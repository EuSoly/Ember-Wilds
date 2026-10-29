--!strict
local ArmorRules = require("../src/shared/Survival/ArmorRules")

local function helmet(armor: any): any
	return { id = "helmet", nameKey = "item.helmet", category = "armor", maxStack = 1, armor = armor }
end

return {
	["no armor is neutral"] = function()
		local m = ArmorRules.modifiers(nil)
		assert(
			m.defense == 0 and m.coldFactor == 1 and m.hungerFactor == 1 and m.thirstFactor == 1,
			"sem armadura = neutro"
		)
		assert(ArmorRules.reduce(10, ArmorRules.NONE) == 10, "sem defesa não corta dano")
	end,

	["armor fills missing fields"] = function()
		local m = ArmorRules.modifiers(helmet({ defense = 0.25 }))
		assert(m.defense == 0.25, `defense {m.defense}`)
		assert(m.coldFactor == 1 and m.hungerFactor == 1 and m.thirstFactor == 1, "fatores ausentes = 1")
		assert(m.heatFactor == 1, "heatFactor ausente = 1")
		assert(ArmorRules.reduce(20, m) == 15, `20 com 25% de defesa deu {ArmorRules.reduce(20, m)}`)
	end,

	["item without armor block is neutral"] = function()
		local m = ArmorRules.modifiers({ id = "wood", nameKey = "item.wood", category = "resource", maxStack = 255 })
		assert(m == ArmorRules.NONE, "item comum = NONE")
	end,
}
