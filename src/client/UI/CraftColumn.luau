--!strict
-- Receitas disponíveis agora e progresso do craft na HUD.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local CraftRules = require(Shared:WaitForChild("Craft"):WaitForChild("CraftRules"))
local Defs = require(Shared:WaitForChild("Defs"))
local HudImages = require(Shared:WaitForChild("HudImages"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local CraftState = require(script.Parent.Parent:WaitForChild("CraftState"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create
local ICON_SIZE = 52
local GRID_COLUMNS = 4
local GRID_GAP = 5
local GRID_WIDTH = GRID_COLUMNS * ICON_SIZE + (GRID_COLUMNS - 1) * GRID_GAP + 4
local hover = vide.source(nil :: string?)

local function materialText(recipe: Defs.RecipeDef): string
	local parts: { string } = {}
	for _, ingredient in recipe.ingredients do
		local def = Defs.Items[ingredient.id]
		table.insert(parts, `{ingredient.count}× {if def then Strings.get(def.nameKey) else ingredient.id}`)
	end
	return table.concat(parts, "\n")
end

local function durationText(recipe: Defs.RecipeDef): string
	local equipped = CraftState.equipped()
	local item = if type(equipped) == "string" then Defs.Items[equipped] else nil
	local seconds = CraftRules.duration(recipe, item)
	local station = if recipe.station == "workbench"
		then Strings.get("craft.station.workbench")
		elseif recipe.station == "fire" then Strings.get("craft.station.fire")
		else Strings.get("craft.station.none")
	return `{string.format("%.0f", seconds)} s · {station}`
end

local function hoveredRecipe(): Defs.RecipeDef?
	local id = hover()
	return if id then Defs.Recipes[id] else nil
end

-- Balão da receita: nome, ingredientes e tempo/estação, na fonte do HUD e
-- recuados da borda do papel (mesmas medidas da dica do item).
local TIP_WIDTH = 260
local TIP_PAD_X = 22
local TIP_PAD_Y = 18
local TIP_NAME = 28
local TIP_LINE = 22

-- Altura dos ingredientes: uma linha por ingrediente.
local function ingredientsHeight(): number
	local recipe = hoveredRecipe()
	return TIP_LINE * math.max(if recipe then #recipe.ingredients else 1, 1)
end

local function RecipeTooltip(): Frame
	return Kit.tooltip({
		Name = "RecipeTooltip",
		Visible = function()
			return hoveredRecipe() ~= nil
		end,
		Active = true,
		ZIndex = 10,
		-- Mantém o tooltip dentro da área segura do HUD, ao lado da grade.
		-- Posicionar acima da lista o colocava sob a barra superior do Roblox.
		Position = UDim2.fromOffset(GRID_WIDTH + 12, 0),
		Size = function()
			return UDim2.fromOffset(TIP_WIDTH, TIP_PAD_Y * 2 + TIP_NAME + ingredientsHeight() + TIP_LINE)
		end,
		Rustic.label({
			dark = true,
			Name = "Name",
			ZIndex = 11,
			Size = UDim2.new(1, -2 * TIP_PAD_X, 0, TIP_NAME),
			Position = UDim2.fromOffset(TIP_PAD_X, TIP_PAD_Y),
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Theme.font.number,
			Text = function()
				local recipe = hoveredRecipe()
				local def = recipe and Defs.Items[recipe.result]
				return if def then Strings.get(def.nameKey) else ""
			end,
			maxSize = 20,
		}),
		Rustic.label({
			dark = true,
			Name = "Ingredients",
			ZIndex = 11,
			Size = function()
				return UDim2.new(1, -2 * TIP_PAD_X, 0, ingredientsHeight())
			end,
			Position = UDim2.fromOffset(TIP_PAD_X, TIP_PAD_Y + TIP_NAME),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			FontFace = Theme.font.number,
			Text = function()
				local recipe = hoveredRecipe()
				return if recipe then materialText(recipe) else ""
			end,
			maxSize = 16,
		}),
		Rustic.label({
			dark = true,
			Name = "TimeAndStation",
			ZIndex = 11,
			Size = UDim2.new(1, -2 * TIP_PAD_X, 0, TIP_LINE),
			Position = function()
				return UDim2.fromOffset(TIP_PAD_X, TIP_PAD_Y + TIP_NAME + ingredientsHeight())
			end,
			TextXAlignment = Enum.TextXAlignment.Left,
			FontFace = Theme.font.number,
			Text = function()
				local recipe = hoveredRecipe()
				return if recipe then durationText(recipe) else ""
			end,
			maxSize = 16,
		}),
	})
end

-- Arte do slot atrás do ícone da receita (dourada na receita sendo feita).
-- Lista vazia sem a arte.
local function slotArt(active: () -> boolean): { Instance }
	if not HudImages.has(HudImages.SLOT) then
		return {}
	end
	return {
		create("ImageLabel")({
			Name = "Art",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Stretch,
			Image = function()
				return if active() then HudImages.SLOT_SELECTED else HudImages.SLOT
			end,
			ZIndex = 0,
		}),
	}
end

-- Ícone do resultado da receita; com a arte, sem a moldura do tier e dentro
-- da borda de madeira do slot.
local function recipeIcon(currentRecipe: () -> Defs.RecipeDef): Instance
	local icon = ItemIcon({
		item = function()
			local recipe = currentRecipe()
			return { id = recipe.result, count = recipe.count }
		end,
		bare = HudArt.HAS_SLOT,
	})
	return if HudArt.HAS_SLOT then HudArt.inSlot(icon) else icon
end

local function recipeButton(row: () -> CraftState.Row): TextButton
	local function currentRecipe(): Defs.RecipeDef
		return Defs.Recipes[row().id]
	end
	local active = function()
		local current = CraftState.current()
		return current ~= nil and current.id == row().id
	end
	local fraction = vide.derive(function()
		local current = CraftState.current()
		if current == nil or current.id ~= row().id then
			return 0
		end
		return CraftRules.progress(current.start, current.finish, CraftState.now())
	end)
	local button = create("TextButton")({
		Name = function()
			return `Craft_{row().id}`
		end,
		LayoutOrder = function()
			return row().order
		end,
		Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.ui.panel,
		-- Com a arte do slot, o couro e a madeira fazem o fundo e a borda.
		BackgroundTransparency = if HudImages.has(HudImages.SLOT) then 1 else Theme.panelTransparency,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = Theme.slotCorner }),
		slotArt(active),
		create("UIStroke")({
			Transparency = if HudImages.has(HudImages.SLOT) then 1 else 0,
			Color = function()
				return if active() then Theme.ui.action else Theme.ui.border
			end,
			Thickness = function()
				return if active() then 2 else Theme.strokeThickness
			end,
		}),
		MouseEnter = function()
			hover(row().id)
		end,
		MouseLeave = function()
			if hover() == row().id then
				hover(nil)
			end
		end,
		InputBegan = function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.Touch then
				hover(row().id)
			elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
				if active() then
					CraftState.cancel()
				end
			end
		end,
		InputEnded = function(input: InputObject)
			if input.UserInputType == Enum.UserInputType.Touch and hover() == row().id then
				hover(nil)
			end
		end,
		Activated = function()
			CraftState.toggle(row().id)
		end,
		recipeIcon(currentRecipe),
		create("Frame")({
			Name = "ProgressFill",
			Visible = active,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.fromScale(0, 1),
			Size = function()
				return UDim2.fromScale(1, fraction())
			end,
			BackgroundColor3 = Theme.ui.action,
			BackgroundTransparency = 0.38,
			BorderSizePixel = 0,
			ZIndex = 3,
			create("UICorner")({ CornerRadius = Theme.slotCorner }),
		}),
	}) :: TextButton
	return button
end

local function CraftColumn(): Frame
	return create("Frame")({
		Name = "CraftColumn",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0.02, 0.12),
		Size = UDim2.new(0, GRID_WIDTH + 240 + 12, 0.68, 0),
		BackgroundTransparency = 1,
		create("ScrollingFrame")({
			Name = "RecipeList",
			Size = UDim2.new(0, GRID_WIDTH, 1, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.ui.border,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			create("UIGridLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				FillDirectionMaxCells = GRID_COLUMNS,
				CellSize = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
				CellPadding = UDim2.fromOffset(GRID_GAP, GRID_GAP),
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			vide.indexes(CraftState.rows, function(row)
				return recipeButton(row)
			end),
		}),
		RecipeTooltip(),
	}) :: Frame
end

return CraftColumn
