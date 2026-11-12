--!strict
-- Kits só de conquista (Defs.Kits com exclusive = true): fora da loja, fora
-- dos pontos, escondidos até a posse; com a posse valem como kit para sempre.
local Defs = require("../src/shared/Defs")
local Strings = require("../src/shared/Strings")
local KitChoice = require("../src/shared/UIFlow/KitChoice")
local KitRules = require("../src/shared/UIFlow/KitRules")
local Products = require("../src/shared/Shop/Products")

local function ids(list: { any }): { [string]: boolean }
	local set = {}
	for _, kit in list do
		set[kit.id] = true
	end
	return set
end

return {
	["exclusive kit is not sold"] = function()
		for _, product in Products.all() do
			for _, reward in product.rewards do
				assert(
					reward.id ~= "kit_hunter" and reward.id ~= "kit_guardian",
					`produto {product.id} vende kit exclusivo`
				)
			end
		end
		local errors = Products.validate(Defs, Strings :: any)
		assert(#errors == 0, "catálogo com erros: " .. table.concat(errors, " | "))
	end,

	["exclusive kit cannot be bought with points"] = function()
		assert(not KitRules.canBuy(Defs.Kits.kit_hunter, 999999), "kit_hunter comprável com pontos")
		assert(KitRules.canBuy(Defs.Kits.kit_starter, 0), "kit_starter continua grátis")
	end,

	["exclusive kit hidden until owned"] = function()
		local without = ids(KitRules.visible(Defs.Kits, {}))
		assert(not without.kit_hunter and not without.kit_guardian, "exclusivo aparece sem posse")
		assert(without.kit_starter and without.kit_veteran, "kits normais sumiram")
		local with = ids(KitRules.visible(Defs.Kits, { kit_hunter = true }))
		assert(with.kit_hunter and not with.kit_guardian, "posse não mostrou o kit_hunter")
	end,

	["owned exclusive kit comes as a permanent kit"] = function()
		local state = { points = 999999, balance = {}, owned = { kit_hunter = true }, active = "kit_hunter" }
		local kitId, source = KitChoice.resolve({ kitId = "kit_hunter", source = "points" }, state, Defs.Kits)
		assert(kitId == "kit_hunter" and source == "permanent", `veio {kitId} {source}`)
		local notOwned = { points = 999999, balance = {}, owned = {}, active = nil }
		local otherId = KitChoice.resolve({ kitId = "kit_guardian", source = "points" }, notOwned, Defs.Kits)
		assert(otherId == nil, "kit exclusivo veio por pontos")
	end,
}
