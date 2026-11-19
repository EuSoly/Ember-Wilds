--!strict
local CosmeticTags = require("../src/shared/UIFlow/CosmeticTags")
local Defs = require("../src/shared/Defs")

local function def(id: string, tags: { string }?): any
	return { id = id, nameKey = "x", slot = "body", rarity = 1, tags = tags }
end

return {
	["animated and effects come from the game, limited is marked"] = function()
		local dragon = CosmeticTags.of(Defs.Cosmetics.body_dragao)
		assert(dragon.left == "animated" and not dragon.limited, "dragão: animada à esquerda")
		local iceBag = CosmeticTags.of(Defs.Cosmetics.bag_cubo_gelo)
		assert(iceBag.left == "effects", "mochila de gelo: efeitos à esquerda")
		local plain = CosmeticTags.of(Defs.Cosmetics.body_default)
		assert(plain.left == nil and not plain.limited, "padrão: sem etiqueta")
		local limited = CosmeticTags.of(def("body_dragao", { "limited" }))
		assert(limited.limited and limited.left == "animated", "limitada à direita e animada à esquerda")
	end,

	["list for the detail panel: limited, animated, effects"] = function()
		local list = CosmeticTags.list(def("body_dragao", { "limited" }))
		assert(#list == 2 and list[1] == "limited" and list[2] == "animated", table.concat(list, ","))
		assert(#CosmeticTags.list(Defs.Cosmetics.body_default) == 0, "padrão sem nada")
	end,
}
