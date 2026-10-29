--!strict
local LifeRules = require("../src/shared/Data/LifeRules")

return {
	["finish returns seconds lived"] = function()
		local life = LifeRules.start(100)
		assert(life.active == true, "vida nova ativa")
		assert(LifeRules.finish(life, 1060) == 960, "960 segundos vividos")
		assert(life.active == false, "vida terminada")
	end,

	["finish counts only once"] = function()
		local life = LifeRules.start(100)
		LifeRules.finish(life, 200)
		assert(LifeRules.finish(life, 300) == nil, "segundo fim da mesma vida não conta")
	end,

	["finish without a life does nothing"] = function()
		assert(LifeRules.finish(nil, 50) == nil, "sem vida")
	end,

	["days survived are full cycles"] = function()
		assert(LifeRules.daysSurvived(959) == 1, "959 s = 1 ciclo")
		assert(LifeRules.daysSurvived(960) == 2, "960 s = 2 ciclos")
		assert(LifeRules.daysSurvived(479) == 0, "479 s = 0")
		assert(LifeRules.daysSurvived(-1) == 0, "negativo = 0")
		assert(LifeRules.daysSurvived(0 / 0) == 0, "NaN = 0")
	end,
}
