--!strict
-- Receitas disponíveis agora e progresso do craft na HUD.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local CraftRules = require(Shared:WaitForChild("Craft"):WaitForChild("CraftRules"))
local Defs = require(Shared:WaitForChild("Defs"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local CraftState = require(script.Parent.Parent:WaitForChild("CraftState"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))
local Kit = require(script.Parent:WaitForChild("Kit"))

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

local function RecipeTooltip(): Frame
	return Kit.panel({
		Name = "RecipeTooltip",
		Visible = function()
			return hoveredRecipe() ~= nil
		end,
		Active = true,
		ZIndex = 10,
		-- Mantém o tooltip dentro da área segura do HUD, ao lado da grade.
		-- Posicionar acima da lista o colocava sob a barra superior do Roblox.
		Position = UDim2.fromOffset(GRID_WIDTH + 12, 0),
		Size = UDim2.fromOffset(240, 112),
		Kit.text({
			Name = "Name",
			ZIndex = 11,
			Size = UDim2.new(1, -16, 0, 30),
			Position = UDim2.fromOffset(8, 5),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				local recipe = hoveredRecipe()
				local def = recipe and Defs.Items[recipe.result]
				return if def then Strings.get(def.nameKey) else ""
			end,
			maxSize = 20,
		}),
		Kit.text({
			Name = "Ingredients",
			ZIndex = 11,
			Size = UDim2.new(1, -16, 0, 50),
			Position = UDim2.fromOffset(8, 34),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			Text = function()
				local recipe = hoveredRecipe()
				return if recipe then materialText(recipe) else ""
			end,
			FontFace = Theme.font.body,
			maxSize = 15,
		}),
		Kit.text({
			Name = "TimeAndStation",
			ZIndex = 11,
			Size = UDim2.new(1, -16, 0, 22),
			Position = UDim2.fromOffset(8, 85),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				local recipe = hoveredRecipe()
				return if recipe then durationText(recipe) else ""
			end,
			maxSize = 14,
		}),
	})
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
		BackgroundTransparency = Theme.panelTransparency,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = Theme.slotCorner }),
		create("UIStroke")({
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
		ItemIcon({
			item = function()
				local recipe = currentRecipe()
				return { id = recipe.result, count = recipe.count }
			end,
		}),
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
