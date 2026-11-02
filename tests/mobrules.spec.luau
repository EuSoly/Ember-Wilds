--!strict
local Defs = require("../src/shared/Defs")
local MobRules = require("../src/shared/Mobs/MobRules")

return {
	["damageOf uses mobDamage or the hand"] = function()
		assert(MobRules.damageOf(nil) == 5, "sem item deveria ser 5")
		assert(MobRules.damageOf(Defs.Items.stone_sword) == 19, "espada de pedra deveria ser 19")
		assert(MobRules.damageOf(Defs.Items.wood) == 5, "item sem mobDamage deveria ser 5")
	end,

	["isWebbed is absolute time"] = function()
		assert(MobRules.isWebbed(10, 5) == true, "no prazo deveria prender")
		assert(MobRules.isWebbed(10, 10) == false, "no instante exato já venceu")
		assert(MobRules.isWebbed(10, 11) == false, "vencida não prende")
		assert(MobRules.isWebbed(nil, 5) == false, "nil não prende")
		assert(MobRules.isWebbed("x", 5) == false, "texto não prende")
		assert(MobRules.isWebbed(0 / 0, 5) == false, "NaN não prende")
	end,
}
