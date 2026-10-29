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

	-- HUD
	["hud.day"] = "Dia {day}",
	["hud.points"] = "{points} pts",
	["hud.rank"] = "#{rank}",
	["hud.nightComing"] = "A noite está chegando",
	["hud.backpack"] = "Mochila",

	-- Itens
	["item.wood"] = "Madeira",
	["item.stone"] = "Pedra",
	["item.gold"] = "Ouro",
	["item.berry"] = "Frutinha",
	["item.leather_bag"] = "Mochila de Couro",
	["item.wood_pickaxe"] = "Picareta de Madeira",
	["item.stone_pickaxe"] = "Picareta de Pedra",
	["item.gold_pickaxe"] = "Picareta de Ouro",

	-- Cosméticos
	["cosmeticSlot.body"] = "Corpo",
	["cosmetic.body_default"] = "Clássico",
	["cosmetic.body_ember"] = "Brasa",
})
