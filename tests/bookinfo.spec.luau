--!strict
local BookInfo = require("../src/shared/UIFlow/BookInfo")
local Defs = require("../src/shared/Defs")
local Strings = require("../src/shared/Strings")

local function has(list: { string }, id: string): boolean
	return table.find(list, id) ~= nil
end

return {
	["buildings without recipe are not resources"] = function()
		local resources = BookInfo.items("resources", true)
		assert(not has(resources, "reidite_wall"), "parede de reidite não é recurso")
		assert(not has(resources, "stone_extractor"), "extrator não é recurso")
		assert(not has(resources, "water_bucket"), "balde não é recurso")
		assert(has(resources, "reidite"), "o minério de reidite continua material (no Studio)")
		assert(has(resources, "raw_meat"), "carne crua continua recurso")
	end,

	["tools stop at gold for now"] = function()
		local tools = BookInfo.items("tools", false)
		assert(has(tools, "gold_pickaxe"), "ouro fica")
		for _, id in { "diamond_pickaxe", "amethyst_pickaxe", "reidite_pickaxe" } do
			assert(not has(tools, id), id .. " fora por enquanto")
		end
	end,

	["wolf fur comes from wolves"] = function()
		local sources = BookInfo.sources("wolf_fur")
		assert(#sources == 1, "um mob só")
		local source = sources[1] :: any
		assert(source.kind == "mob" and source.id == "wolf" and source.count == 1, "lobo deixa 1")
	end,

	["stone comes from rocks with a pickaxe"] = function()
		local found = false
		for _, source in BookInfo.sources("stone") do
			local s = source :: any
			if s.kind == "resource" and s.id == "rock" then
				found = s.hardness == 1
			end
		end
		assert(found, "rocha, picareta nível 1")
	end,

	["berry bush gives berries with anything in hand"] = function()
		local s = BookInfo.sources("berry")[1] :: any
		assert(s and s.kind == "resource" and s.id == "berry_bush" and s.hardness == nil, "arbusto, qualquer coisa")
	end,

	["decorative pebble is never a source"] = function()
		for id in Defs.Items do
			for _, source in BookInfo.sources(id) do
				assert((source :: any).id ~= "pebble", id)
			end
		end
	end,

	["crafted material has craft and does not break sources"] = function()
		assert(BookInfo.craft("paper") ~= nil, "papel tem receita")
		assert(type(BookInfo.sources("paper")) == "table", "fontes do papel")
	end,

	["item with no source returns empty list"] = function()
		assert(#BookInfo.sources("gold_sword") == 0, "espada não cai de nada")
	end,

	["wood is used in many recipes"] = function()
		local used = BookInfo.usedIn("wood", false)
		assert(has(used, "wood_pickaxe") and has(used, "campfire"), "madeira faz picareta e fogueira")
	end,

	["test-only results hide from used-in"] = function()
		for _, id in BookInfo.usedIn("wood", false) do
			assert(not Defs.Items[id].testOnly, id)
		end
	end,

	["craftable now needs items and station"] = function()
		assert(BookInfo.craftableNow("wood_pickaxe", { wood = 10 }, {}) == true, "tem madeira")
		assert(BookInfo.craftableNow("wood_pickaxe", { wood = 9 }, {}) == false, "falta madeira")
		local kit = { wood = 60, stone = 50, gold = 40, stone_sword = 1 }
		assert(BookInfo.craftableNow("gold_sword", kit, {}) == false, "sem bancada perto")
		assert(BookInfo.craftableNow("gold_sword", kit, { workbench = true }) == true, "com bancada")
		assert(BookInfo.craftableNow("wood", {}, {}) == true, "recurso nunca fica apagado")
	end,

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
