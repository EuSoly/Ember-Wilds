--!strict
-- Números da loja num lugar só: preços, chances dos giros e devolução de skin
-- repetida. Preço em Robux ainda NÃO é cobrado (ShopService.charge entrega de
-- graça); os valores ficam aqui para quando a cobrança real for ligada.
local ShopTypes = require("./Types")

local ShopConfig = {}

export type SpinKind = ShopTypes.SpinKind -- "paid" = giro especial

-- Chances (%) por raridade, da Comum à Mítica (tabela do Elizeu).
ShopConfig.SPIN_ODDS = table.freeze({
	normal = table.freeze({ 30, 40, 23, 6, 1 }), -- giro normal (Golden Ember)
	paid = table.freeze({ 5, 25, 40, 25, 5 }), -- giro especial (Robux)
})

-- Skin que o jogador já tem: devolve esta Golden Ember no lugar.
ShopConfig.DUPLICATE_REFUND = table.freeze({ normal = 50, paid = 150 })

export type SpinPack = { qty: number, price: number }
-- Pacotes de giros: o normal custa Golden Ember; o especial, Robux.
ShopConfig.SPIN_PACKS = table.freeze({
	normal = table.freeze({ { qty = 1, price = 100 }, { qty = 3, price = 280 }, { qty = 10, price = 850 } }),
	paid = table.freeze({ { qty = 1, price = 49 }, { qty = 3, price = 129 }, { qty = 10, price = 399 } }),
}) :: { normal: { SpinPack }, paid: { SpinPack } }

export type EmberPack = { amount: number, robux: number, tag: string? }
-- Pacotes de Golden Ember (quantidade ↔ preço em Robux).
ShopConfig.EMBER_PACKS = table.freeze({
	{ amount = 300, robux = 80 },
	{ amount = 600, robux = 150 },
	{ amount = 2600, robux = 600, tag = "popular" },
	{ amount = 7000, robux = 1500, tag = "off30" },
	{ amount = 20000, robux = 3500, tag = "best" },
}) :: { EmberPack }

export type KitRobux = { once: number, forever: number }
-- Kits com Robux: preço de 1 vida (soma 1 no saldo do kit) e para sempre.
-- Todo kit de Defs.Kits precisa de uma entrada (a validação avisa).
ShopConfig.KIT_ROBUX = table.freeze({
	kit_starter = { once = 15, forever = 99 },
	kit_explorer = { once = 25, forever = 199 },
	kit_survivor = { once = 49, forever = 299 },
	kit_veteran = { once = 67, forever = 399 },
}) :: { [string]: KitRobux }

export type PassDef = { nameKey: string, descKey: string, robux: number }
-- Passes (vantagens para sempre). O efeito de cada um fica no servidor
-- (ember2x: +1 no multiplicador de Golden Ember; book: nasce com o livro).
ShopConfig.PASSES = table.freeze({
	ember2x = { nameKey = "shop.pass.ember2x", descKey = "shop.pass.ember2x.desc", robux = 199 },
	book = { nameKey = "shop.pass.book", descKey = "shop.pass.book.desc", robux = 99 },
}) :: { [string]: PassDef }

-- VIP por tempo (não é gamepass): Robux por `days` dias.
ShopConfig.VIP = table.freeze({ robux = 99, days = 30 })

-- Bônus somados no multiplicador de Golden Ember (base 1): 1 + 1 + 0,5 + 0,2 = 2,7.
ShopConfig.PERK_BONUS = table.freeze({ ember2x = 1, vip = 0.5, premium = 0.2 })

-- Preço de cada degrau do revive (para no último).
ShopConfig.REVIVE_ROBUX = table.freeze({ 25, 49, 99, 199 })

-- Boost de XP: cada compra soma `seconds`.
ShopConfig.XP_BOOST = table.freeze({ robux = 49, seconds = 3600 })

-- Prêmios do check-in diário (dia 1..7; depois do 7 volta ao 1).
local checkin: { ShopTypes.Reward } = {
	{ kind = "ember", amount = 100 },
	{ kind = "spins", spin = "normal", count = 1 },
	{ kind = "ember", amount = 150 },
	{ kind = "kitOnce", id = "kit_explorer", count = 1 },
	{ kind = "ember", amount = 200 },
	{ kind = "spins", spin = "normal", count = 2 },
	{ kind = "spins", spin = "paid", count = 5 },
}
for _, reward in checkin do
	table.freeze(reward)
end
ShopConfig.CHECKIN = table.freeze(checkin)

return ShopConfig
