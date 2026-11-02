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
}
