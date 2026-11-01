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

	["progress clamps and handles zero duration"] = function()
		assert(CraftRules.progress(0, 10, 5) == 0.5, "metade do tempo dá metade do progresso")
		assert(CraftRules.progress(0, 10, -1) == 0, "progresso não fica abaixo de zero")
		assert(CraftRules.progress(0, 10, 11) == 1, "progresso não passa do fim")
		assert(CraftRules.progress(2, 2, 2) == 1, "duração zero termina")
	end,
}
