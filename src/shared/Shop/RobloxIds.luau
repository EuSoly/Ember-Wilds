--!strict
-- Ids no Roblox de cada produto da loja (Shop/Products), criados em 18/11/2026
-- no universo 10773601314 (conta do Elizeu). Criados FORA DE VENDA pela API;
-- a venda é ligada no Creator Hub (Monetização do Ember Wilds) ou por
-- PATCH isForSale. Item fora de venda não abre a janela de compra.
--
-- GAME_PASS: compra única para sempre (kits para sempre e passes).
-- PRODUCT: produto de desenvolvedor (pacotes, giros especiais, kit de 1 vida,
--   boost de XP, revive, pacotes em destaque).
-- SUBSCRIPTION: assinatura (o VIP; criada à mão no Creator Hub).
-- Quem cobra e entrega é o RobuxService (servidor).
--
-- Produto NOVO na loja (pacote em destaque novo, preço novo de pacote...)
-- precisa de um id aqui; o teste tests/robloxids.spec.luau avisa o que falta.
-- Preço mudou: mudar também no Creator Hub (o preço cobrado é o de lá).
local RobloxIds = {}

RobloxIds.GAME_PASS = table.freeze({
	pass_ember2x = 2092959107,
	pass_book = 2094315136,
	kit_kit_starter = 2093985027,
	kit_kit_explorer = 2094213086,
	kit_kit_survivor = 2092281104,
	kit_kit_veteran = 2093649105,
}) :: { [string]: number }

RobloxIds.PRODUCT = table.freeze({
	pack_300 = 3733055559,
	pack_600 = 3733055564,
	pack_2600 = 3733055571,
	pack_7000 = 3733055598,
	pack_20000 = 3733055613,
	spins_paid_1 = 3733055619,
	spins_paid_3 = 3733055643,
	spins_paid_10 = 3733055650,
	kitonce_kit_starter = 3733055656,
	kitonce_kit_explorer = 3733055682,
	kitonce_kit_survivor = 3733055690,
	kitonce_kit_veteran = 3733055692,
	xpboost_1h = 3733055728,
	revive_1 = 3733055736,
	revive_2 = 3733055742,
	revive_3 = 3733055777,
	revive_4 = 3733055785,
	bundle_mar = 3733055794,
	bundle_gelo = 3733055822,
	bundle_floresta = 3733055827,
}) :: { [string]: number }

-- Produtos de presente ("Presente: X"): mesmo id da loja, comprado por um
-- jogador para outro (GiftService). VIP e revive não têm.
RobloxIds.GIFT = table.freeze({
	kit_kit_starter = 3733075488,
	kit_kit_explorer = 3733075532,
	kit_kit_survivor = 3733075544,
	kit_kit_veteran = 3733075557,
	pass_ember2x = 3733075612,
	pass_book = 3733075624,
	pack_300 = 3733075636,
	pack_600 = 3733075645,
	pack_2600 = 3733075695,
	pack_7000 = 3733075707,
	pack_20000 = 3733075716,
	spins_paid_1 = 3733075721,
	spins_paid_3 = 3733075779,
	spins_paid_10 = 3733075789,
	kitonce_kit_starter = 3733075801,
	kitonce_kit_explorer = 3733075811,
	kitonce_kit_survivor = 3733075868,
	kitonce_kit_veteran = 3733075878,
	xpboost_1h = 3733075886,
	bundle_mar = 3733075894,
	bundle_gelo = 3733075924,
	bundle_floresta = 3733075933,
}) :: { [string]: number }

RobloxIds.SUBSCRIPTION = table.freeze({
	vip_30d = "EXP-7043584435712819724",
}) :: { [string]: string }

export type Home = "pass" | "product" | "subscription"

-- Onde um produto da loja (Shop/Products, pelo `kind`) vive no Roblox.
function RobloxIds.homeOf(kind: string): Home
	if kind == "kit" or kind == "pass" then
		return "pass"
	elseif kind == "vip" then
		return "subscription"
	end
	return "product"
end

local productById: { [number]: string } = {}
for productId, id in RobloxIds.PRODUCT do
	productById[id] = productId
end
local giftById: { [number]: string } = {}
for productId, id in RobloxIds.GIFT do
	giftById[id] = productId
end
local passById: { [number]: string } = {}
for productId, id in RobloxIds.GAME_PASS do
	passById[id] = productId
end
local subscriptionById: { [string]: string } = {}
for productId, id in RobloxIds.SUBSCRIPTION do
	subscriptionById[id] = productId
end

-- Id da loja de um produto de desenvolvedor do Roblox (nil = não é nosso) e
-- se é o produto de presente dele.
function RobloxIds.fromProduct(robloxId: number): (string?, boolean)
	local gift = giftById[robloxId]
	if gift ~= nil then
		return gift, true
	end
	return productById[robloxId], false
end

-- Id da loja de uma gamepass do Roblox.
function RobloxIds.fromGamePass(robloxId: number): string?
	return passById[robloxId]
end

-- Id da loja de uma assinatura do Roblox.
function RobloxIds.fromSubscription(robloxId: string): string?
	return subscriptionById[robloxId]
end

return table.freeze(RobloxIds)
