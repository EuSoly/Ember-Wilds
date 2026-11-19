--!strict
-- Regras das ferramentas novas: escudo na mão, bônus de conjunto, martelo
-- contra material acima e conserto da chave inglesa.
local ArmorRules = require("../src/shared/Survival/ArmorRules")
local BuildRules = require("../src/shared/Build/BuildRules")
local MobRules = require("../src/shared/Mobs/MobRules")

local function item(fields: { [string]: any }): any
	local def: any = { id = "x", nameKey = "x", category = "weapon", maxStack = 1 }
	for k, v in fields do
		def[k] = v
	end
	return def
end

local GOLD_HELMET = ArmorRules.modifiers(item({ category = "armor", armor = { defense = 4, mobDefense = 13 } }))
local GOLD_SHIELD = item({ mobDamage = 3, shield = { defense = 3, mobDefense = 8 } })

return {
	["shield in hand adds to the helmet"] = function()
		assert(ArmorRules.reduce(22, GOLD_HELMET, "player", GOLD_SHIELD) == 15, "jogador: 22 − 4 − 3")
		assert(ArmorRules.reduce(30, GOLD_HELMET, "mob", GOLD_SHIELD) == 9, "mob: 30 − 13 − 8")
		assert(ArmorRules.reduce(24, GOLD_HELMET, "mob", GOLD_SHIELD) == 6, "mob: 24 − 21 = 3, mínimo 25% = 6")
		assert(ArmorRules.reduce(5, GOLD_HELMET, "player", GOLD_SHIELD) == 1.25, "mínimo 25% de 5")
	end,

	["no shield is the helmet alone"] = function()
		assert(ArmorRules.reduce(22, GOLD_HELMET, "player", nil) == 18, "sem nada na mão")
		local sword = item({ mobDamage = 22 })
		assert(ArmorRules.reduce(22, GOLD_HELMET, "player", sword) == 18, "espada na mão não defende")
	end,

	["gear bonus needs the matching helmet"] = function()
		local sword = item({ mobDamage = 30, gearBonus = { set = "dragon", damage = 3 } })
		local dragon = item({ category = "armor", armor = { defense = 8, gearSet = "dragon" } })
		local lava = item({ category = "armor", armor = { defense = 9, gearSet = "lava" } })
		local plain = item({ category = "armor", armor = { defense = 1 } })
		assert(MobRules.damageOf(sword, dragon) == 33, "conjunto completo")
		assert(MobRules.damageOf(sword, lava) == 30, "outro conjunto")
		assert(MobRules.damageOf(sword, plain) == 30, "capacete sem conjunto")
		assert(MobRules.damageOf(sword, nil) == 30, "sem capacete")
		assert(MobRules.damageOf(nil, dragon) == MobRules.HAND_DAMAGE, "mão")
	end,

	["hammer is weak against a higher material"] = function()
		local hammer = item({ category = "tool", structureDamage = 20, hammer = { minDamage = 5 } })
		assert(BuildRules.damageOf(hammer, 3, 2) == 5, "martelo de pedra em parede de ouro")
		assert(BuildRules.damageOf(hammer, 2, 2) == 20, "mesmo material")
		assert(BuildRules.damageOf(hammer, 1, 2) == 20, "material abaixo")
		assert(BuildRules.damageOf(hammer, nil, 2) == 20, "construção sem material")
		local sword = item({ structureDamage = 10 })
		assert(BuildRules.damageOf(sword, 6, 3) == 10, "só martelo cai")
	end,

	["wrench repairs without passing the max"] = function()
		local wrench = item({ category = "tool", repair = 70 })
		assert(BuildRules.repairAmount(wrench, 900, 1000) == 70, "conserta 70")
		assert(BuildRules.repairAmount(wrench, 980, 1000) == 20, "só até o máximo")
		assert(BuildRules.repairAmount(wrench, 1000, 1000) == 0, "cheia")
		assert(BuildRules.repairAmount(item({ structureDamage = 10 }), 500, 1000) == 0, "sem repair")
		assert(BuildRules.repairAmount(nil, 500, 1000) == 0, "mão")
	end,
}
