--!strict
local CrateRules = require("../src/shared/Crate/CrateRules")

return {
	["constants match the spec"] = function()
		assert(CrateRules.PLAYER_LIFETIME == 180, "vida da caixa de jogador")
		assert(CrateRules.MOB_LIFETIME == 60, "vida da caixa de mob")
		assert(CrateRules.HEALTH == 600, "vida da caixa")
		assert(CrateRules.OPEN_RANGE == 8, "alcance para abrir")
		assert(CrateRules.RADIUS == 1.5, "raio da caixa")
		assert(CrateRules.KILL_BONUS == 0.25, "bônus de abate")
	end,

	["killBonus is a quarter of the score, rounded down"] = function()
		assert(CrateRules.killBonus(1000) == 250, "1000 deveria dar 250")
		assert(CrateRules.killBonus(3) == 0, "3 deveria dar 0")
		assert(CrateRules.killBonus(7) == 1, "7 deveria dar 1")
	end,

	["killBonus is 0 for invalid or negative scores"] = function()
		assert(CrateRules.killBonus(-5) == 0, "negativo")
		assert(CrateRules.killBonus(0 / 0) == 0, "NaN")
		assert(CrateRules.killBonus(math.huge) == 0, "infinito")
		assert(CrateRules.killBonus("x" :: any) == 0, "texto")
		assert(CrateRules.killBonus(nil :: any) == 0, "nil")
	end,

	["skinFor prefers the killer skin"] = function()
		assert(CrateRules.skinFor(nil, "a") == "a", "sem matador usa a do morto")
		assert(CrateRules.skinFor("b", "a") == "b", "com matador usa a dele")
	end,

	["item largado: constantes"] = function()
		assert(CrateRules.DROP_LIFETIME == 60, "a caixa de item largado dura 1 min")
		assert(CrateRules.DROP_MERGE_RADIUS > 0, "junta em caixa perto")
		assert(CrateRules.MAX_DROP_SLOTS >= 10, "cabe bastante coisa")
	end,

	["mergeDrop junta na pilha do mesmo item e abre slot novo para outro"] = function()
		local slots = { { id = "wood", count = 5 } }
		assert(CrateRules.mergeDrop(slots, "wood", 3, 65535), "cabe")
		assert(#slots == 1 and slots[1].count == 8, "somou na pilha")
		assert(CrateRules.mergeDrop(slots, "stone", 2, 65535), "cabe")
		assert(#slots == 2 and slots[2].id == "stone" and slots[2].count == 2, "slot novo no fim")
	end,

	["mergeDrop respeita o máximo por slot"] = function()
		local slots = { { id = "wood", count = 9 } }
		assert(CrateRules.mergeDrop(slots, "wood", 5, 10), "cabe")
		assert(slots[1].count == 10 and slots[2].id == "wood" and slots[2].count == 4, "o resto vai em outro slot")
	end,

	["mergeDrop recusa sem mexer quando passaria do limite de slots"] = function()
		local slots = {}
		for i = 1, CrateRules.MAX_DROP_SLOTS do
			slots[i] = { id = "item" .. i, count = 1 }
		end
		assert(not CrateRules.mergeDrop(slots, "novo", 1, 65535), "não cabe slot novo")
		assert(#slots == CrateRules.MAX_DROP_SLOTS, "nada mudou")
		assert(CrateRules.mergeDrop(slots, "item1", 1, 65535), "pilha existente ainda cabe")
		assert(slots[1].count == 2, "somou")
	end,

	["mergeDrop recusa quantidade inválida"] = function()
		local slots = {}
		assert(not CrateRules.mergeDrop(slots, "wood", 0, 65535), "zero")
		assert(not CrateRules.mergeDrop(slots, "wood", 1.5, 65535), "fração")
		assert(not CrateRules.mergeDrop(slots, "wood", 0 / 0, 65535), "NaN")
		assert(#slots == 0, "nada entrou")
	end,
}
