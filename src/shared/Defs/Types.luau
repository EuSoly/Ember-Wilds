--!strict
-- Tipos das definições de conteúdo. Ficam num módulo separado para que
-- Tiers, Items e Validate possam usar os mesmos tipos sem depender um do outro.

export type TierDef = {
	id: string,
	-- Posição na escada de progressão (1 = madeira). Ramos laterais (esmeralda) usam 0.
	order: number,
	color: string, -- hex da Palette
	rarityKey: string, -- chave em Strings (raridade de cosmético equivalente)
	nameKey: string, -- chave em Strings
}

export type ItemCategory = "resource" | "food" | "tool" | "weapon" | "armor" | "bag" | "placeable" | "misc"

export type ItemDef = {
	id: string,
	nameKey: string,
	category: ItemCategory,
	tier: string?, -- id em Tiers; nil = moldura neutra (recursos, comida)
	maxStack: number,
	-- Só para category "bag": quantos slots a mochila dá quando vestida.
	bagSlots: number?,
}

export type DefsTables = {
	Tiers: { [string]: TierDef },
	Items: { [string]: ItemDef },
}

return nil
