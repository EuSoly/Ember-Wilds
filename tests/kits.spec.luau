--!strict
-- Kits falsos montados aqui: os preços e itens reais (Defs/Kits) vão mudar.
local KitRules = require("../src/shared/UIFlow/KitRules")
local Types = require("../src/shared/Defs/Types")
local Defs = require("../src/shared/Defs")
local Products = require("../src/shared/Shop/Products")

type KitDef = Types.KitDef

local function kit(id: string, order: number, price: number): KitDef
	return { id = id, nameKey = `kit.{id}`, order = order, price = price, items = { { id = "wood", count = 1 } } }
end

local CHEAP = kit("cheap", 1, 1000)
local MIDDLE = kit("middle", 2, 4000)
local EXPENSIVE = kit("expensive", 3, 8000)
local FREE = kit("free", 4, 0)

local KITS: { [string]: KitDef } = { expensive = EXPENSIVE, free = FREE, cheap = CHEAP, middle = MIDDLE }

return {
	["sorted follows order"] = function()
		local list = KitRules.sorted(KITS)
		assert(#list == 4, `quantidade de kits: {#list}`)
		for index, entry in list do
			assert(entry.order == index, `kit {entry.id} na posição {index} com order {entry.order}`)
		end
		assert(list[1].id == "cheap", `primeiro: {list[1].id}`)
		assert(list[4].id == "free", `último: {list[4].id}`)
	end,

	["canBuy checks existence and points"] = function()
		assert(KitRules.canBuy(MIDDLE, 5000) == true, "5000 compra o de 4000")
		assert(KitRules.canBuy(MIDDLE, 4000) == true, "preço exato compra")
		assert(KitRules.canBuy(EXPENSIVE, 5000) == false, "5000 não compra o de 8000")
		assert(KitRules.canBuy(FREE, 0) == true, "kit de graça com 0 pontos")
		assert(KitRules.canBuy(nil, 9999) == false, "kit inexistente")
		assert(KitRules.canBuy(CHEAP, 0 / 0) == false, "NaN")
		assert(KitRules.canBuy(CHEAP, math.huge) == false, "infinito")
	end,

	["buy returns the remaining points"] = function()
		local ok, left = KitRules.buy(MIDDLE, 5000)
		assert(ok == true and left == 1000, `comprou {ok}, sobrou {left}`)
		local ok2, left2 = KitRules.buy(EXPENSIVE, 5000)
		assert(ok2 == false and left2 == 5000, `comprou {ok2}, sobrou {left2}`)
		local ok3, left3 = KitRules.buy(nil, 300)
		assert(ok3 == false and left3 == 300, `comprou {ok3}, sobrou {left3}`)
	end,

	["kit_vip is vipOnly and not sold"] = function()
		assert(Defs.Kits.kit_vip.vipOnly == true and Defs.Kits.kit_vip.exclusive == true, "flags")
		assert(Products.get("kit_kit_vip") == nil, "kit_vip à venda")
		assert(Products.get("kitonce_kit_vip") == nil, "kit_vip à venda (1 vida)")
		assert(not KitRules.canBuy(Defs.Kits.kit_vip, 999999), "kit_vip comprável com pontos")
	end,
}
