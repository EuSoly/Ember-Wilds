--!strict
-- Textos exibidos em português do Brasil. Chave → texto.
-- Toda chave usada por Defs (nameKey, rarityKey) precisa existir aqui:
-- a validação das Defs falha no boot se faltar alguma.
return table.freeze({
	-- Raridades (iguais aos tiers de material)
	["rarity.common"] = "Comum",
	["rarity.uncommon"] = "Incomum",
	["rarity.rare"] = "Raro",
	["rarity.epic"] = "Épico",
	["rarity.mythic"] = "Mítico",
	["rarity.legendary"] = "Lendário",

	-- Tiers de material
	["tier.wood"] = "Madeira",
	["tier.stone"] = "Pedra",
	["tier.gold"] = "Ouro",
	["tier.diamond"] = "Diamante",
	["tier.amethyst"] = "Ametista",
	["tier.reidite"] = "Reidite",
	["tier.emerald"] = "Esmeralda",

	-- Itens
	["item.wood"] = "Madeira",
	["item.stone"] = "Pedra",
	["item.gold"] = "Ouro",
	["item.berry"] = "Frutinha",
	["item.wood_pickaxe"] = "Picareta de Madeira",
	["item.stone_pickaxe"] = "Picareta de Pedra",
	["item.gold_pickaxe"] = "Picareta de Ouro",
})
