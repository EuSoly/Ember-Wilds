--!strict
-- Dados falsos do mockup de loja e perfil (G7a e UI 2).
-- Tudo que é número ou nome inventado fica aqui, num lugar só, para apagar
-- quando a loja de verdade existir. Nada daqui compra, grava ou sorteia de
-- verdade: o sorteio da loja (SpinRules) só escolhe o que a animação mostra.
local CosmeticCatalog = require("./CosmeticCatalog")

local MockStore = {}

export type Pack = { amount: number, robux: number, tag: string? }

-- Pacotes de moeda (quantidade ↔ preço em Robux).
MockStore.PACKS = {
	{ amount = 300, robux = 80 },
	{ amount = 600, robux = 150 },
	{ amount = 2600, robux = 600, tag = "popular" },
	{ amount = 7000, robux = 1500, tag = "off30" },
	{ amount = 20000, robux = 3500, tag = "best" },
} :: { Pack }

-- Kits iniciais com Robux (mockup da UI 1): preço para 1 vida e para sempre,
-- por id de Defs.Kits. Provisórios: o Elizeu ajusta. Apagar daqui quando a
-- compra real existir (aí os preços vão para Defs.Kits).
export type KitRobux = { once: number, forever: number }
MockStore.KIT_ROBUX = {
	kit_starter = { once = 15, forever = 99 },
	kit_explorer = { once = 25, forever = 199 },
	kit_survivor = { once = 49, forever = 399 },
	kit_veteran = { once = 99, forever = 799 },
} :: { [string]: KitRobux }

-- Kits que o mockup já começa tendo para sempre (para mostrar o botão "Usar").
MockStore.KIT_STARTS_OWNED = { "kit_starter" } :: { string }

-- ================= Loja (UI 2) =================

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

-- Chances (%) por raridade, na ordem acima (tabela do Elizeu).
MockStore.SPIN_ODDS = {
	normal = { 30, 40, 23, 6, 1 }, -- giro com Golden Ember
	paid = { 5, 25, 40, 25, 5 }, -- giro especial com Robux
}
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

export type SpinPrice = { qty: number, price: number }
MockStore.SPIN_PRICES = {
	normal = { { qty = 1, price = 100 }, { qty = 3, price = 280 }, { qty = 10, price = 850 } }, -- Golden Ember
	paid = { { qty = 1, price = 49 }, { qty = 3, price = 129 }, { qty = 10, price = 399 } }, -- Robux
} :: { normal: { SpinPrice }, paid: { SpinPrice } }

-- Pacotes em destaque (só Robux): conjunto de corpo, livro, mochila e caixa.
-- endsIn = segundos até a oferta acabar, contados a partir de abrir a loja.
export type BundleItem = { type: string, nameKey: string }
export type Bundle = {
	id: string,
	nameKey: string,
	rarity: number,
	theme: string,
	robux: number,
	endsIn: number,
	items: { BundleItem },
}

local function bundleItems(id: string): { BundleItem }
	local list: { BundleItem } = {}
	for _, typeId in { "body", "book", "bag", "crate" } do
		table.insert(list, { type = typeId, nameKey = `shop.bundle.{id}.{typeId}` })
	end
	return list
end

local DAY, HOUR, MINUTE = 86400, 3600, 60
MockStore.BUNDLES = {
	{
		id = "brasa",
		nameKey = "shop.bundle.brasa",
		rarity = 5,
		theme = "#B8361A",
		robux = 399,
		endsIn = 2 * DAY + 10 * HOUR + 7 * MINUTE,
		items = bundleItems("brasa"),
	},
	{
		id = "geada",
		nameKey = "shop.bundle.geada",
		rarity = 4,
		theme = "#2F7FD8",
		robux = 349,
		endsIn = 5 * DAY + 2 * HOUR + 40 * MINUTE,
		items = bundleItems("geada"),
	},
	{
		id = "musgo",
		nameKey = "shop.bundle.musgo",
		rarity = 2,
		theme = "#4E9A2E",
		robux = 299,
		endsIn = 12 * HOUR + 5 * MINUTE,
		items = bundleItems("musgo"),
	},
} :: { Bundle }

-- Gamepasses (provisórias): os kits para sempre (mesmo preço do painel de
-- kits) e o VIP de +3 espaços que o jogo já tem preparado.
export type Pass = { id: string, nameKey: string, descKey: string, robux: number, kitId: string? }

local function kitPass(kitId: string): Pass
	return {
		id = kitId,
		nameKey = `shop.pass.{kitId}`,
		descKey = "shop.pass.forever",
		robux = MockStore.KIT_ROBUX[kitId].forever,
		kitId = kitId,
	}
end

MockStore.PASSES = {
	kitPass("kit_starter"),
	kitPass("kit_explorer"),
	kitPass("kit_survivor"),
	kitPass("kit_veteran"),
	{ id = "vip", nameKey = "shop.pass.vip", descKey = "shop.pass.vip.desc", robux = 149 },
} :: { Pass }

return MockStore
