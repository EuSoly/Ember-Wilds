--!strict
-- Ícone provisório de um item: moldura na cor do tier (borda forte e fundo a 15%),
-- com as iniciais do nome no centro e a quantidade no canto.
-- Itens sem tier (recursos, comida) usam a moldura neutra.
-- Quando os ícones desenhados chegarem (spritesheet), só este arquivo muda.
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

export type Props = {
	itemId: string,
	count: number,
}

local function frameColor(itemId: string): Color3
	local def = Defs.Items[itemId]
	local tier = def and def.tier and Defs.Tiers[def.tier]
	return Theme.color(if tier then tier.color else Palette.neutralFrame)
end

local function ItemIcon(props: Props): Frame
	local def = Defs.Items[props.itemId]
	local name = if def then Strings.get(def.nameKey) else props.itemId
	local color = frameColor(props.itemId)

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
		Kit.text({
			Name = "Initials",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.45),
			Size = UDim2.fromScale(0.8, 0.5),
			Text = UIMath.initials(name),
			maxSize = 22,
		}),
		if props.count > 1
			then Kit.text({
				Name = "Count",
				AnchorPoint = Vector2.new(1, 1),
				Position = UDim2.fromScale(0.95, 0.98),
				Size = UDim2.fromScale(0.6, 0.34),
				FontFace = Theme.font.number,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = tostring(props.count),
				maxSize = 16,
			})
			else nil,
	}) :: Frame
end

return ItemIcon
