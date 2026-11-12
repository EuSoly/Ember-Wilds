--!strict
-- Receita fixada pelo livro (PinState), na coluna da direita do HUD, abaixo do
-- quadrinho do tutorial: o nome do item e uma linha por ingrediente, com ícone
-- e "Madeira 15/10" (sem teto, para ver o que já passou; verde quando já tem).
-- O nome fica verde quando dá para fazer. O X desafixa.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local HudColumn = require(Shared:WaitForChild("UIFlow"):WaitForChild("HudColumn"))
local PinRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("PinRules"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local PinState = require(script.Parent.Parent:WaitForChild("PinState"))
local HudColumnState = require(script.Parent:WaitForChild("HudColumnState"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create
local R = Theme.rustic

local DONE_COLOR = Color3.fromRGB(46, 140, 52) -- verde do "já tem"

local function itemName(id: string): string
	local def = Defs.Items[id]
	return if def then Strings.get(def.nameKey) else id
end

-- Uma linha: ícone e "Madeira 15/10".
local function Line(line: () -> PinRules.Line, index: number): Frame
	return create("Frame")({
		Name = "Line",
		LayoutOrder = index,
		Size = function()
			local rows = math.max(#PinState.lines(), 1)
			return UDim2.fromScale(1, 1 / rows)
		end,
		BackgroundTransparency = 1,
		create("Frame")({
			Name = "IconBox",
			Size = UDim2.fromScale(0.9, 0.9),
			Position = UDim2.fromScale(0, 0.05),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
			ItemIcon({
				item = function()
					return { id = line().item, count = 1 }
				end,
				bare = true,
			}),
		}),
		Rustic.label({
			Name = "Count",
			dark = true,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.fromScale(0.8, 0.8),
			FontFace = Theme.font.number,
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 16,
			TextColor3 = function()
				return if line().done then DONE_COLOR else R.charcoal
			end,
			Text = function()
				local l = line()
				return `{itemName(l.item)} {l.have}/{l.need}`
			end,
		}),
	}) :: Frame
end

local function PinnedRecipe(): Frame
	local lines = vide.derive(PinState.lines)
	return Rustic.paper({
		Name = "PinnedRecipe",
		AnchorPoint = Vector2.new(1, 0),
		Visible = function()
			return #lines() > 0
		end,
		Position = function()
			return UDim2.fromScale(0.98, HudColumnState.column().pinnedY)
		end,
		Size = function()
			return UDim2.fromScale(HudColumn.WIDTH, math.max(HudColumnState.pinnedHeight(), 0.01))
		end,
		create("UIPadding")({
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 8),
			PaddingTop = UDim.new(0, 6),
			PaddingBottom = UDim.new(0, 6),
		}),
		Rustic.label({
			Name = "Title",
			Size = UDim2.new(1, -30, 0, 22),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 18,
			TextColor3 = function()
				return if PinState.ready() then DONE_COLOR else R.emberShadow
			end,
			Text = function()
				local id = PinState.pinned()
				if id == nil then
					return ""
				end
				return Strings.format("hud.pinned.title", { item = itemName(id) })
			end,
		}),
		-- Desafixar sem abrir o livro. Um "X" de letra (o "✕" não existe na fonte e
		-- ficava invisível, visto em 11/11), num botão redondo de couro.
		create("TextButton")({
			Name = "Unpin",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 2, 0, -2),
			Size = UDim2.fromOffset(26, 26),
			BackgroundColor3 = R.emberShadow,
			AutoButtonColor = true,
			Text = "X",
			FontFace = Theme.font.number,
			TextScaled = true,
			TextColor3 = R.cream,
			ZIndex = 3,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			create("UIPadding")({
				PaddingTop = UDim.new(0, 5),
				PaddingBottom = UDim.new(0, 5),
			}),
			Activated = function()
				PinState.pinned(nil)
			end,
		}),
		create("Frame")({
			Name = "Lines",
			Position = UDim2.fromOffset(0, 26),
			Size = UDim2.new(1, 0, 1, -26),
			BackgroundTransparency = 1,
			create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
			vide.indexes(lines, Line),
		}),
	}) :: Frame
end

return PinnedRecipe
