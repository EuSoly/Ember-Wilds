--!strict
local Defs = require("../src/shared/Defs")
local Strings = require("../src/shared/Strings")
local Rewards = require("../src/shared/Shop/Rewards")
local Products = require("../src/shared/Shop/Products")
local ShopConfig = require("../src/shared/Shop/ShopConfig")
local ShopDates = require("../src/shared/Shop/ShopDates")

-- Erro esperado de uma recompensa (nil = válida).
local function rewardError(reward: Rewards.Reward): string?
	return Rewards.validate(reward, Defs)
end

local function hasError(errors: { string }, fragment: string): boolean
	for _, message in errors do
		if string.find(message, fragment, 1, true) then
			return true
		end
	end
	return false
end

-- Pacote mínimo válido para os testes de validação (copiado e alterado).
local function bundle(changes: { [string]: any }): Products.BundleDef
	local base: { [string]: any } = {
		id = "teste",
		nameKey = "shop.bundle.brasa",
		theme = "#B8361A",
		rarity = 3,
		robux = 99,
		startsAt = "2026-11-09 00:00",
		endsAt = "2026-11-12 00:00",
		rewards = { { kind = "ember", amount = 100 } },
	}
	for key, value in changes do
		base[key] = value
	end
	return base :: any
end

return {
	["real catalog has no errors"] = function()
		local errors = Products.validate(Defs, Strings)
		assert(#errors == 0, table.concat(errors, "\n"))
	end,

	["every reward kind accepts a valid reward"] = function()
		assert(rewardError({ kind = "cosmetic", id = "body_lobo" }) == nil, "cosmetic")
		assert(rewardError({ kind = "ember", amount = 500 }) == nil, "ember")
		assert(rewardError({ kind = "spins", spin = "paid", count = 2 }) == nil, "spins")
		assert(rewardError({ kind = "kit", id = "kit_explorer" }) == nil, "kit")
		assert(rewardError({ kind = "kitOnce", id = "kit_explorer", count = 1 }) == nil, "kitOnce")
		assert(rewardError({ kind = "pass", id = "vip" }) == nil, "pass")
	end,

	["invalid rewards are refused with the field name"] = function()
		local cases: { { reward: Rewards.Reward, field: string } } = {
			{ reward = { kind = "cosmetic", id = "body_nada" }, field = "id" },
			{ reward = { kind = "kit", id = "kit_nada" }, field = "id" },
			{ reward = { kind = "ember", amount = 0 }, field = "amount" },
			{ reward = { kind = "ember", amount = 1.5 }, field = "amount" },
			{ reward = { kind = "spins", spin = "x" :: any, count = 1 }, field = "spin" },
			{ reward = { kind = "spins", spin = "normal", count = 0 }, field = "count" },
			{ reward = { kind = "kitOnce", id = "kit_explorer" }, field = "count" },
			{ reward = { kind = "pass", id = "ouro" }, field = "id" },
			{ reward = { kind = "pet", id = "gato" }, field = "kind" },
		}
		for _, case in cases do
			local message = rewardError(case.reward)
			assert(message ~= nil, `deveria recusar {case.reward.kind}`)
			assert(string.find(message, case.field, 1, true), `{case.reward.kind}: "{message}" sem "{case.field}"`)
		end
	end,

	["bundle with end before start is refused"] = function()
		local errors = Products.validateBundles({ bundle({ endsAt = "2026-11-08 00:00" }) }, Defs, Strings)
		assert(hasError(errors, "endsAt"), table.concat(errors, "\n"))
	end,

	["bundle with a badly written date is refused"] = function()
		local errors = Products.validateBundles({ bundle({ startsAt = "09/11/2026" }) }, Defs, Strings)
		assert(hasError(errors, "startsAt"), table.concat(errors, "\n"))
	end,

	["bundle ids must be unique"] = function()
		local errors = Products.validateBundles({ bundle({}), bundle({}) }, Defs, Strings)
		assert(hasError(errors, "repetido"), table.concat(errors, "\n"))
	end,

	["bundle name must have a text"] = function()
		local errors = Products.validateBundles({ bundle({ nameKey = "shop.bundle.nada" }) }, Defs, Strings)
		assert(hasError(errors, "nameKey"), table.concat(errors, "\n"))
	end,

	["bundle with a bad reward is refused"] = function()
		local errors =
			Products.validateBundles({ bundle({ rewards = { { kind = "cosmetic", id = "x" } } }) }, Defs, Strings)
		assert(hasError(errors, "teste"), table.concat(errors, "\n"))
	end,

	["kit products: forever and one life"] = function()
		local forever = Products.get("kit_kit_explorer")
		assert(forever ~= nil and forever.kind == "kit", "kit para sempre existe")
		assert(forever.rewards[1].kind == "kit" and forever.rewards[1].id == "kit_explorer", "entrega o kit")
		assert(forever.once, "para sempre compra uma vez")
		assert(
			forever.price.currency == "robux" and forever.price.amount == ShopConfig.KIT_ROBUX.kit_explorer.forever,
			"preço do kit para sempre"
		)
		local once = Products.get("kitonce_kit_explorer")
		assert(once ~= nil and not once.once, "1 vida compra quantas quiser")
		assert(once.rewards[1].kind == "kitOnce" and once.rewards[1].count == 1, "1 vida soma 1 no saldo")
	end,

	["spin, pack and pass products"] = function()
		local spins = Products.get("spins_normal_3")
		assert(spins ~= nil and spins.price.currency == "ember" and spins.price.amount == 280, "3 giros = 280")
		assert(spins.rewards[1].spin == "normal" and spins.rewards[1].count == 3, "entrega 3 giros normais")
		local paid = Products.get("spins_paid_10")
		assert(paid ~= nil and paid.price.currency == "robux" and paid.rewards[1].count == 10, "10 especiais")
		local pack = Products.get("pack_2600")
		assert(pack ~= nil and pack.rewards[1].kind == "ember" and pack.rewards[1].amount == 2600, "pacote de moeda")
		local vip = Products.get("pass_vip")
		assert(vip ~= nil and vip.once and vip.price.currency == "robux", "VIP é Robux e uma vez")
		assert(Products.get("nada") == nil, "produto inexistente")
	end,

	["bundles are bought once and only listed while open"] = function()
		local brasa = Products.get("bundle_brasa")
		assert(brasa ~= nil and brasa.once and brasa.kind == "bundle", "pacote compra uma vez")
		assert(brasa.endsAt ~= nil, "pacote de exemplo tem fim")
		local listedNow = false
		for _, product in Products.bundles(brasa.endsAt - 1) do
			listedNow = listedNow or product.id == "bundle_brasa"
		end
		assert(listedNow, "aberto um segundo antes do fim")
		for _, product in Products.bundles(brasa.endsAt) do
			assert(product.id ~= "bundle_brasa", "fechado no fim")
		end
	end,

	["example bundles mix reward kinds"] = function()
		local kinds = {}
		for _, product in Products.all() do
			if product.kind == "bundle" then
				for _, reward in product.rewards do
					kinds[reward.kind] = true
				end
			end
		end
		for _, kind in { "cosmetic", "ember", "spins", "kit" } do
			assert(kinds[kind], `nenhum pacote de exemplo tem {kind}`)
		end
	end,

	["kit robux prices"] = function()
		local expected = {
			kit_starter = { 15, 99 },
			kit_explorer = { 25, 199 },
			kit_survivor = { 49, 399 },
			kit_veteran = { 99, 799 },
		}
		for id, prices in expected do
			local entry = ShopConfig.KIT_ROBUX[id]
			assert(entry ~= nil, `{id} sem preço em Robux`)
			assert(entry.once == prices[1] and entry.forever == prices[2], `{id}: {entry.once}/{entry.forever}`)
		end
	end,

	["ember packs and the VIP price"] = function()
		local expected = { { 300, 80 }, { 600, 150 }, { 2600, 600 }, { 7000, 1500 }, { 20000, 3500 } }
		assert(#ShopConfig.EMBER_PACKS == 5, `veio {#ShopConfig.EMBER_PACKS}`)
		for i, pack in ShopConfig.EMBER_PACKS do
			assert(pack.amount == expected[i][1] and pack.robux == expected[i][2], `pacote {i}`)
		end
		assert(ShopConfig.PASSES.vip.robux == 149, "VIP de 149")
	end,

	["spin odds and refunds"] = function()
		assert(table.concat(ShopConfig.SPIN_ODDS.normal, ",") == "30,40,23,6,1", "chances do normal")
		assert(table.concat(ShopConfig.SPIN_ODDS.paid, ",") == "5,25,40,25,5", "chances do especial")
		assert(ShopConfig.DUPLICATE_REFUND.normal == 50 and ShopConfig.DUPLICATE_REFUND.paid == 150, "devolução")
	end,

	["bundle dates use ShopDates"] = function()
		local brasa = Products.get("bundle_brasa")
		local def = Products.bundleDef("brasa")
		assert(brasa ~= nil and def ~= nil and def.startsAt ~= nil, "pacote de exemplo")
		assert(brasa.startsAt == ShopDates.parse(def.startsAt :: string), "início convertido")
	end,
}
