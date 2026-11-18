--!strict
local ShopData = require("../src/shared/Shop/ShopData")
local PurchaseRules = require("../src/shared/Shop/PurchaseRules")
local Products = require("../src/shared/Shop/Products")

local function product(id: string): Products.Product
	local found = Products.get(id)
	assert(found ~= nil, `produto {id} não existe`)
	return found
end

-- Pacote real com datas de teste (os pacotes da loja podem não ter datas).
local function dated(id: string): Products.Product
	local copy = table.clone(product(id))
	copy.startsAt = 1_000_000
	copy.endsAt = 2_000_000
	return copy
end

return {
	["spins start at zero and cannot go negative"] = function()
		local d = ShopData.empty()
		assert(d.Spins.normal == 0 and d.Spins.paid == 0, "começa sem giros")
		assert(not ShopData.useSpin(d, "normal"), "sem giro não gasta")
		assert(d.Spins.normal == 0, "continua 0")
		ShopData.addSpins(d, "paid", 3)
		assert(ShopData.useSpin(d, "paid") and d.Spins.paid == 2, "gasta um especial")
	end,

	["kit balance stacks and is spent one by one"] = function()
		local d = ShopData.empty()
		ShopData.addKitBalance(d, "kit_explorer", 1)
		ShopData.addKitBalance(d, "kit_explorer", 2)
		assert(d.KitBalance.kit_explorer == 3, "acumula")
		assert(ShopData.useKitBalance(d, "kit_explorer") and d.KitBalance.kit_explorer == 2, "gasta 1")
		ShopData.useKitBalance(d, "kit_explorer")
		ShopData.useKitBalance(d, "kit_explorer")
		assert(d.KitBalance.kit_explorer == nil, "zerado some da lista")
		assert(not ShopData.useKitBalance(d, "kit_explorer"), "sem saldo não gasta")
	end,

	["only an owned kit can be active"] = function()
		local d = ShopData.empty()
		assert(not ShopData.setActive(d, "kit_veteran"), "não possuído não ativa")
		assert(d.KitActive == "", "nenhum ativo")
		ShopData.ownKit(d, "kit_veteran")
		assert(ShopData.setActive(d, "kit_veteran") and d.KitActive == "kit_veteran", "ativa o possuído")
		assert(ShopData.setActive(d, nil) and d.KitActive == "", "nil desativa")
	end,

	["passes and purchases are remembered"] = function()
		local d = ShopData.empty()
		ShopData.setPass(d, "vip")
		ShopData.markPurchased(d, "bundle_mar")
		assert(d.Passes.vip == true and d.Purchased.bundle_mar == true, "guardados")
	end,

	["cleaning drops false marks and never grants from purchases"] = function()
		local d = ShopData.empty()
		-- A posse do perfil é a verdade: tirada à mão (false), não volta pela compra.
		d.KitsOwned = { kit_veteran = false, kit_starter = true }
		d.Purchased = { kit_kit_veteran = true, bundle_floresta = true }
		d.Passes = { vip = false }
		ShopData.clean(d)
		assert(d.KitsOwned.kit_veteran == nil, "false some")
		assert(d.KitsOwned.kit_starter == true, "true fica")
		assert(d.KitsOwned.kit_explorer == nil, "o pacote comprado não devolve o kit")
		assert(d.Passes.vip == nil, "passe tirado não volta")
	end,

	["a forever kit taken away can be bought again"] = function()
		local d = ShopData.empty()
		ShopData.markPurchased(d, "kit_kit_veteran") -- comprou um dia...
		assert(PurchaseRules.check(product("kit_kit_veteran"), d, 0, 0) == nil, "...mas não tem mais: pode comprar")
	end,

	["unknown product is refused"] = function()
		assert(PurchaseRules.check(nil, ShopData.empty(), 0, 0) == "unknown", "produto inexistente")
	end,

	["bundle outside its dates is refused"] = function()
		local brasa = dated("bundle_mar")
		local d = ShopData.empty()
		assert(PurchaseRules.check(brasa, d, (brasa.startsAt :: number) - 1, 0) == "closed", "antes do começo")
		assert(PurchaseRules.check(brasa, d, brasa.endsAt :: number, 0) == "closed", "no fim")
		assert(PurchaseRules.check(brasa, d, brasa.startsAt :: number, 0) == nil, "aberto")
	end,

	["once products cannot be bought twice"] = function()
		local brasa = dated("bundle_mar")
		local d = ShopData.empty()
		ShopData.markPurchased(d, "bundle_mar")
		assert(PurchaseRules.check(brasa, d, brasa.startsAt :: number, 0) == "bought", "pacote já comprado")
		local once = product("kitonce_kit_explorer")
		ShopData.markPurchased(d, "kitonce_kit_explorer")
		assert(PurchaseRules.check(once, d, 0, 0) == nil, "1 vida compra quantas vezes quiser")
	end,

	["forever kit already owned by another path is refused"] = function()
		local d = ShopData.empty()
		ShopData.ownKit(d, "kit_explorer") -- veio de um pacote, por exemplo
		assert(PurchaseRules.check(product("kit_kit_explorer"), d, 0, 0) == "bought", "já tem o kit para sempre")
		assert(PurchaseRules.check(product("kit_kit_veteran"), d, 0, 0) == nil, "outro kit continua comprável")
	end,

	["pass already owned by another path is refused"] = function()
		local d = ShopData.empty()
		ShopData.setPass(d, "ember2x")
		assert(PurchaseRules.check(product("pass_ember2x"), d, 0, 0) == "bought", "já tem o 2×")
	end,

	["bundle is not refused because part of it is owned"] = function()
		local musgo = dated("bundle_floresta")
		local d = ShopData.empty()
		ShopData.ownKit(d, "kit_explorer")
		assert(PurchaseRules.check(musgo, d, musgo.startsAt :: number, 0) == nil, "o resto do pacote ainda entra")
	end,

	["ember price needs enough balance"] = function()
		local spins = product("spins_normal_3")
		local d = ShopData.empty()
		assert(PurchaseRules.check(spins, d, 0, 279) == "balance", "falta 1")
		assert(PurchaseRules.check(spins, d, 0, 280) == nil, "saldo exato paga")
	end,

	["robux price is free for now"] = function()
		assert(PurchaseRules.check(product("spins_paid_10"), ShopData.empty(), 0, 0) == nil, "Robux não é cobrado")
	end,

	["restricted blocks spin packs of both kinds"] = function()
		local d = ShopData.empty()
		assert(PurchaseRules.check(product("spins_normal_1"), d, 0, 1000, true) == "restricted", "normal")
		assert(PurchaseRules.check(product("spins_paid_1"), d, 0, 0, true) == "restricted", "especial")
		assert(Products.hasRandom(product("spins_paid_1")), "hasRandom spins")
	end,

	["restricted blocks bundles with spins only"] = function()
		local withSpins, withoutSpins = nil, nil
		for _, p in Products.all() do
			if p.kind == "bundle" then
				if Products.hasRandom(p) then
					withSpins = withSpins or p
				else
					withoutSpins = withoutSpins or p
				end
			end
		end
		assert(withSpins ~= nil, "há pacote com giros")
		local at = withSpins.startsAt :: number
		assert(PurchaseRules.check(withSpins, ShopData.empty(), at, 0, true) == "restricted", "com giros")
		assert(PurchaseRules.check(withSpins, ShopData.empty(), at, 0, false) == nil, "liberado compra")
		if withoutSpins ~= nil then
			assert(
				PurchaseRules.check(withoutSpins, ShopData.empty(), withoutSpins.startsAt :: number, 0, true) == nil,
				"sem giros passa"
			)
		end
		assert(PurchaseRules.check(product("pack_300"), ShopData.empty(), 0, 0, true) == nil, "outros passam")
	end,

	["unrestricted buys normally"] = function()
		local d = ShopData.empty()
		assert(PurchaseRules.check(product("spins_paid_1"), d, 0, 0, false) == nil, "false")
		assert(PurchaseRules.check(product("spins_paid_1"), d, 0, 0, nil) == nil, "nil")
	end,

	["a bad balance never pays"] = function()
		local spins = product("spins_normal_1")
		assert(PurchaseRules.check(spins, ShopData.empty(), 0, 0 / 0) == "balance", "NaN não paga")
	end,

	["vip days stack from the later of now and VipUntil"] = function()
		local d = ShopData.empty()
		ShopData.addVipDays(d, 30, 1000)
		assert(d.VipUntil == 1000 + 30 * 86400, `veio {d.VipUntil}`)
		ShopData.addVipDays(d, 30, 2000)
		assert(d.VipUntil == 1000 + 60 * 86400, `veio {d.VipUntil}`)
	end,

	["boost restarts after expiring"] = function()
		local d = ShopData.empty()
		ShopData.addBoost(d, 3600, 0)
		assert(d.BoostStart == 0 and d.BoostUntil == 3600, `{d.BoostStart}/{d.BoostUntil}`)
		ShopData.addBoost(d, 3600, 5000)
		assert(d.BoostStart == 5000 and d.BoostUntil == 8600, `{d.BoostStart}/{d.BoostUntil}`)
		ShopData.addBoost(d, 3600, 8000)
		assert(d.BoostStart == 5000 and d.BoostUntil == 12200, `{d.BoostStart}/{d.BoostUntil}`)
	end,

	["new profile fields start empty"] = function()
		local d = ShopData.empty()
		assert(d.VipUntil == 0 and d.BoostStart == 0 and d.BoostUntil == 0 and d.ReviveCredits == 0, "zeros")
		assert(d.CheckIn.Day == 1 and d.CheckIn.LastDay == 0, "check-in")
	end,

	["hidden product is unknown for the shop"] = function()
		assert(PurchaseRules.check(product("revive_1"), ShopData.empty(), 0, 0) == "unknown", "revive escondido")
	end,

	["rememberGift ignores a repeated purchase id"] = function()
		local d = ShopData.empty()
		assert(ShopData.rememberGift(d, "p1"), "primeira vez")
		assert(not ShopData.rememberGift(d, "p1"), "repetido")
	end,

	["rememberGift keeps 100"] = function()
		local d = ShopData.empty()
		for i = 1, 101 do
			ShopData.rememberGift(d, `p{i}`)
		end
		assert(#d.GiftIds == 100, `guardou {#d.GiftIds}`)
		assert(table.find(d.GiftIds, "p1") == nil and d.GiftIds[100] == "p101", "o mais velho saiu")
	end,

	["setGiftPending replaces the previous recipient"] = function()
		local d = ShopData.empty()
		ShopData.setGiftPending(d, "pack_300", 1, "Um")
		ShopData.setGiftPending(d, "pack_300", 2, "Dois")
		local pending = ShopData.takeGiftPending(d, "pack_300")
		assert(pending ~= nil and pending.to == 2 and pending.name == "Dois", "o último vence")
		assert(ShopData.takeGiftPending(d, "pack_300") == nil, "lido e apagado")
	end,

	["inbox is first in first out"] = function()
		local d = ShopData.empty()
		ShopData.pushInbox(d, "Ana", "pack_300")
		ShopData.pushInbox(d, "Bia", "pass_book")
		local first = ShopData.popInbox(d)
		assert(first ~= nil and first.from == "Ana" and first.productId == "pack_300", "primeiro")
		local second = ShopData.popInbox(d)
		assert(second ~= nil and second.from == "Bia", "segundo")
		assert(ShopData.popInbox(d) == nil, "vazia")
	end,

	["clearGiftPending keeps a newer recipient"] = function()
		local d = ShopData.empty()
		ShopData.setGiftPending(d, "pack_300", 1, "Um")
		local first = d.GiftPending.pack_300
		ShopData.setGiftPending(d, "pack_300", 2, "Dois") -- outra janela no meio do recibo
		ShopData.clearGiftPending(d, "pack_300", first :: any)
		local kept = d.GiftPending.pack_300
		assert(kept ~= nil and kept.to == 2, "o pendente novo continua")
		ShopData.clearGiftPending(d, "pack_300", kept :: any)
		assert(d.GiftPending.pack_300 == nil, "o mesmo pendente sai")
	end,
}
