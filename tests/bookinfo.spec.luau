--!strict
local BookInfo = require("../src/shared/UIFlow/BookInfo")
local Defs = require("../src/shared/Defs")
local Strings = require("../src/shared/Strings")

local function has(list: { string }, id: string): boolean
	return table.find(list, id) ~= nil
end

return {
	["sword craft lists ingredients, workbench and time"] = function()
		local craft = BookInfo.craft("gold_sword")
		assert(craft and craft.station == "workbench" and craft.seconds > 0, "bancada e tempo")
		assert(#craft.ingredients == 4 and craft.count == 1, "quatro ingredientes")
	end,

	["raw item has no craft"] = function()
		assert(BookInfo.craft("wood") == nil, "madeira não se crafta")
	end,

	["every station used by a recipe is in the table"] = function()
		for _, recipe in Defs.Recipes do
			assert(recipe.station == nil or BookInfo.STATIONS[recipe.station], recipe.id)
		end
		assert(BookInfo.STATIONS.water, "água já prevista para receitas futuras")
		assert(Strings.get(BookInfo.STATIONS.water.key) == "Perto da água", "texto da água")
	end,

	["sheet shows every stat, not just three"] = function()
		assert(#BookInfo.stats("gold_sword") >= 4, "todos os dados da espada")
	end,

	["tabs come in the book order"] = function()
		assert(table.concat(BookInfo.TABS, ",") == "tools,weapons,armor,food,build,resources", "ordem das abas")
	end,

	["swords are in weapons"] = function()
		assert(has(BookInfo.items("weapons", false), "gold_sword"), "espada em Armas")
	end,

	["bag sits with armor"] = function()
		assert(has(BookInfo.items("armor", false), "leather_bag"), "mochila em Armaduras")
	end,

	["raw items are resources and food at once"] = function()
		assert(has(BookInfo.items("resources", false), "berry"), "frutinha em Recursos")
		assert(has(BookInfo.items("food", false), "berry"), "frutinha em Comida")
		assert(has(BookInfo.items("resources", false), "wolf_fur"), "pele de lobo em Recursos")
	end,

	["crafted material stays in resources"] = function()
		assert(has(BookInfo.items("resources", false), "paper"), "papel em Recursos")
	end,

	["crafted tool is not a resource"] = function()
		assert(not has(BookInfo.items("resources", false), "wood_pickaxe"), "picareta não é recurso")
	end,

	["test-only items hide outside studio"] = function()
		assert(not has(BookInfo.items("tools", false), "water_bucket"), "balde de teste fora do Studio")
		assert(has(BookInfo.items("tools", true), "water_bucket"), "balde de teste no Studio")
	end,

	["first tab finds the tab of an ingredient"] = function()
		assert(BookInfo.firstTab("stone_sword", false) == "weapons", "espada de pedra")
		assert(BookInfo.firstTab("wood", false) == "resources", "madeira")
	end,

	["recipes come before raw items, by recipe order"] = function()
		local tools = BookInfo.items("tools", false)
		local wood, stone = table.find(tools, "wood_pickaxe"), table.find(tools, "stone_pickaxe")
		assert(wood and stone and wood < stone, "picareta de madeira antes da de pedra")
	end,

	["recipe of finds the recipe by result"] = function()
		local recipe = BookInfo.recipeOf("gold_sword")
		assert(recipe and recipe.result == "gold_sword", "receita da espada de ouro")
		assert(BookInfo.recipeOf("wood") == nil, "madeira não tem receita")
	end,
}
