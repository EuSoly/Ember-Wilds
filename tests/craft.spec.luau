--!strict
local CraftRules = require("../src/shared/Craft/CraftRules")
local Inventory = require("../src/shared/Inventory")

local function recipe(id: string, order: number, station: string?): any
	return {
		id = id,
		result = "tool",
		count = 1,
		ingredients = { { id = "wood", count = 2 } },
		time = 15,
		station = station,
		order = order,
	}
end

local function maxStack(id: string): number
	return if id == "tool" then 1 else 255
end

return {
	["combined stations need all"] = function()
		local r = recipe("crown", 1, "workbench")
		r.alsoNear = { "fire", "water" }
		local counts = { wood = 2 }
		assert(not CraftRules.canCraft(r, counts, { workbench = true, fire = true }), "falta a água")
		assert(CraftRules.missingStation(r, { workbench = true, fire = true }) == "water", "aponta a água")
		assert(CraftRules.canCraft(r, counts, { workbench = true, fire = true, water = true }), "com as três")
		assert(CraftRules.missingStation(r, { workbench = true, fire = true, water = true }) == nil, "nada falta")
		local all = CraftRules.stationsOf(r)
		assert(#all == 3 and all[1] == "workbench" and all[3] == "water", "ordem das estações")
		assert(#CraftRules.stationsOf(recipe("x", 1, nil)) == 0, "sem estação")
	end,

	["materials exact or insufficient"] = function()
		local r = recipe("tool", 1, nil)
		assert(CraftRules.hasIngredients(r, { wood = 2 }))
		assert(not CraftRules.hasIngredients(r, { wood = 1 }), "precisa recusar materiais insuficientes")
	end,

	["station is required only when recipe asks"] = function()
		local r = recipe("tool", 1, "workbench")
		assert(not CraftRules.canCraft(r, { wood = 2 }, {}), "precisa da bancada")
		assert(CraftRules.canCraft(r, { wood = 2 }, { workbench = true }))
		assert(CraftRules.canCraft(recipe("tool", 1, nil), { wood = 2 }, {}))
	end,

	["held book multiplies crafting speed"] = function()
		local r = recipe("tool", 1, nil)
		assert(CraftRules.duration(r, nil) == 15, "sem livro usa o tempo base")
		assert(CraftRules.duration(r, { craftSpeed = 3 } :: any) == 5, "livro triplica a velocidade")
	end,

	["craftable filters and sorts by order"] = function()
		local recipes = {
			late = recipe("late", 3, nil),
			station = recipe("station", 1, "fire"),
			early = recipe("early", 2, nil),
		}
		local out = CraftRules.craftable(recipes, { wood = 2 }, {})
		assert(#out == 2 and out[1].id == "early" and out[2].id == "late", "filtra e ordena as receitas")
	end,

	["fits when ingredients free a result slot"] = function()
		local inv = Inventory.new(1)
		Inventory.add(inv, "wood", 2, 255)
		local r = recipe("tool", 1, nil)
		assert(CraftRules.fits(inv, r, maxStack))
		assert(inv.slots[1].id == "wood" and inv.slots[1].count == 2, "fits não deve alterar o original")
	end,

	["fits rejects full inventory of other items"] = function()
		local inv = Inventory.new(1)
		Inventory.add(inv, "wood", 10, 255)
		local r = recipe("tool", 1, nil)
		r.ingredients = { { id = "wood", count = 2 } }
		assert(not CraftRules.fits(inv, r, maxStack), "o resultado não cabe no espaço ocupado")
	end,

	["worn piece counts as ingredient"] = function()
		local r = recipe("stone_helmet", 1, nil)
		r.ingredients = { { id = "stone", count = 2 }, { id = "wood_helmet", count = 1 } }
		local counts = { stone = 2 }
		assert(not CraftRules.hasIngredients(r, counts), "sem o capacete no inventário")
		assert(CraftRules.hasIngredients(r, CraftRules.withWorn(counts, "wood_helmet")), "o vestido conta")
		assert(counts.wood_helmet == nil, "withWorn não altera o original")
		local parts, usesWorn = CraftRules.split(r, counts, "wood_helmet")
		assert(usesWorn, "consome o vestido")
		assert(#parts == 1 and parts[1].id == "stone", "só a pedra sai do inventário")
	end,

	["inventory copy is used before the worn piece"] = function()
		local r = recipe("stone_helmet", 1, nil)
		r.ingredients = { { id = "wood_helmet", count = 1 } }
		local parts, usesWorn = CraftRules.split(r, { wood_helmet = 1 }, "wood_helmet")
		assert(not usesWorn and #parts == 1, "o do inventário vai primeiro")
		local other, usesOther = CraftRules.split(r, {}, "hood")
		assert(not usesOther and #other == 1, "peça vestida diferente não entra")
	end,

	["fits counts only what leaves the inventory"] = function()
		-- Inventário cheio só de pedra: sem o capacete na mochila, a pedra
		-- gasta libera o slot do capacete novo.
		local inv = Inventory.new(1)
		Inventory.add(inv, "stone", 2, 255)
		local r = recipe("tool", 1, nil)
		r.ingredients = { { id = "stone", count = 2 }, { id = "wood_helmet", count = 1 } }
		local parts = CraftRules.split(r, { stone = 2 }, "wood_helmet")
		assert(CraftRules.fits(inv, r, maxStack, parts), "cabe usando o capacete vestido")
		assert(not CraftRules.fits(inv, r, maxStack), "sem split falta o capacete no inventário")
	end,

	["progress clamps and handles zero duration"] = function()
		assert(CraftRules.progress(0, 10, 5) == 0.5, "metade do tempo dá metade do progresso")
		assert(CraftRules.progress(0, 10, -1) == 0, "progresso não fica abaixo de zero")
		assert(CraftRules.progress(0, 10, 11) == 1, "progresso não passa do fim")
		assert(CraftRules.progress(2, 2, 2) == 1, "duração zero termina")
	end,
}
