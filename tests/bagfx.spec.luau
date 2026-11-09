--!strict
local BagFxConfig = require("../src/shared/BagFxConfig")
local Defs = require("../src/shared/Defs")

return {
	["the three launch bags have effects"] = function()
		for _, id in { "bag_cubo_gelo", "bag_caranguejo", "bag_cubos_esmeralda" } do
			local list = BagFxConfig.of(id)
			assert(list and #list > 0, id .. " com efeito")
		end
		assert(BagFxConfig.of("bag_default") == nil, "mochila comum sem efeito")
		assert(BagFxConfig.of(nil) == nil, "sem mochila")
	end,

	["every bag with effects is a cosmetic"] = function()
		for _, id in BagFxConfig.bags() do
			local def = Defs.Cosmetics[id]
			assert(def and def.slot == "bag", id .. " cadastrada como mochila")
		end
	end,

	["emitters are well formed"] = function()
		for _, id in BagFxConfig.bags() do
			for i, e in BagFxConfig.of(id) :: { BagFxConfig.Emitter } do
				local where = `{id}[{i}]`
				assert(string.match(e.texture, "^rbxassetid://%d+$"), where .. ": textura")
				assert(#e.colors >= 1 and #e.colors <= 2, where .. ": cores")
				for _, hex in e.colors do
					assert(string.match(hex, "^#%x%x%x%x%x%x$"), where .. ": cor " .. hex)
				end
				assert(#e.size >= 2 and #e.size <= 3 and #e.transparency >= 2 and #e.transparency <= 3, where)
				assert(e.lifetime[1] > 0 and e.lifetime[1] <= e.lifetime[2], where .. ": vida")
				assert(e.rate > 0 and #e.acceleration == 3, where)
			end
		end
	end,

	["nothing comes out standing still, more when walking faster"] = function()
		local e = (BagFxConfig.of("bag_cubo_gelo") :: { BagFxConfig.Emitter })[1]
		assert(BagFxConfig.rate(e, 0) == 0, "parado")
		assert(BagFxConfig.rate(e, BagFxConfig.MIN_WALK / 2) == 0, "quase parado")
		assert(BagFxConfig.rate(e, 1) == e.rate, "andando a toda")
		assert(BagFxConfig.rate(e, 0.5) < BagFxConfig.rate(e, 1), "proporcional")
	end,
}
