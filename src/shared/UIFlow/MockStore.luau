--!strict
-- Dados falsos do mockup de loja, cosméticos, ranking e perfil (G7a).
-- Tudo que é número ou nome inventado fica aqui, num lugar só, para apagar
-- quando a loja de verdade existir. Nada daqui compra, grava ou sorteia de
-- verdade: `roll` só escolhe qual prêmio a animação do spin vai mostrar.
local MockStore = {}

export type Pack = { amount: number, robux: number, tag: string? }
export type Odd = { nameKey: string, chance: number }
export type Spin = { id: string, nameKey: string, price: number, kind: string, odds: { Odd } }
export type Offer = { hours: number, price: number }
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

-- Chances iguais para os três níveis do mesmo tipo; soma 1 por spin.
local function odds(): { Odd }
	return {
		{ nameKey = "mock.prize.common", chance = 0.6 },
		{ nameKey = "mock.prize.rare", chance = 0.25 },
		{ nameKey = "mock.prize.epic", chance = 0.12 },
		{ nameKey = "mock.prize.legendary", chance = 0.03 },
	}
end

MockStore.SPINS = {
	{ id = "skin_starter", nameKey = "mock.spin.skin.starter", price = 100, kind = "skin", odds = odds() },
	{ id = "skin_golden", nameKey = "mock.spin.skin.golden", price = 300, kind = "skin", odds = odds() },
	{ id = "skin_dragon", nameKey = "mock.spin.skin.dragon", price = 600, kind = "skin", odds = odds() },
	{ id = "custom_starter", nameKey = "mock.spin.custom.starter", price = 50, kind = "custom", odds = odds() },
	{ id = "custom_golden", nameKey = "mock.spin.custom.golden", price = 150, kind = "custom", odds = odds() },
	{ id = "custom_dragon", nameKey = "mock.spin.custom.dragon", price = 300, kind = "custom", odds = odds() },
} :: { Spin }

MockStore.KIT = {
	items = { "mock.kit.book", "mock.kit.backpack" },
	offers = { { hours = 1, price = 300 }, { hours = 24, price = 600 } },
} :: { items: { string }, offers: { Offer } }

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

-- Índice sorteado para r em [0, 1). Se a soma das chances ficar um pouco
-- abaixo de 1, r nas pontas cai no último índice (nunca devolve fora da lista).
function MockStore.roll(oddsList: { Odd }, r: number): number
	local acc = 0
	for i, odd in oddsList do
		acc += odd.chance
		if r < acc then
			return i
		end
	end
	return #oddsList
end

return MockStore
