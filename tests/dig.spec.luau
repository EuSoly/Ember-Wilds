--!strict
-- Cavar com a pá (src/shared/Gather/DigRules): terra no chão da floresta,
-- areia nas margens, nada na água; achados de sorte da config do Starve.
local Defs = require("../src/shared/Defs")
local DigRules = require("../src/shared/Gather/DigRules")

local NO_LUCK = { 1, 1, 1 } -- sorteios que nunca acertam achado

local function total(list: { DigRules.Find }, id: string): number
	local n = 0
	for _, find in list do
		if find.id == id then
			n += find.count
		end
	end
	return n
end

return {
	["ground and sand are resources"] = function()
		for _, id in { "ground", "sand" } do
			local item = (Defs.Items :: any)[id]
			assert(item ~= nil and item.category == "resource" and item.maxStack == 255, `{id}: recurso`)
			assert(item.testOnly ~= true, `{id}: liberado`)
		end
	end,

	["only shovels dig"] = function()
		assert(DigRules.canDig(Defs.Items.stone_shovel), "pá de pedra cava")
		assert(not DigRules.canDig(Defs.Items.stone_pickaxe), "picareta não cava")
		assert(not DigRules.canDig(nil), "mão vazia não cava")
	end,

	["shovel tier sets how much it digs"] = function()
		local stone = DigRules.dig(Defs.Items.stone_shovel, "ground", NO_LUCK, Defs)
		assert(total(stone, "ground") == 1, "pá de pedra: 1 terra")
		local gold = DigRules.dig(Defs.Items.gold_shovel, "ground", NO_LUCK, Defs)
		assert(total(gold, "ground") == 2, "pá de ouro: 2 terras")
	end,

	["river bank gives sand"] = function()
		local finds = DigRules.dig(Defs.Items.gold_shovel, "sand", NO_LUCK, Defs)
		assert(total(finds, "sand") == 2 and total(finds, "ground") == 0, "margem dá areia")
	end,

	["water gives nothing"] = function()
		assert(DigRules.surfaceAt(true, true) == nil, "água ganha da areia")
		assert(DigRules.surfaceAt(false, true) == "sand", "margem")
		assert(DigRules.surfaceAt(false, false) == "ground", "chão")
	end,

	["lucky rolls find stone and gold but never test only items"] = function()
		-- Sorteios na ordem de DIG_ITEMS: pedra 5%, ouro ~1,5%, diamante ~0,17%.
		local finds = DigRules.dig(Defs.Items.stone_shovel, "ground", { 0.01, 0.01, 0.0001 }, Defs)
		assert(total(finds, "stone") == 1, "achou pedra")
		assert(total(finds, "gold") == 1, "achou ouro")
		assert(total(finds, "diamond") == 0, "diamante ainda é de teste")
		local none = DigRules.dig(Defs.Items.stone_shovel, "ground", { 0.06, 0.02, 0.5 }, Defs)
		assert(total(none, "stone") == 0 and total(none, "gold") == 0, "sem sorte")
	end,
}
