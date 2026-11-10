--!strict
local ShopData = require("../src/shared/Shop/ShopData")
local PurchaseRules = require("../src/shared/Shop/PurchaseRules")
local Products = require("../src/shared/Shop/Products")

local function product(id: string): Products.Product
	local found = Products.get(id)
	assert(found ~= nil, `produto {id} não existe`)
	return found
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
		ShopData.markPurchased(d, "bundle_brasa")
		assert(d.Passes.vip == true and d.Purchased.bundle_brasa == true, "guardados")
	end,

	["loading restores forever kits and passes of purchased products"] = function()
		local d = ShopData.empty()
		-- Perfil visto em 10/11: compras gravadas, mas a posse com false.
		d.KitsOwned = { kit_veteran = false, kit_starter = false }
		d.Purchased = { kit_kit_veteran = true, bundle_musgo = true, pass_vip = true }
		ShopData.restoreOwned(d, Products.all())
		assert(d.KitsOwned.kit_veteran == true, "kit comprado para sempre volta")
		assert(d.KitsOwned.kit_explorer == true, "kit que veio no pacote volta")
		assert(d.Passes.vip == true, "passe comprado volta")
		assert(d.KitsOwned.kit_starter == nil, "false sem compra some (nada inventado)")
	end,

	["restoring keeps balances and active kit untouched"] = function()
		local d = ShopData.empty()
		ShopData.addKitBalance(d, "kit_survivor", 2)
		ShopData.ownKit(d, "kit_veteran")
		ShopData.setActive(d, "kit_veteran")
		ShopData.restoreOwned(d, Products.all())
		assert(d.KitBalance.kit_survivor == 2 and d.KitActive == "kit_veteran", "nada mais muda")
	end,

	["unknown product is refused"] = function()
		assert(PurchaseRules.check(nil, ShopData.empty(), 0, 0) == "unknown", "produto inexistente")
	end,

	["bundle outside its dates is refused"] = function()
		local brasa = product("bundle_brasa")
		local d = ShopData.empty()
		assert(PurchaseRules.check(brasa, d, (brasa.startsAt :: number) - 1, 0) == "closed", "antes do começo")
		assert(PurchaseRules.check(brasa, d, brasa.endsAt :: number, 0) == "closed", "no fim")
		assert(PurchaseRules.check(brasa, d, brasa.startsAt :: number, 0) == nil, "aberto")
	end,

	["once products cannot be bought twice"] = function()
		local vip = product("pass_vip")
		local d = ShopData.empty()
		ShopData.markPurchased(d, "pass_vip")
		assert(PurchaseRules.check(vip, d, 0, 0) == "bought", "VIP já comprado")
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
		ShopData.setPass(d, "vip")
		assert(PurchaseRules.check(product("pass_vip"), d, 0, 0) == "bought", "já tem o VIP")
	end,

	["bundle is not refused because part of it is owned"] = function()
		local musgo = product("bundle_musgo")
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

	["a bad balance never pays"] = function()
		local spins = product("spins_normal_1")
		assert(PurchaseRules.check(spins, ShopData.empty(), 0, 0 / 0) == "balance", "NaN não paga")
	end,
}
