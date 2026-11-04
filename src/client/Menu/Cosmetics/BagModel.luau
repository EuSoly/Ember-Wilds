--!strict
-- Mochila feita de peças (corpo, aba e duas alças) nas cores de uma skin de
-- mochila (Defs.Cosmetics[id].bag). As peças são montadas já na posição das
-- costas do boneco, com a raiz dele na origem (a frente do boneco é -Z, então
-- as costas ficam em +Z); o pivô do modelo é essa origem.
--
-- `attach` põe a mochila num boneco: move o pivô para a raiz (num
-- ViewportFrame não roda física, por isso o CFrame é posto direto) e solda
-- no Body (no mundo ela acompanha o quique do corpo).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local C = require(Shared:WaitForChild("BonecoConfig"))
local Defs = require(Shared:WaitForChild("Defs"))
local Client = script.Parent.Parent.Parent
local BonecoModel = require(Client:WaitForChild("Boneco"):WaitForChild("BonecoModel"))

-- Medidas (studs). Encostada nas costas (atrás do contorno do corpo) e um
-- pouco mais alta que o corpo, para aparecer por trás na vista de frente.
local BACK_Z = C.BODY_DEPTH / 2 + C.OUTLINE -- costas do contorno do corpo
local SIZE = Vector3.new(2.4, 2.3, 1.1)
local BOTTOM_Y = -0.85 -- base da mochila em relação ao centro do corpo
local FLAP_THICKNESS = 0.18
local FLAP_DROP = 1 -- quanto a aba desce pelo lado de fora
local FLAP_OVERHANG = 0.1 -- a aba passa um pouco do corpo da mochila
local FLAP_SHADE = 0.22 -- a aba é a cor da mochila um pouco mais escura
local STRAP_X = 0.8 -- alças em x = ±STRAP_X
local STRAP_WIDTH = 0.35
local STRAP_THICKNESS = 0.08
local STRAP_FRONT_Z = 0.45 -- até onde a alça chega por cima do corpo (eixo Z)

local BagModel = {}

local function newPart(model: Model, name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	part.Parent = model
	return part
end

-- Mochila nas cores de `look`. Peças ancoradas até o `attach`.
function BagModel.build(look: Defs.BagLook): Model
	local color = Color3.fromHex(look.color)
	local strapColor = Color3.fromHex(look.strapColor)
	local top = BOTTOM_Y + SIZE.Y
	local centerZ = BACK_Z + SIZE.Z / 2
	local outerZ = BACK_Z + SIZE.Z

	local model = Instance.new("Model")
	model.Name = "Bag"
	local body = newPart(model, "BagBody", SIZE, CFrame.new(0, BOTTOM_Y + SIZE.Y / 2, centerZ), color)

	-- Aba: tampa por cima e a parte que desce pelo lado de fora.
	local flapColor = color:Lerp(Color3.new(0, 0, 0), FLAP_SHADE)
	local flapWidth = SIZE.X + 2 * FLAP_OVERHANG
	newPart(
		model,
		"BagFlap",
		Vector3.new(flapWidth, FLAP_THICKNESS, SIZE.Z + FLAP_OVERHANG),
		CFrame.new(0, top + FLAP_THICKNESS / 2, centerZ + FLAP_OVERHANG / 2),
		flapColor
	)
	newPart(
		model,
		"BagFlapFront",
		Vector3.new(flapWidth, FLAP_DROP + FLAP_THICKNESS, FLAP_THICKNESS),
		CFrame.new(0, top + FLAP_THICKNESS - (FLAP_DROP + FLAP_THICKNESS) / 2, outerZ + FLAP_THICKNESS / 2),
		flapColor
	)

	-- Alças: deitadas no topo do corpo do boneco, das costas até STRAP_FRONT_Z.
	local strapTop = C.BODY_HEIGHT / 2 + STRAP_THICKNESS / 2
	local strapLength = BACK_Z + SIZE.Z / 2 - STRAP_FRONT_Z
	for _, side in { -1, 1 } do
		newPart(
			model,
			if side < 0 then "LeftStrap" else "RightStrap",
			Vector3.new(STRAP_WIDTH, STRAP_THICKNESS, strapLength),
			CFrame.new(side * STRAP_X, strapTop, STRAP_FRONT_Z + strapLength / 2),
			strapColor
		)
	end

	-- Pivô na origem da montagem (= raiz do boneco).
	model.PrimaryPart = body
	body.PivotOffset = body.CFrame:Inverse()
	for _, part in model:GetChildren() do
		if part ~= body and part:IsA("BasePart") then
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = part
			weld.Parent = part
		end
	end
	return model
end

-- Põe `model` (de BagModel.build) nas costas de `boneco`.
function BagModel.attach(model: Model, boneco: BonecoModel.Boneco)
	local main = model.PrimaryPart
	assert(main ~= nil, "[BagModel] mochila sem PrimaryPart")
	local offset = main.PivotOffset:Inverse() -- posição do corpo da mochila em relação à raiz
	model:PivotTo(boneco.root.CFrame)

	-- No mundo: solda no Body com o mesmo encaixe (Body fica em raiz * C0).
	local bodyPart = boneco.bodyJoint.Part1
	if bodyPart then
		local joint = Instance.new("Weld")
		joint.Name = "BagWeld"
		joint.Part0 = bodyPart
		joint.Part1 = main
		joint.C0 = boneco.bodyJoint.C0:Inverse() * offset
		joint.Parent = main
	end
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
		end
	end
	model.Parent = boneco.model
end

return BagModel
