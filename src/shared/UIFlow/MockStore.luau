--!strict
-- Dados de exibição da loja: raridades (cores e nomes), as roletas (uma por
-- tipo de skin, com as skins reais do catálogo) e os pesos da vitrine. Preços,
-- chances e produtos de verdade ficam em Shop/ (ShopConfig, Products, Bundles).
local CosmeticCatalog = require("./CosmeticCatalog")

local MockStore = {}

-- Raridades das skins (tabela do Elizeu, 04/11): 5 níveis com cores próprias,
-- do mais comum ao mais raro. Mítico (vermelho) fica acima de Lendário.
export type Rarity = { id: string, nameKey: string, color: string }
MockStore.RARITIES = {
	{ id = "common", nameKey = "shop.rarity.common", color = "#9CA3AF" },
	{ id = "rare", nameKey = "shop.rarity.rare", color = "#3B9DFF" },
	{ id = "epic", nameKey = "shop.rarity.epic", color = "#A855F7" },
	{ id = "legendary", nameKey = "shop.rarity.legendary", color = "#FFBD38" },
	{ id = "mythic", nameKey = "shop.rarity.mythic", color = "#FF4545" },
} :: { Rarity }

-- Só para o carrossel ocioso mostrar as raridades misturadas (não é chance).
MockStore.SHOWCASE_WEIGHTS = { 30, 30, 20, 13, 7 } :: { number }

export type SpinItem = { id: string, nameKey: string, rarity: number, color: string }
export type SpinType = { id: string, nameKey: string, theme: string, items: { SpinItem } }

-- Um tipo de giro por categoria de skin (a caixa de saque e a de morte usam
-- as mesmas skins: um tipo só). Os itens são as skins reais do catálogo; tipo
-- sem skins (acessório, por enquanto) fica com a lista vazia: "Em breve".
MockStore.SPIN_TYPES = {
	{
		id = "body",
		nameKey = "shop.type.body",
		theme = "#D8452B",
		items = CosmeticCatalog.spinItems("body"),
	},
	{
		id = "accessory",
		nameKey = "shop.type.accessory",
		theme = "#7A4FD8",
		items = CosmeticCatalog.spinItems("accessory"),
	},
	{
		id = "bag",
		nameKey = "shop.type.bag",
		theme = "#4E9A2E",
		items = CosmeticCatalog.spinItems("bag"),
	},
	{
		id = "book",
		nameKey = "shop.type.book",
		theme = "#2F7FD8",
		items = CosmeticCatalog.spinItems("book"),
	},
	{
		id = "crate",
		nameKey = "shop.type.crate",
		theme = "#E97F22",
		items = CosmeticCatalog.spinItems("crate"),
	},
} :: { SpinType }

return MockStore
