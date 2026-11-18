--!strict
-- Ids no Roblox de cada produto da loja (Shop/Products), criados em 18/11/2026
-- no universo 10773601314 (conta do Elizeu). TODOS FORA DE VENDA até ligar a
-- cobrança (fase 9): pôr à venda = PATCH isForSale nas APIs de game-passes e
-- developer-products (veja docs/guia/loja.md, "Ligar o Robux de verdade").
--
-- GAME_PASS: compra única para sempre (kits para sempre e passes).
-- PRODUCT: produto de desenvolvedor (pacotes, giros especiais, kit de 1 vida,
--   boost de XP, revive, pacotes em destaque).
-- SUBSCRIPTION: assinatura (o VIP; criada à mão no Creator Hub).
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

RobloxIds.SUBSCRIPTION = table.freeze({
	vip_30d = "EXP-7043584435712819724",
}) :: { [string]: string }

return table.freeze(RobloxIds)
