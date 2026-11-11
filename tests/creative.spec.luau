--!strict
local CreativeRules = require("../src/shared/Creative/CreativeRules")
local Defs = require("../src/shared/Defs")
local ItemAccess = require("../src/shared/ItemAccess")

return {
	["creative sees test items like the studio"] = function()
		assert(ItemAccess.allowsTest(true, false), "Studio")
		assert(ItemAccess.allowsTest(false, true), "criativo no jogo publicado")
		assert(ItemAccess.allowsTest(true, true), "os dois")
		assert(not ItemAccess.allowsTest(false, false), "jogador normal no publicado")
	end,

	["gives one tool or a big stack"] = function()
		assert(CreativeRules.giveCount(Defs.Items.lava_sword) == 1, "ferramenta: 1")
		assert(CreativeRules.giveCount(Defs.Items.wood) == 100, "madeira: 100")
		local small: any = { id = "x", nameKey = "x", category = "misc", maxStack = 10 }
		assert(CreativeRules.giveCount(small) == 10, "pilha menor que 100: a pilha")
	end,

	["one give at a time"] = function()
		assert(CreativeRules.canGive(nil, 5), "primeiro pedido")
		assert(not CreativeRules.canGive(5, 5 + CreativeRules.GIVE_EVERY / 2), "rápido demais")
		assert(CreativeRules.canGive(5, 5 + CreativeRules.GIVE_EVERY), "depois do intervalo")
	end,
}
