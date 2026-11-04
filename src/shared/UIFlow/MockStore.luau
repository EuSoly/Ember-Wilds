--!strict
-- Dados falsos do mockup de loja, cosméticos, ranking e perfil (G7a e UI 2).
-- Tudo que é número ou nome inventado fica aqui, num lugar só, para apagar
-- quando a loja de verdade existir. Nada daqui compra, grava ou sorteia de
-- verdade: o sorteio da loja (SpinRules) só escolhe o que a animação mostra.
local MockStore = {}

export type Pack = { amount: number, robux: number, tag: string? }
export type CategoryItem = { id: string, nameKey: string }
export type Category = { id: string, nameKey: string, items: { CategoryItem } }
export type RankRow = { name: string, points: number }
export type Stat = { nameKey: string, value: number }

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

MockStore.CATEGORIES = {
	{ id = "skins", nameKey = "mock.cat.skins", items = {} }, -- usa as skins de corpo reais
	{
		id = "accessories",
		nameKey = "mock.cat.accessories",
		items = {
			{ id = "hat_ember", nameKey = "mock.item.hat_ember" },
			{ id = "hat_moss", nameKey = "mock.item.hat_moss" },
			{ id = "scarf_frost", nameKey = "mock.item.scarf_frost" },
			{ id = "goggles_dune", nameKey = "mock.item.goggles_dune" },
		},
	},
	{
		id = "bag",
		nameKey = "mock.cat.bag",
		items = {
			{ id = "bag_leather", nameKey = "mock.item.bag_leather" },
			{ id = "bag_patchwork", nameKey = "mock.item.bag_patchwork" },
			{ id = "bag_ranger", nameKey = "mock.item.bag_ranger" },
		},
	},
	{
		id = "book",
		nameKey = "mock.cat.book",
		items = {
			{ id = "book_cinder", nameKey = "mock.item.book_cinder" },
			{ id = "book_wild", nameKey = "mock.item.book_wild" },
			{ id = "book_night", nameKey = "mock.item.book_night" },
		},
	},
	{
		id = "crate",
		nameKey = "mock.cat.crate",
		items = {
			{ id = "crate_oak", nameKey = "mock.item.crate_oak" },
			{ id = "crate_iron", nameKey = "mock.item.crate_iron" },
			{ id = "crate_ember", nameKey = "mock.item.crate_ember" },
			{ id = "crate_bone", nameKey = "mock.item.crate_bone" },
		},
	},
} :: { Category }

-- Ranking falso, do maior para o menor.
MockStore.RANKING = {
	{ name = "Cinzas", points = 48210 },
	{ name = "LoboSolitario", points = 41377 },
	{ name = "Brasa_77", points = 36902 },
	{ name = "Musgo", points = 30455 },
	{ name = "NoiteLonga", points = 27118 },
	{ name = "Ferrugem", points = 22640 },
	{ name = "ZéDoFogo", points = 19873 },
	{ name = "Geada", points = 15204 },
	{ name = "Pedregulho", points = 11986 },
	{ name = "Fagulha", points = 8421 },
} :: { RankRow }

MockStore.PROFILE = {
	level = 7,
	xp = 340,
	xpMax = 500,
	stats = {
		{ nameKey = "mock.stat.kills", value = 23 },
		{ nameKey = "mock.stat.deaths", value = 41 },
		{ nameKey = "mock.stat.days", value = 96 },
		{ nameKey = "mock.stat.crafted", value = 312 },
	},
} :: { level: number, xp: number, xpMax: number, stats: { Stat } }

-- Chaves dos passos do tutorial, na ordem.
MockStore.TUTORIAL = {
	"mock.tutorial.1",
	"mock.tutorial.2",
	"mock.tutorial.3",
	"mock.tutorial.4",
	"mock.tutorial.5",
} :: { string }

-- ================= Loja (UI 2) =================

-- Raridades = os tiers, de Comum (madeira) a Lendário (reidite): a cor e o
-- nome vêm de Defs.Tiers (pilar "tier é cor" da identidade visual).
MockStore.RARITIES = { "wood", "stone", "gold", "diamond", "amethyst", "reidite" } :: { string }

-- Chances (%) por raridade, na ordem acima. Provisórias.
MockStore.SPIN_ODDS = {
	normal = { 60, 25, 10, 4, 0.9, 0.1 }, -- giro com Golden Ember
	paid = { 30, 25, 20, 15, 7, 3 }, -- giro especial com Robux
}
-- Só para o carrossel ocioso mostrar as raridades misturadas (não é chance).
MockStore.SHOWCASE_WEIGHTS = { 30, 25, 18, 13, 9, 5 } :: { number }

export type SpinItem = { id: string, nameKey: string, rarity: number, color: string }
export type SpinType = { id: string, nameKey: string, theme: string, items: { SpinItem } }

-- Um item de mentirinha por raridade (índice = raridade); `color` pinta o
-- quadradinho do carrossel até existirem os ícones de verdade.
local function spinItems(typeId: string, colors: { string }): { SpinItem }
	local list: { SpinItem } = {}
	for i, color in colors do
		local id = `{typeId}_{i}`
		table.insert(list, { id = id, nameKey = `shop.item.{id}`, rarity = i, color = color })
	end
	return list
end

-- Um tipo de giro por categoria de skin (a caixa de saque e a de morte usam
-- as mesmas skins: um tipo só).
MockStore.SPIN_TYPES = {
	{
		id = "body",
		nameKey = "shop.type.body",
		theme = "#D8452B",
		items = spinItems("body", { "#78834F", "#E8B86D", "#7FC8F0", "#2EC4B6", "#B07CF0", "#E5402B" }),
	},
	{
		id = "accessory",
		nameKey = "shop.type.accessory",
		theme = "#7A4FD8",
		items = spinItems("accessory", { "#78834F", "#7FC8F0", "#E99843", "#E8B86D", "#8B5A2B", "#E5402B" }),
	},
	{
		id = "bag",
		nameKey = "shop.type.bag",
		theme = "#4E9A2E",
		items = spinItems("bag", { "#95603D", "#B87C4B", "#3E8E41", "#7FC8F0", "#3B3F8F", "#E5402B" }),
	},
	{
		id = "book",
		nameKey = "shop.type.book",
		theme = "#2F7FD8",
		items = spinItems("book", { "#5E5E5E", "#78834F", "#2EC4B6", "#3B3F8F", "#9B5DE5", "#E5402B" }),
	},
	{
		id = "crate",
		nameKey = "shop.type.crate",
		theme = "#E97F22",
		items = spinItems("crate", { "#A77B4F", "#8A8F98", "#59402D", "#E8E0D0", "#3FD0E0", "#E5402B" }),
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
		rarity = 6,
		theme = "#B8361A",
		robux = 399,
		endsIn = 2 * DAY + 10 * HOUR + 7 * MINUTE,
		items = bundleItems("brasa"),
	},
	{
		id = "geada",
		nameKey = "shop.bundle.geada",
		rarity = 5,
		theme = "#2F7FD8",
		robux = 349,
		endsIn = 5 * DAY + 2 * HOUR + 40 * MINUTE,
		items = bundleItems("geada"),
	},
	{
		id = "musgo",
		nameKey = "shop.bundle.musgo",
		rarity = 3,
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
