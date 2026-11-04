--!strict
-- Ícone provisório de um item: moldura na cor do tier (borda forte e fundo a 15%),
-- com as iniciais do nome no centro e a quantidade no canto.
-- Se existir um modelo em ReplicatedStorage.Assets.Icons/<id>, um ViewportFrame
-- mostra o modelo 3D no lugar das iniciais.
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

-- Modelo-molde do ícone do item, ou nil. Procura na hora (o Assets pode ainda
-- não ter chegado no primeiro frame): sem molde, o ícone usa as iniciais.
local function iconTemplate(itemId: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local icons = assets and assets:FindFirstChild("Icons")
	local template = icons and icons:FindFirstChild(itemId)
	return if template and template:IsA("Model") then template else nil
end

-- Posiciona a câmera de cima, levemente inclinada, enquadrando a caixa do modelo.
local function frameCamera(camera: Camera, model: Model)
	local boxCFrame, size = model:GetBoundingBox()
	local distance = UIMath.iconCameraDistance(size.X, size.Y, size.Z, ICON_FOV, ICON_MARGIN)
	local direction = Vector3.new(0, math.cos(ICON_TILT), math.sin(ICON_TILT))
	local center = boxCFrame.Position
	camera.FieldOfView = ICON_FOV
	camera.CFrame = CFrame.lookAt(center + direction * distance, center)
end

local function ItemIcon(props: Props): Frame
	local template = vide.derive(function()
		return iconTemplate(props.item().id)
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
		local model = source:Clone()
		model.Parent = viewport
		frameCamera(camera, model)
		vide.cleanup(function()
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
