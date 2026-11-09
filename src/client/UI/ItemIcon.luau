--!strict
-- Ícone de um item: moldura na cor do tier (borda forte e fundo a 15%), com o
-- modelo 3D do item num ViewportFrame e a quantidade no canto.
-- O modelo vem do primeiro que existir em ReplicatedStorage.Assets:
--   Icons/<id>      ícone em relevo (comidas, drops, recursos), visto de cima;
--   Tools/<id>      ferramenta/arma de mão, deitada na diagonal (ponta em cima
--                   à direita), vista pelo lado largo;
--   Structures/<id> construção, vista de cima como os ícones.
-- Sem modelo, o ícone mostra as iniciais do nome.
--
-- Ajuste por item (atributos opcionais no molde OU numa peça direta dele, ex.
-- a MeshPart de dentro ou o Handle; editáveis no Studio e o ícone muda ao vivo,
-- ver scripts/studio/icon-bench.luau):
--   IconeGiro    Vector3, graus: X inclina (cima/baixo), Y vira (esq./dir.),
--                Z gira no plano da tela; a câmera orbita o centro do modelo.
--   IconeZoom    número: 1 = enche o quadro, 1.3 = 30% maior, 0.8 = menor.
--   IconeDesloca Vector2: move o modelo no quadro, em frações do quadro
--                (0.1, 0 = 10% para a direita; 0, 0.1 = 10% para cima).
-- Itens sem tier (recursos, comida) usam a moldura neutra.
--
-- Recebe o item como FONTE reativa: se a quantidade ou o item do slot mudar,
-- o ícone se atualiza sozinho (sem ser recriado).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local Palette = require(Shared:WaitForChild("Palette"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local UIMath = require(Shared:WaitForChild("UIMath"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local create = vide.create

local FRAME_BORDER = 3
local ICON_FOV = 30 -- campo de visão vertical da câmera do ícone
local ICON_MARGIN = 0.12 -- folga fixa em volta do modelo
local ICON_TILT = math.rad(35) -- inclinação em relação à vista de cima

export type Item = { id: string, count: number }

export type Props = {
	item: () -> Item,
}

local function frameColor(itemId: string): Color3
	local def = Defs.Items[itemId]
	local tier = def and def.tier and Defs.Tiers[def.tier]
	return Theme.color(if tier then tier.color else Palette.neutralFrame)
end

local function displayName(itemId: string): string
	local def = Defs.Items[itemId]
	return if def then Strings.get(def.nameKey) else itemId
end

type Kind = "flat" | "tool"
type Source = { instance: Instance, kind: Kind }

-- Pastas de Assets onde procurar o modelo do item, em ordem, e como enquadrar.
local SOURCES: { { folder: string, kind: Kind } } = {
	{ folder = "Icons", kind = "flat" },
	{ folder = "Tools", kind = "tool" },
	{ folder = "Structures", kind = "flat" },
}

-- Molde do ícone do item, ou nil. Procura na hora (o Assets pode ainda não ter
-- chegado no primeiro frame): sem molde, o ícone usa as iniciais.
local function iconSource(itemId: string): Source?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	if assets == nil then
		return nil
	end
	for _, entry in SOURCES do
		local folder = assets:FindFirstChild(entry.folder)
		local found = folder and folder:FindFirstChild(itemId)
		if found and (found:IsA("Model") or found:IsA("Tool")) then
			return { instance = found, kind = entry.kind }
		end
	end
	return nil
end

-- Cópia do molde como Model (uma Tool vira Model com as mesmas peças).
local function cloneAsModel(source: Instance): Model
	local copy = source:Clone()
	if copy:IsA("Model") then
		return copy
	end
	local model = Instance.new("Model")
	model.Name = source.Name
	for _, child in copy:GetChildren() do
		child.Parent = model
	end
	copy:Destroy()
	return model
end

-- Cantos de todas as peças do modelo, no mundo.
local function corners(model: Model): { Vector3 }
	local list = {}
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			local half = part.Size / 2
			for _, sx in { -1, 1 } do
				for _, sy in { -1, 1 } do
					for _, sz in { -1, 1 } do
						table.insert(list, part.CFrame * Vector3.new(half.X * sx, half.Y * sy, half.Z * sz))
					end
				end
			end
		end
	end
	return list
end

-- Base da câmera antes do ajuste por item: centro e eixos direita/cima da tela.
type View = { center: Vector3, right: Vector3, up: Vector3 }

-- Onde o ajuste pode morar: o molde e as peças diretas dele (quem seleciona a
-- peça no Explorer e cria o atributo nela também acerta).
local function attributeHolders(source: Instance): { Instance }
	local holders = { source }
	for _, child in source:GetChildren() do
		if child:IsA("BasePart") then
			table.insert(holders, child)
		end
	end
	return holders
end

local function readAttribute(source: Instance, name: string): any
	for _, holder in attributeHolders(source) do
		local value = holder:GetAttribute(name)
		if value ~= nil then
			return value
		end
	end
	return nil
end

local function vectorAttribute(source: Instance, name: string): Vector3
	local value = readAttribute(source, name)
	return if typeof(value) == "Vector3" then value else Vector3.zero
end

-- Põe a câmera na vista `view`, com o ajuste do molde, a uma distância que
-- enche o quadro.
local function placeCamera(camera: Camera, model: Model, view: View, source: Instance)
	local giro = vectorAttribute(source, "IconeGiro")
	local zoom = readAttribute(source, "IconeZoom")
	local desloca = readAttribute(source, "IconeDesloca")
	local basis = CFrame.fromMatrix(Vector3.zero, view.right, view.up)
		* CFrame.Angles(math.rad(giro.X), math.rad(giro.Y), math.rad(giro.Z))
	local right, up = basis.RightVector, basis.UpVector
	local look = up:Cross(right) -- para onde a câmera olha
	local points = {}
	for _, corner in corners(model) do
		local offset = corner - view.center
		table.insert(points, { offset:Dot(right), offset:Dot(up), offset:Dot(look) })
	end
	local distance = UIMath.fitDistance(points, ICON_FOV, 1, ICON_MARGIN)
	if typeof(zoom) == "number" and zoom > 0 then
		distance /= zoom
	end
	local position = view.center - look * distance
	if typeof(desloca) == "Vector2" then
		-- Altura do quadro na distância do centro do modelo.
		local frameHeight = 2 * distance * math.tan(math.rad(ICON_FOV) / 2)
		position -= (right * desloca.X + up * desloca.Y) * frameHeight
	end
	camera.FieldOfView = ICON_FOV
	camera.CFrame = CFrame.fromMatrix(position, right, up)
end

-- Ícone em relevo ou construção: de cima, levemente inclinado (frente = -Z).
local function flatView(model: Model): View
	local boxCFrame = model:GetBoundingBox()
	local up = Vector3.new(0, math.sin(ICON_TILT), -math.cos(ICON_TILT))
	return { center = boxCFrame.Position, right = Vector3.xAxis, up = up }
end

-- Ferramenta: olha pelo eixo mais fino da peça principal (o lado largo da
-- lâmina/cabeça) e gira para a ponta (o lado longe da pegada) ficar em cima à
-- direita, como nos ícones de ferramenta de jogos do gênero.
local function toolView(model: Model): View
	local named = model:FindFirstChild("Handle")
	local handle: BasePart? = if named and named:IsA("BasePart")
		then named
		else model:FindFirstChildWhichIsA("BasePart", true)
	if handle == nil then
		return flatView(model)
	end
	local cf, size = handle.CFrame, handle.Size
	local axes = {
		{ dir = cf.RightVector, len = size.X },
		{ dir = cf.UpVector, len = size.Y },
		{ dir = cf.LookVector, len = size.Z },
	}
	table.sort(axes, function(a, b)
		return a.len < b.len
	end)
	local normal = axes[1].dir
	if normal.Y < 0 then
		normal = -normal -- vê de cima quando a peça está deitada
	end
	local look = -normal
	local center = model:GetBoundingBox().Position
	-- Direção cabo -> ponta, no plano da peça.
	local grip = handle:FindFirstChild("Grip")
	local gripPos = if grip and grip:IsA("Attachment") then grip.WorldPosition else cf.Position
	local toTip = center - gripPos
	toTip -= normal * toTip:Dot(normal)
	if toTip.Magnitude < 1e-3 then
		toTip = axes[3].dir
	end
	toTip = toTip.Unit
	local side = toTip:Cross(look)
	return { center = center, right = (toTip - side).Unit, up = (toTip + side).Unit }
end

local function ItemIcon(props: Props): Frame
	-- Só troca o molde quando o id muda (não a cada mudança de quantidade).
	local itemId = vide.derive(function()
		return props.item().id
	end)
	local template = vide.derive(function()
		return iconSource(itemId())
	end)

	-- Um único ViewportFrame e uma única câmera por ícone; só o modelo troca.
	local camera = create("Camera")({ Name = "IconCamera" }) :: Camera
	local viewport = create("ViewportFrame")({
		Name = "Icon3D",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.9),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Ambient = Color3.fromRGB(190, 190, 190),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-0.3, -1, -0.5),
		CurrentCamera = camera,
		Visible = function()
			return template() ~= nil
		end,
	}) :: ViewportFrame
	camera.Parent = viewport

	vide.effect(function()
		local source = template()
		if not source then
			return
		end
		local model = cloneAsModel(source.instance)
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.Anchored = true
			end
		end
		model.Parent = viewport
		local view = if source.kind == "tool" then toolView(model) else flatView(model)
		placeCamera(camera, model, view, source.instance)
		-- Ajuste ao vivo: mexer nos atributos do molde no Studio reenquadra.
		local connections = {}
		for _, holder in attributeHolders(source.instance) do
			table.insert(
				connections,
				holder.AttributeChanged:Connect(function(name)
					if name == "IconeGiro" or name == "IconeZoom" or name == "IconeDesloca" then
						placeCamera(camera, model, view, source.instance)
					end
				end)
			)
		end
		vide.cleanup(function()
			for _, connection in connections do
				connection:Disconnect()
			end
			model:Destroy()
		end)
	end)

	local color = vide.derive(function()
		return frameColor(props.item().id)
	end)

	return create("Frame")({
		Name = "ItemIcon",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.86, 0.86),
		BackgroundColor3 = color,
		BackgroundTransparency = 0.85, -- fundo na cor do tier a 15%
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = Theme.slotCorner }),
		create("UIStroke")({ Color = color, Thickness = FRAME_BORDER }),
		viewport,
		Kit.text({
			Name = "Initials",
			Visible = function()
				return template() == nil
			end,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromScale(0.8, 0.5),
			Text = function()
				return UIMath.initials(displayName(props.item().id))
			end,
			maxSize = 22,
		}),
		Kit.text({
			Name = "Count",
			Visible = function()
				return props.item().count > 1
			end,
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(0.95, 0.98),
			Size = UDim2.fromScale(0.6, 0.34),
			FontFace = Theme.font.number,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = function()
				return tostring(props.item().count)
			end,
			maxSize = 16,
		}),
	}) :: Frame
end

return ItemIcon
