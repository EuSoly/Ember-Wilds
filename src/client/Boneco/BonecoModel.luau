--!strict
-- Boneco visual (só no cliente): corpo de cantos arredondados com contorno,
-- olhos no topo, duas mãos soltas, ferramenta ou comida na mão direita e o
-- nome em cima. A comida na mão é o ícone em relevo dela (Assets.Icons/<id>).
-- Medidas em BonecoConfig (valores do spike aprovado); cores vêm da skin.
--
-- Montagem: uma raiz invisível e ancorada (quem move é o BonecoRenderer, com
-- BulkMoveTo) e articulações Motor6D Root → Body e Root → mãos. A animação
-- escreve Motor6D.Transform. As peças do corpo, do contorno e dos olhos são
-- soldadas ao Body; o contorno de cada mão, à mão.
-- Os estilos de olho (Validate.EYE_STYLES) são montados uma vez e trocados por
-- Transparency: piscar não cria nem destrói peças.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local C = require(Shared:WaitForChild("BonecoConfig"))
local Defs = require(Shared:WaitForChild("Defs"))
local Palette = require(Shared:WaitForChild("Palette"))
local SkinAssets = require(Shared:WaitForChild("Models"):WaitForChild("SkinAssets"))
local SkinManifest = require(Shared:WaitForChild("Defs"):WaitForChild("SkinManifest"))
local Theme = require(Shared:WaitForChild("Theme"))
local ToolModel = require(Shared:WaitForChild("Models"):WaitForChild("ToolModel"))
local Validate = require(Shared:WaitForChild("Defs"):WaitForChild("Validate"))

local FOLDER_NAME = "BonecoVisuals"
local DEFAULT_EYE_COLOR = "#111111"
local SHINE_COLOR = "#FFFFFF"
-- Olhos: disco fino logo acima do topo do corpo (0.06/0.08 fica acima das camadas do topo das skins 3D).
local EYE_LIFT = 0.06
local EYE_THICKNESS = 0.08
local SHINE_OFFSET = Vector3.new(-0.18, 0.02, -0.18)
-- Barras do olho fechado e do "> <".
local BAR_THICKNESS = 0.06
local BAR_WIDTH = 0.14
local SQUEEZE_LENGTH = 0.55
local SQUEEZE_ANGLE = math.rad(30)
-- "^ ^" (contente, comendo): duas barras que se encontram na ponta da frente.
local HAPPY_WIDTH = 0.62
local HAPPY_DEPTH = 0.32
-- Farelos da mordida.
local DEFAULT_CRUMB_COLOR = "#D9B27C"
local CRUMB_TEXTURE = "rbxasset://textures/particles/SquareParticle.png" -- quadradinho liso: pega a cor
-- Etiqueta do nome.
local NAME_SIZE = UDim2.fromOffset(200, 28)
local NAME_STROKE = 1.5
-- Cilindro em pé: o cilindro do Roblox tem o eixo em X, então gira 90° em Z.
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90))

type EyeParts = { [Defs.EyeStyle]: { BasePart } }

export type Boneco = {
	model: Model,
	root: BasePart, -- ancorada, invisível; quem move é o renderer
	bodyJoint: Motor6D, -- Root → Body
	leftHandJoint: Motor6D, -- Root → mão esquerda
	rightHandJoint: Motor6D, -- Root → mão direita
	rightHand: BasePart,
	nameLabel: TextLabel,
	-- Internos (cor, olhos, ferramenta).
	bodyParts: { BasePart },
	handParts: { BasePart },
	outlineParts: { BasePart },
	eyeParts: { BasePart }, -- peças na cor do olho (sem o brilho)
	eyeStyles: EyeParts,
	look: Defs.BodyLook,
	skinId: string?,
	skinParts: { BasePart },
	flash: string?,
	tool: Model?,
	crumbs: ParticleEmitter?,
}

local BonecoModel = {}

local function visualFolder(): Folder
	local folder = Workspace:FindFirstChild(FOLDER_NAME)
	if folder and folder:IsA("Folder") then
		return folder
	end
	local created = Instance.new("Folder")
	created.Name = FOLDER_NAME
	created.Parent = Workspace
	return created
end

-- Peça puramente visual: não colide, não é atingida por raycast, não pesa.
local function styleVisualPart(part: BasePart)
	part.Anchored = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	-- MeshParts importados já carregam o material do tier (madeira, pedra,
	-- metal ou gema). Não sobrescreva esse acabamento ao equipar.
	if not part:IsA("MeshPart") then
		part.Material = Enum.Material.SmoothPlastic
	end
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
end

local function newPart(model: Model, name: string, size: Vector3, cframe: CFrame, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = name
	if shape then
		part.Shape = shape
	end
	part.Size = size
	part.CFrame = cframe
	styleVisualPart(part)
	part.Parent = model
	return part
end

local function weld(base: BasePart, part: BasePart)
	local constraint = Instance.new("WeldConstraint")
	constraint.Part0 = base
	constraint.Part1 = part
	constraint.Parent = part
end

local function newMotor(name: string, part0: BasePart, part1: BasePart, c0: CFrame): Motor6D
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = c0
	motor.Parent = part0
	return motor
end

-- Caixa de cantos arredondados (vista de cima): 2 blocos em cruz + 4 cilindros
-- em pé nos cantos. A primeira peça devolvida é o bloco principal.
local function roundedBox(model: Model, name: string, size: Vector3, radius: number, center: CFrame): { BasePart }
	local w, h, d = size.X, size.Y, size.Z
	local parts: { BasePart } = {
		newPart(model, name, Vector3.new(w, h, d - 2 * radius), center),
		newPart(model, name .. "Cross", Vector3.new(w - 2 * radius, h, d), center),
	}
	local cornerSize = Vector3.new(h, 2 * radius, 2 * radius)
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			local corner = center * CFrame.new(sx * (w / 2 - radius), 0, sz * (d / 2 - radius)) * UPRIGHT
			table.insert(parts, newPart(model, name .. "Corner", cornerSize, corner, Enum.PartType.Cylinder))
		end
	end
	return parts
end

-- Um olho em `eye` (centro do olho, já no topo do corpo). `inward` = direção
-- (+1/-1 em X) do centro do boneco: a ponta do "> <" aponta para dentro.
-- Devolve as peças de cada estilo e o brilho (que não muda de cor com a skin).
local function buildEye(model: Model, eye: CFrame, inward: number): (EyeParts, BasePart)
	local diameter = C.EYE_DIAMETER
	local disc =
		newPart(model, "EyeOpen", Vector3.new(EYE_THICKNESS, diameter, diameter), eye * UPRIGHT, Enum.PartType.Cylinder)
	local shineSize = diameter * C.SHINE_FRACTION
	local shine = newPart(
		model,
		"EyeShine",
		Vector3.new(EYE_THICKNESS, shineSize, shineSize),
		eye * CFrame.new(SHINE_OFFSET) * UPRIGHT,
		Enum.PartType.Cylinder
	)
	local closed = newPart(model, "EyeClosed", Vector3.new(diameter, BAR_THICKNESS, BAR_WIDTH), eye)

	-- "> <": duas barras inclinadas ±SQUEEZE_ANGLE que se encontram na ponta
	-- do lado de dentro; o desenho fica centrado no olho.
	local squeeze: { BasePart } = {}
	local barSize = Vector3.new(SQUEEZE_LENGTH, BAR_THICKNESS, BAR_WIDTH)
	for _, side in { -1, 1 } do
		local offset = CFrame.new(0, 0, side * (SQUEEZE_LENGTH / 2) * math.sin(SQUEEZE_ANGLE))
		local yaw = CFrame.Angles(0, inward * side * SQUEEZE_ANGLE, 0)
		table.insert(squeeze, newPart(model, "EyeSqueeze", barSize, eye * offset * yaw))
	end

	-- "^": ponta para a frente (-Z), as duas pontas soltas para trás.
	local happy: { BasePart } = {}
	local apex = Vector3.new(0, 0, -HAPPY_DEPTH / 2)
	for _, side in { -1, 1 } do
		local tip = Vector3.new(side * HAPPY_WIDTH / 2, 0, HAPPY_DEPTH / 2)
		local middle = (apex + tip) / 2
		local length = (tip - apex).Magnitude + BAR_THICKNESS
		local bar = eye * CFrame.lookAt(middle, tip)
		table.insert(happy, newPart(model, "EyeHappy", Vector3.new(BAR_WIDTH, BAR_THICKNESS, length), bar))
	end

	local styles: EyeParts = { open = { disc, shine }, closed = { closed }, squeeze = squeeze, happy = happy }
	return styles, shine
end

-- Pinta tudo conforme o look atual; o flash (se houver) cobre corpo e mãos.
local function paint(boneco: Boneco)
	local look = boneco.look
	local bodyColor = Theme.color(boneco.flash or look.bodyColor)
	local handColor = Theme.color(boneco.flash or look.handColor or look.bodyColor)
	local outlineColor = Theme.color(look.outlineColor)
	local eyeColor = Theme.color(look.eyeColor or DEFAULT_EYE_COLOR)
	for _, part in boneco.bodyParts do
		part.Color = bodyColor
	end
	for _, part in boneco.handParts do
		part.Color = handColor
	end
	for _, part in boneco.outlineParts do
		part.Color = outlineColor
	end
	for _, part in boneco.eyeParts do
		part.Color = eyeColor
	end
	local skinTint = if boneco.flash then Theme.color(boneco.flash) else Color3.new(1, 1, 1)
	for _, part in boneco.skinParts do
		part.Color = skinTint
	end
end

local function buildNameTag(root: BasePart, displayName: string): TextLabel
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = NAME_SIZE
	billboard.StudsOffset = Vector3.new(0, C.NAME_HEIGHT, 0)
	billboard.MaxDistance = C.ANIM_RANGE
	billboard.LightInfluence = 0

	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = displayName
	label.FontFace = Theme.font.label
	label.TextColor3 = Theme.ui.text
	label.TextScaled = true

	local stroke = Instance.new("UIStroke")
	stroke.Color = Theme.color(Palette.ui.panel)
	stroke.Thickness = NAME_STROKE
	stroke.Parent = label

	label.Parent = billboard
	billboard.Parent = root
	return label
end

-- Mão em `c0` (posição em relação à raiz) e o contorno soldado a ela, mais baixo.
local function buildHand(model: Model, name: string, c0: CFrame): (BasePart, BasePart)
	local hand = newPart(model, name, Vector3.one * C.HAND_DIAMETER, c0, Enum.PartType.Ball)
	local outline = newPart(
		model,
		name .. "Outline",
		Vector3.one * (C.HAND_DIAMETER + 2 * C.OUTLINE),
		c0 * CFrame.new(0, -C.HAND_OUTLINE_DROP, 0),
		Enum.PartType.Ball
	)
	weld(hand, outline)
	return hand, outline
end

function BonecoModel.build(displayName: string): Boneco
	local model = Instance.new("Model")
	model.Name = displayName

	-- Tudo é montado com a raiz na origem; depois o renderer move só a raiz.
	local root = newPart(model, "Root", Vector3.one * 0.2, CFrame.identity)
	root.Anchored = true
	root.Transparency = 1
	model.PrimaryPart = root

	local bodySize = Vector3.new(C.BODY_WIDTH, C.BODY_HEIGHT, C.BODY_DEPTH)
	local bodyCenter = CFrame.new(0, C.VISUAL_OFFSET_Y, 0)

	-- Corpo e contorno (mesma forma, maior em X/Z, topo OUTLINE_DROP mais baixo).
	local bodyParts = roundedBox(model, "Body", bodySize, C.CORNER_RADIUS, bodyCenter)
	local body = bodyParts[1]
	local outlineParts = roundedBox(
		model,
		"Outline",
		bodySize + Vector3.new(2 * C.OUTLINE, -C.OUTLINE_DROP, 2 * C.OUTLINE),
		C.CORNER_RADIUS + C.OUTLINE,
		bodyCenter * CFrame.new(0, -C.OUTLINE_DROP / 2, 0)
	)

	-- Olhos: esquerdo em -X, direito em +X; o centro do boneco fica do lado oposto.
	local eyeStyles: EyeParts = {}
	for _, style in Validate.EYE_STYLES do
		eyeStyles[style :: Defs.EyeStyle] = {}
	end
	local eyeParts: { BasePart } = {}
	for _, side in { -1, 1 } do
		local eye = bodyCenter * CFrame.new(side * C.EYE_X, C.BODY_HEIGHT / 2 + EYE_LIFT, C.EYE_Z)
		local styles, shine = buildEye(model, eye, -side)
		shine.Color = Theme.color(SHINE_COLOR)
		for style, parts in styles do
			for _, part in parts do
				table.insert(eyeStyles[style :: Defs.EyeStyle], part)
				if part ~= shine then
					table.insert(eyeParts, part)
				end
			end
		end
	end

	-- Tudo que é do corpo segue o Body (é ele que quica).
	for i, part in bodyParts do
		if i > 1 then
			weld(body, part)
		end
	end
	for _, part in outlineParts do
		weld(body, part)
	end
	for _, parts in eyeStyles do
		for _, part in parts do
			weld(body, part)
		end
	end
	local bodyJoint = newMotor("BodyJoint", root, body, bodyCenter)

	-- Mãos soltas, cada uma com a própria articulação na raiz. Direita = +X.
	local handY = C.VISUAL_OFFSET_Y + C.HAND_Y
	local leftC0 = CFrame.new(-C.HAND_X, handY, C.HAND_Z)
	local rightC0 = CFrame.new(C.HAND_X, handY, C.HAND_Z)
	local leftHand, leftOutline = buildHand(model, "LeftHand", leftC0)
	local rightHand, rightOutline = buildHand(model, "RightHand", rightC0)
	table.insert(outlineParts, leftOutline)
	table.insert(outlineParts, rightOutline)

	local defaultLook = Defs.Cosmetics[Defs.CosmeticSlots.body.default].body
	assert(defaultLook ~= nil, "[BonecoModel] skin padrão do corpo sem cores")

	local boneco: Boneco = {
		model = model,
		root = root,
		bodyJoint = bodyJoint,
		leftHandJoint = newMotor("LeftHandJoint", root, leftHand, leftC0),
		rightHandJoint = newMotor("RightHandJoint", root, rightHand, rightC0),
		rightHand = rightHand,
		nameLabel = buildNameTag(root, displayName),
		bodyParts = bodyParts,
		handParts = { leftHand, rightHand },
		outlineParts = outlineParts,
		eyeParts = eyeParts,
		eyeStyles = eyeStyles,
		look = defaultLook,
		skinId = nil,
		skinParts = {},
		flash = nil,
		tool = nil,
	}
	paint(boneco)
	BonecoModel.setEyes(boneco, "open")

	model.Parent = visualFolder()
	return boneco
end

local function setProceduralVisible(boneco: Boneco, visible: boolean)
	local transparency = if visible then 0 else 1
	for _, part in boneco.bodyParts do
		part.Transparency = transparency
	end
	for _, part in boneco.handParts do
		part.Transparency = transparency
	end
	for _, part in boneco.outlineParts do
		part.Transparency = transparency
	end
end

local function applySkinMeshes(boneco: Boneco, skinId: string?)
	local has3D = skinId ~= nil and SkinAssets.hasSkin(skinId)
	if skinId == boneco.skinId and (not has3D or #boneco.skinParts > 0) then
		return
	end
	for _, part in boneco.skinParts do
		part:Destroy()
	end
	table.clear(boneco.skinParts)
	boneco.skinId = skinId

	if not has3D or skinId == nil then
		setProceduralVisible(boneco, true)
		return
	end

	local partNames = SkinManifest.PARTS_BY_SKIN[skinId]
	if partNames == nil then
		setProceduralVisible(boneco, true)
		return
	end

	local body = boneco.bodyParts[1]
	local leftHand = boneco.handParts[1]
	local rightHand = boneco.handParts[2]

	local hasLeftHandMesh = false
	for _, partName in partNames do
		local info = SkinManifest.PARTS[partName]
		if info and info.papel == "mao_esq" and SkinAssets.findPart(skinId, partName) ~= nil then
			hasLeftHandMesh = true
			break
		end
	end

	for _, partName in partNames do
		local info = SkinManifest.PARTS[partName]
		if info then
			if info.papel == "corpo" then
				local clone = SkinAssets.clonePart(skinId, partName, body.CFrame)
				if clone then
					clone.Parent = boneco.model
					weld(body, clone)
					table.insert(boneco.skinParts, clone)
				end
			elseif SkinAssets.isAnimated(partName) then
				-- Asa, rabo, tentáculo, raiz...: presa no corpo por uma junta no
				-- pivô dela; o SkinAnimator mexe a junta (BonecoRenderer).
				local clone = SkinAssets.clonePart(skinId, partName, body.CFrame)
				if clone then
					clone.Parent = boneco.model
					SkinAssets.attachPart(body, clone, body.CFrame)
					table.insert(boneco.skinParts, clone)
				end
			elseif info.papel == "mao" then
				local cloneRight = SkinAssets.clonePart(skinId, partName, rightHand.CFrame)
				if cloneRight then
					cloneRight.Parent = rightHand
					weld(rightHand, cloneRight)
					table.insert(boneco.skinParts, cloneRight)
				end
				if not hasLeftHandMesh then
					local cloneLeft = SkinAssets.clonePart(skinId, partName, leftHand.CFrame)
					if cloneLeft then
						cloneLeft.Name = partName .. "_esq"
						cloneLeft.Parent = leftHand
						weld(leftHand, cloneLeft)
						table.insert(boneco.skinParts, cloneLeft)
					end
				end
			elseif info.papel == "mao_esq" then
				local cloneLeft = SkinAssets.clonePart(skinId, partName, leftHand.CFrame)
				if cloneLeft then
					cloneLeft.Parent = leftHand
					weld(leftHand, cloneLeft)
					table.insert(boneco.skinParts, cloneLeft)
				end
			end
		end
	end

	setProceduralVisible(boneco, #boneco.skinParts == 0)
end

function BonecoModel.applyLook(boneco: Boneco, look: Defs.BodyLook, skinId: string?)
	boneco.look = look
	applySkinMeshes(boneco, skinId)
	paint(boneco)
end

function BonecoModel.setEyes(boneco: Boneco, style: Defs.EyeStyle)
	-- O brilho está em "open": some junto quando o olho fecha.
	for name, parts in boneco.eyeStyles do
		local transparency = if name == style then 0 else 1
		for _, part in parts do
			part.Transparency = transparency
		end
	end
end

-- Pinta corpo e mãos com `hex` (ex. vermelho do dano); nil volta às cores do look.
function BonecoModel.setFlash(boneco: Boneco, hex: string?)
	boneco.flash = hex
	paint(boneco)
end

-- Comida na mão: o ícone em relevo (Assets.Icons/<id>) deitado em cima da mão,
-- do tamanho FOOD_HAND_SIZE, para ler de cima o que o jogador vai comer.
local function holdFood(boneco: Boneco, itemId: string)
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local icons = assets and assets:FindFirstChild("Icons")
	local template = icons and icons:FindFirstChild(itemId)
	if template == nil or not template:IsA("Model") then
		return
	end
	local food = template:Clone()
	local _, size = food:GetBoundingBox()
	local biggest = math.max(size.X, size.Z)
	if biggest > 0 then
		food:ScaleTo(food:GetScale() * C.FOOD_HAND_SIZE / biggest)
	end
	local pivot = food:GetPivot()
	local offset = C.FOOD_HAND_OFFSET
	for _, part in food:GetDescendants() do
		if part:IsA("BasePart") then
			styleVisualPart(part)
			-- Weld com C0/C1 (como a ferramenta): não depende da pose da mão agora.
			local joint = Instance.new("Weld")
			joint.Name = "FoodWeld"
			joint.Part0 = boneco.rightHand
			joint.Part1 = part
			joint.C0 = CFrame.new(offset[1], offset[2], offset[3])
			joint.C1 = part.CFrame:Inverse() * pivot
			joint.Parent = part
		end
	end
	food.Parent = boneco.model
	boneco.tool = food
end

-- Farelos que saem da comida a cada mordida (cor do item ou cor de pão).
function BonecoModel.emitCrumbs(boneco: Boneco, hex: string?, count: number)
	local emitter = boneco.crumbs
	if emitter == nil then
		local offset = C.FOOD_HAND_OFFSET
		local attachment = Instance.new("Attachment")
		attachment.Name = "Crumbs"
		attachment.Position = Vector3.new(offset[1], offset[2], offset[3])
		attachment.Parent = boneco.rightHand
		local created = Instance.new("ParticleEmitter")
		created.Texture = CRUMB_TEXTURE
		created.Rate = 0
		created.Lifetime = NumberRange.new(0.35, 0.6)
		created.Speed = NumberRange.new(4, 7)
		created.SpreadAngle = Vector2.new(70, 70)
		created.Acceleration = Vector3.new(0, -35, 0)
		created.Size = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.35),
			NumberSequenceKeypoint.new(1, 0.1),
		})
		created.Rotation = NumberRange.new(0, 360)
		created.LightInfluence = 0
		created.Parent = attachment
		boneco.crumbs = created
		emitter = created
	end
	local color = Theme.color(hex or DEFAULT_CRUMB_COLOR)
	local crumbs = emitter :: ParticleEmitter
	crumbs.Color = ColorSequence.new(color, color:Lerp(Color3.new(0, 0, 0), 0.25))
	crumbs:Emit(count)
end

-- Troca o item na mão direita. true se ficou uma ferramenta na mão (a comida
-- aparece na mão, mas não conta como ferramenta: não golpeia).
function BonecoModel.setHeldItem(boneco: Boneco, itemId: string?, cosmeticId: string?): boolean
	if boneco.tool then
		boneco.tool:Destroy()
		boneco.tool = nil
	end
	if itemId == nil then
		return false
	end
	local def = Defs.Items[itemId]
	if def and def.food then
		holdFood(boneco, itemId)
		return false
	end
	local tool = ToolModel.build(itemId, cosmeticId)
	if tool == nil then
		return false
	end
	local handle = tool.PrimaryPart
	local grip = handle and handle:FindFirstChild("Grip")
	if handle == nil or grip == nil or not grip:IsA("Attachment") then
		tool:Destroy()
		return false
	end
	for _, part in tool:GetDescendants() do
		if part:IsA("BasePart") then
			styleVisualPart(part)
		end
	end

	-- Orientação da raiz (igual à da mão em repouso): cabo para a frente e
	-- cabeça deitada (Grip: Y = cabo, X = lado da cabeça), girada
	-- SWING_REST_ANGLE para fora (para a direita = ângulo negativo em Y). Armas
	-- de estocada (lança) apontam THRUST_REST_ANGLE: para a frente, um pouco para dentro.
	-- Weld com C0/C1 em vez de WeldConstraint: o encaixe não depende de onde a
	-- mão está neste quadro (pode estar no meio de um golpe).
	local thrust = ToolModel.attackAnimOf(itemId) == "thrust"
	local restAngle = if thrust then C.THRUST_REST_ANGLE else C.SWING_REST_ANGLE
	local rest = CFrame.Angles(0, -math.rad(restAngle), 0)
	local joint = Instance.new("Weld")
	joint.Name = "GripWeld"
	joint.Part0 = boneco.rightHand
	joint.Part1 = handle
	joint.C0 = CFrame.fromMatrix(Vector3.zero, rest.RightVector, rest.LookVector)
	joint.C1 = grip.CFrame
	joint.Parent = handle

	tool.Parent = boneco.model
	boneco.tool = tool
	return true
end

-- Mostra ou esconde o boneco (tira do Workspace). Usado quando o personagem
-- fica sem HumanoidRootPart: é melhor sumir do que ficar congelado no lugar.
function BonecoModel.setVisible(boneco: Boneco, visible: boolean)
	local parent: Instance? = if visible then visualFolder() else nil
	if boneco.model.Parent ~= parent then
		boneco.model.Parent = parent
	end
end

function BonecoModel.destroy(boneco: Boneco)
	boneco.model:Destroy()
end

return BonecoModel
