--!strict
-- O que a dica de um item mostra (puro, testado no Lune): o material (tier,
-- com a cor dele) e até MAX_LINES linhas do que o item faz, lidas dos campos
-- do item em Defs/Items. A tela (UI/ItemTooltip) só formata com Strings.
local Defs = require("../Defs")
local Types = require("../Defs/Types")

export type Line = { key: string, vars: { [string]: string | number } }

local ItemInfo = {}

ItemInfo.MAX_LINES = 3

local function percent(fraction: number): number
	return math.floor(fraction * 100 + 0.5)
end

-- Material do item: chave do nome e cor do tier, ou nil sem tier.
function ItemInfo.tier(def: Types.ItemDef): (string?, string?)
	local tier = def.tier and Defs.Tiers[def.tier]
	if tier == nil then
		return nil, nil
	end
	return tier.nameKey, tier.color
end

-- Quantidade no slot, só para o que empilha (madeira, pedra, comida); nil
-- para ferramentas, armas e o resto que ocupa um slot por unidade.
function ItemInfo.quantity(def: Types.ItemDef, count: number): Line?
	if def.maxStack <= 1 then
		return nil
	end
	return { key = "info.count", vars = { value = count } }
end

-- Linhas do que o item faz, na ordem de importância: no máximo `max`
-- (padrão MAX_LINES, o da dica; a ficha do livro pede todas com math.huge).
function ItemInfo.lines(def: Types.ItemDef, max: number?): { Line }
	local limit = max or ItemInfo.MAX_LINES
	local out: { Line } = {}
	local function add(key: string, value: number?)
		if value ~= nil and #out < limit then
			table.insert(out, { key = key, vars = { value = value } })
		end
	end

	local food = def.food
	if food then
		add("info.food.hunger", food.hunger)
		add("info.food.thirst", food.thirst)
		add("info.food.health", food.health)
	end
	if def.pickaxe and #out < limit then
		table.insert(out, { key = "info.pickaxe", vars = { level = def.pickaxe.level } })
	end
	add("info.damage", def.mobDamage)
	if def.moveSpeed and def.moveSpeed < 1 then
		add("info.speed", percent(def.moveSpeed))
	end
	add("info.structureDamage", def.structureDamage)
	add("info.reach", def.reach)
	add("info.equipLock", def.equipLock)
	local armor = def.armor
	if armor then
		if armor.defense and armor.defense > 0 then
			add("info.defense", percent(armor.defense))
		end
		if armor.coldFactor and armor.coldFactor < 1 then
			add("info.cold", percent(1 - armor.coldFactor))
		end
	end
	add("info.bag", def.bagSlots)
	local structure = def.structure
	if structure then
		add("info.health", structure.health)
		add("info.spikes", structure.spikeDamage)
	end
	return out
end

return ItemInfo
