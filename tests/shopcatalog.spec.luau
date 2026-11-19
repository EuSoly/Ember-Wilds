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
		nameKey = "shop.bundle.mar",
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
		assert(rewardError({ kind = "pass", id = "ember2x" }) == nil, "pass")
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
		local vip = Products.get("pass_ember2x")
		assert(vip ~= nil and vip.once and vip.price.currency == "robux", "2× é Robux e uma vez")
		assert(Products.get("nada") == nil, "produto inexistente")
	end,

	["bundles are bought once and listed while open"] = function()
		for _, id in { "bundle_mar", "bundle_gelo", "bundle_floresta" } do
			local found = Products.get(id)
			assert(found ~= nil and found.once and found.kind == "bundle", `{id}: compra uma vez`)
		end
		-- Sem datas: aberto sempre. Com datas, Products.bundles segue o ShopDates.isOpen.
		for _, product in Products.all() do
			if product.kind == "bundle" then
				local listed = false
				local now = product.startsAt or 0
				for _, open in Products.bundles(now) do
					listed = listed or open.id == product.id
				end
				assert(listed, `{product.id}: listado no começo`)
				if product.endsAt then
					for _, open in Products.bundles(product.endsAt) do
						assert(open.id ~= product.id, `{product.id}: fechado no fim`)
					end
				end
			end
		end
	end,

	["each featured bundle grants four different cosmetic slots at the configured price"] = function()
		for id, price in { bundle_mar = 499, bundle_floresta = 399, bundle_gelo = 299 } do
			local p = assert(Products.get(id))
			assert(p.price.amount == price and #p.rewards == 4, `{id}: preço e 4 peças`)
			local slots = {}
			for _, reward in p.rewards do
				assert(reward.kind == "cosmetic", `{id}: só cosméticos`)
				local slot = Defs.Cosmetics[reward.id :: string].slot
				assert(not slots[slot], `{id}: slot repetido {slot}`)
				slots[slot] = true
			end
		end
	end,

	["kit robux prices"] = function()
		local expected = {
			kit_starter = { 15, 99 },
			kit_explorer = { 25, 199 },
			kit_survivor = { 49, 299 },
			kit_veteran = { 67, 399 },
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
		assert(ShopConfig.VIP.robux == 99 and ShopConfig.VIP.days == 30, "VIP de 99 por 30 dias")
	end,

	["spin odds and refunds"] = function()
		assert(table.concat(ShopConfig.SPIN_ODDS.normal, ",") == "30,30,22,13,4,1", "chances do normal")
		assert(table.concat(ShopConfig.SPIN_ODDS.paid, ",") == "4,11,20,35,25,5", "chances do especial")
		assert(ShopConfig.DUPLICATE_REFUND.normal == 50 and ShopConfig.DUPLICATE_REFUND.paid == 150, "devolução")
	end,

	["bundle dates use ShopDates"] = function()
		for _, product in Products.all() do
			if product.kind == "bundle" then
				local def = Products.bundleDef(string.sub(product.id, #"bundle_" + 1))
				assert(def ~= nil, `{product.id}: sem pacote`)
				local expected = if def.startsAt then ShopDates.parse(def.startsAt) else nil
				assert(product.startsAt == expected, `{product.id}: início convertido`)
			end
		end
	end,

	["vip pass is gone, ember2x and book exist"] = function()
		assert(Products.get("pass_vip") == nil, "pass_vip ainda existe")
		local ember2x = Products.get("pass_ember2x")
		local book = Products.get("pass_book")
		assert(ember2x ~= nil and ember2x.price.amount == 199, "pass_ember2x de 199")
		assert(book ~= nil and book.price.amount == 99, "pass_book de 99")
	end,

	["vip and boost products"] = function()
		local vip = Products.get("vip_30d")
		assert(vip ~= nil and vip.price.amount == 99 and vip.once == false, "vip_30d")
		assert(vip.rewards[1].kind == "vip" and vip.rewards[1].count == 30, "30 dias")
		local boost = Products.get("xpboost_1h")
		assert(boost ~= nil and boost.price.amount == 49, "xpboost_1h")
		assert(boost.rewards[1].kind == "xpBoost" and boost.rewards[1].count == 3600, "1 hora")
	end,

	["revive products are hidden and priced by step"] = function()
		local prices = { 25, 49, 99, 199 }
		for step, robux in prices do
			local product = Products.get(`revive_{step}`)
			assert(product ~= nil and product.hidden == true, `revive_{step} escondido`)
			assert(product.price.amount == robux, `revive_{step}: {product.price.amount}`)
		end
		assert(Products.get("revive_3").hidden == true, "revive_3")
	end,

	["checkin rewards are valid"] = function()
		assert(#ShopConfig.CHECKIN == 7, "7 dias")
		for day, reward in ShopConfig.CHECKIN do
			local message = rewardError(reward)
			assert(message == nil, `dia {day}: {message}`)
		end
	end,

	["new reward kinds validate counts"] = function()
		for _, kind in { "vip", "xpBoost", "reviveCredit" } do
			assert(rewardError({ kind = kind, count = 1 }) == nil, `{kind} válido`)
			assert(rewardError({ kind = kind }) ~= nil, `{kind} sem count`)
			assert(rewardError({ kind = kind, count = 0 }) ~= nil, `{kind} count 0`)
		end
	end,

	["perk bonus config"] = function()
		assert(ShopConfig.PERK_BONUS.ember2x == 1 and ShopConfig.PERK_BONUS.vip == 0.5, "bônus")
		assert(ShopConfig.PERK_BONUS.premium == 0.2, "premium")
	end,
}
