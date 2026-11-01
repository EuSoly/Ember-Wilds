--!strict
-- Livro completo de receitas, desenhado pelo molde RecipeBook.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local CraftRules = require(Shared:WaitForChild("Craft"):WaitForChild("CraftRules"))
local Defs = require(Shared:WaitForChild("Defs"))
local Strings = require(Shared:WaitForChild("Strings"))
local CraftState = require(script.Parent.Parent:WaitForChild("CraftState"))
local InventoryState = require(script.Parent.Parent:WaitForChild("InventoryState"))
local ItemIcon = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("ItemIcon"))
local Theme = require(Shared:WaitForChild("Theme"))
local Template = require(script.Parent.Parent:WaitForChild("UITemplates"):WaitForChild("Template"))

local TEMPLATE = "RecipeBook"
local ROW_TEMPLATE = "RecipeRow"
local RecipeBookScreen = { open = vide.source(false) }

function RecipeBookScreen.toggle()
	RecipeBookScreen.open(not vide.untrack(RecipeBookScreen.open))
end

local function counts(): { [string]: number }
	local result = {}
	for _, slot in InventoryState.slots() do
		result[slot.id] = (result[slot.id] or 0) + slot.count
	end
	return result
end

local function buildRow(list: Instance, recipe: Defs.RecipeDef)
	local row = Template.clone(ROW_TEMPLATE)
	if row == nil then
		return
	end
	row.Name = recipe.id
	if row:IsA("GuiObject") then
		row.LayoutOrder = recipe.order
	end
	Template.bind(row)
	local icon = Template.find(row, "Icon", "Frame")
	if icon then
		ItemIcon({
			item = function()
				return { id = recipe.result, count = recipe.count }
			end,
		}).Parent =
			icon
	end
	local item = Defs.Items[recipe.result]
	Template.setText(
		Template.find(row, "NameLabel", "TextLabel"),
		`{recipe.count}× {if item then Strings.get(item.nameKey) else recipe.result}`
	)
	local ingredientsLabel = Template.find(row, "IngredientsLabel", "TextLabel") :: TextLabel?
	local infoLabel = Template.find(row, "InfoLabel", "TextLabel") :: TextLabel?
	if ingredientsLabel then
		ingredientsLabel.RichText = true
	end
	vide.effect(function()
		local current = counts()
		local pieces: { string } = {}
		for _, ingredient in recipe.ingredients do
			local def = Defs.Items[ingredient.id]
			local name = if def then Strings.get(def.nameKey) else ingredient.id
			local enough = (current[ingredient.id] or 0) >= ingredient.count
			local text = `{ingredient.count}× {name}`
			table.insert(pieces, if enough then text else `<font color="#FF645A">{text}</font>`)
		end
		if ingredientsLabel then
			ingredientsLabel.Text = table.concat(pieces, ", ")
		end
		if infoLabel then
			local equipped = CraftState.equipped()
			local held = if type(equipped) == "string" then Defs.Items[equipped] else nil
			local seconds = string.format("%.0f", CraftRules.duration(recipe, held))
			local station = if recipe.station == "workbench"
				then Strings.get("craft.station.workbench")
				elseif recipe.station == "fire" then Strings.get("craft.station.fire")
				else Strings.get("craft.station.none")
			local ready = recipe.station == nil or CraftState.near()[recipe.station] == true
			infoLabel.Text = `{seconds} s · {station}`
			infoLabel.TextColor3 = if ready then Theme.ui.text else Theme.ui.warning
		end
	end)
	row.Parent = list
end

function RecipeBookScreen.mount(playerGui: Instance): ScreenGui?
	local gui = Template.clone(TEMPLATE)
	if gui == nil or not gui:IsA("ScreenGui") then
		return nil
	end
	gui.ResetOnSpawn = false
	gui.Enabled = false
	Template.bind(gui)
	local list = Template.find(gui, "List", "GuiObject")
	if list then
		local sorted = {}
		for _, recipe in Defs.Recipes do
			table.insert(sorted, recipe)
		end
		table.sort(sorted, function(a, b)
			return a.order < b.order
		end)
		for _, recipe in sorted do
			buildRow(list, recipe)
		end
	end
	local close = Template.find(gui, "CloseButton", "GuiButton") :: GuiButton?
	if close then
		close.Activated:Connect(function()
			RecipeBookScreen.open(false)
		end)
	end
	gui.Parent = playerGui
	return gui
end

return RecipeBookScreen
