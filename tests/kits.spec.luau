--!strict
local Defs = require("../src/shared/Defs")
local KitRules = require("../src/shared/UIFlow/KitRules")

return {
	["sorted follows order"] = function()
		local list = KitRules.sorted(Defs.Kits)
		assert(#list == 4, `quantidade de kits: {#list}`)
		for index, kit in list do
			assert(kit.order == index, `kit {kit.id} na posição {index} com order {kit.order}`)
		end
		assert(list[1].id == "kit_starter", `primeiro: {list[1].id}`)
		assert(list[4].id == "kit_veteran", `último: {list[4].id}`)
	end,

	["canBuy checks existence and points"] = function()
		assert(KitRules.canBuy(Defs.Kits.kit_survivor, 5000) == true, "5000 compra o de 4000")
		assert(KitRules.canBuy(Defs.Kits.kit_survivor, 4000) == true, "preço exato compra")
		assert(KitRules.canBuy(Defs.Kits.kit_veteran, 5000) == false, "5000 não compra o de 8000")
		assert(KitRules.canBuy(nil, 9999) == false, "kit inexistente")
		assert(KitRules.canBuy(Defs.Kits.kit_starter, 0 / 0) == false, "NaN")
		assert(KitRules.canBuy(Defs.Kits.kit_starter, math.huge) == false, "infinito")
	end,

	["buy returns the remaining points"] = function()
		local ok, left = KitRules.buy(Defs.Kits.kit_survivor, 5000)
		assert(ok == true and left == 1000, `comprou {ok}, sobrou {left}`)
		local ok2, left2 = KitRules.buy(Defs.Kits.kit_veteran, 5000)
		assert(ok2 == false and left2 == 5000, `comprou {ok2}, sobrou {left2}`)
		local ok3, left3 = KitRules.buy(nil, 300)
		assert(ok3 == false and left3 == 300, `comprou {ok3}, sobrou {left3}`)
	end,
}
