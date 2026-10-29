--!strict
-- Regras da armadura vestida (só números: testável no Lune). A armadura vem do
-- bloco `armor` do item em Defs/Items; campos ausentes ficam neutros.
local Types = require("../Defs/Types")

export type Modifiers = {
	defense: number, -- fração do dano de combate cortada
	coldFactor: number, -- multiplica a queda do frio
	hungerFactor: number, -- multiplica a queda da fome
	thirstFactor: number, -- multiplica a queda da sede
	heatFactor: number, -- multiplica quanto o calor sobe
}

local ArmorRules = {}

-- Sem armadura: não corta dano, barras caem no ritmo normal.
ArmorRules.NONE =
	table.freeze({ defense = 0, coldFactor = 1, hungerFactor = 1, thirstFactor = 1, heatFactor = 1 }) :: Modifiers

-- Modificadores de um item (nil ou sem bloco armor = NONE).
function ArmorRules.modifiers(def: Types.ItemDef?): Modifiers
	local armor = def and def.armor
	if armor == nil then
		return ArmorRules.NONE
	end
	return {
		defense = armor.defense or 0,
		coldFactor = armor.coldFactor or 1,
		hungerFactor = armor.hungerFactor or 1,
		thirstFactor = armor.thirstFactor or 1,
		heatFactor = armor.heatFactor or 1,
	}
end

-- Dano de combate depois da defesa.
function ArmorRules.reduce(amount: number, mods: Modifiers): number
	return amount * (1 - mods.defense)
end

return ArmorRules
