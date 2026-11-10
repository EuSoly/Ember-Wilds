--!strict
local ArmorRules = require("../src/shared/Survival/ArmorRules")

local function helmet(armor: any): any
	return { id = "helmet", nameKey = "item.helmet", category = "armor", maxStack = 1, armor = armor }
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

return {
	["no armor is neutral"] = function()
		local m = ArmorRules.modifiers(nil)
		assert(m == ArmorRules.NONE, "sem armadura = NONE")
		assert(ArmorRules.reduce(10, m, "player") == 10, "sem defesa não corta golpe de jogador")
		assert(ArmorRules.reduce(10, m, "mob") == 10, "sem defesa não corta mordida")
		assert(ArmorRules.coldMultiplier(m, "forest", true) == 1, "frio normal à noite")
		assert(ArmorRules.coldMultiplier(m, "water", false) == 1, "frio normal na água")
		assert(ArmorRules.oxygenFactor(m) == 1, "fôlego normal")
		assert(ArmorRules.regenFactor(m) == 1, "regen normal")
	end,

	["defense subtracts by source"] = function()
		local m = ArmorRules.modifiers(helmet({ defense = 4, mobDefense = 13 }))
		assert(ArmorRules.reduce(22, m, "player") == 18, `jogador: {ArmorRules.reduce(22, m, "player")}`)
		assert(ArmorRules.reduce(24, m, "mob") == 11, `mob: {ArmorRules.reduce(24, m, "mob")}`)
	end,

	["defense never heals"] = function()
		local m = ArmorRules.modifiers(helmet({ mobDefense = 30 }))
		assert(ArmorRules.reduce(16, m, "mob") == 0, "golpe menor que a defesa = 0")
		assert(ArmorRules.reduce(16, m, "player") == 16, "defesa contra mob não vale para jogador")
	end,

	["coat keeps cold at day"] = function()
		local m = ArmorRules.modifiers(helmet({ warm = { day = 2, night = 13 } }))
		assert(ArmorRules.coldMultiplier(m, "forest", false) == 0, "casaco de dia não perde frio")
		assert(near(ArmorRules.coldMultiplier(m, "forest", true), 5 / 18), "casaco à noite = 5/18")
	end,

	["fur hat warms by day"] = function()
		local m = ArmorRules.modifiers(helmet({ warm = { day = 3, night = 17 } }))
		assert(ArmorRules.coldMultiplier(m, "forest", false) == -0.5, "chapéu de pele esquenta de dia")
		assert(near(ArmorRules.coldMultiplier(m, "forest", true), 1 / 18), "à noite = 1/18")
	end,

	["water uses water warm"] = function()
		local m = ArmorRules.modifiers(helmet({ warm = { day = 9, waterDay = 2, waterNight = 15 } }))
		assert(near(ArmorRules.coldMultiplier(m, "water", false), 3 / 5), "água de dia = 3/5")
		assert(near(ArmorRules.coldMultiplier(m, "water", true), 10 / 25), "água à noite = 10/25")
	end,

	["diving mask oxygen"] = function()
		assert(near(ArmorRules.oxygenFactor(ArmorRules.modifiers(helmet({ oxygenLoss = 14 }))), 11 / 25), "máscara")
		assert(ArmorRules.oxygenFactor(ArmorRules.modifiers(helmet({ oxygenLoss = 30 }))) == 0, "nunca negativo")
	end,

	["life crown regen"] = function()
		local m = ArmorRules.modifiers(helmet({ regenHeal = 40 }))
		assert(near(ArmorRules.regenFactor(m), 40 / 12), "coroa da vida = 40/12")
	end,

	["missing fields are neutral"] = function()
		local m = ArmorRules.modifiers(helmet({ defense = 1 }))
		assert(m.mobDefense == 0 and m.fireHeatFactor == 1 and m.swimSpeed == 1, "faltando = neutro")
		assert(m.hidesName == false and m.explorer == false, "booleanos falsos")
		assert(m.hungerFactor == 1 and m.thirstFactor == 1, "fatores 1")
		assert(m.warm.night == 0 and m.warm.waterDay == 0, "warm ausente = 0")
	end,

	["swap lock"] = function()
		assert(ArmorRules.canSwap(nil, 0), "sem trava troca")
		assert(not ArmorRules.canSwap(10, 9), "antes do fim da trava não troca")
		assert(ArmorRules.canSwap(10, 10), "no fim da trava troca")
	end,

	["explorer stealth"] = function()
		local m = ArmorRules.modifiers(helmet({ explorer = true }))
		assert(ArmorRules.isStealthy(m, nil, 5), "nunca bateu: escondido")
		assert(not ArmorRules.isStealthy(m, 20, 15), "bateu há pouco: visível")
		assert(ArmorRules.isStealthy(m, 20, 20), "passou o tempo: escondido de novo")
		assert(not ArmorRules.isStealthy(ArmorRules.NONE, nil, 5), "sem explorador: visível")
	end,

	["item without armor block is neutral"] = function()
		local m = ArmorRules.modifiers({ id = "wood", nameKey = "item.wood", category = "resource", maxStack = 255 })
		assert(m == ArmorRules.NONE, "item comum = NONE")
	end,
}
