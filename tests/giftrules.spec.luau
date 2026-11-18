--!strict
local GiftRules = require("../src/shared/Shop/GiftRules")
local Products = require("../src/shared/Shop/Products")
local ShopData = require("../src/shared/Shop/ShopData")

local function product(id: string): Products.Product
	local found = Products.get(id)
	assert(found ~= nil, `produto {id} não existe`)
	return found
end

-- Presenteáveis de teste (o RobloxIds.GIFT real é preenchido na criação dos produtos).
local GIFTABLE = {
	pack_300 = true,
	spins_paid_3 = true,
	kit_kit_veteran = true,
	vip_30d = false,
}

return {
	["cannot gift to yourself"] = function()
		GiftRules._setGiftable(GIFTABLE)
		local refusal = GiftRules.check(product("pack_300"), ShopData.empty(), 0, false, false, true)
		GiftRules._setGiftable(nil)
		assert(refusal == "self", `veio {refusal}`)
	end,

	["vip and revive are not giftable"] = function()
		GiftRules._setGiftable(GIFTABLE)
		local vip = GiftRules.check(product("vip_30d"), ShopData.empty(), 0, false, false, false)
		local revive = GiftRules.check(product("revive_1"), ShopData.empty(), 0, false, false, false)
		GiftRules._setGiftable(nil)
		assert(vip == "notGiftable", `VIP: {vip}`)
		assert(revive == "unknown", `revive: {revive}`)
	end,

	["spins blocked for payer or recipient"] = function()
		GiftRules._setGiftable(GIFTABLE)
		local spins = product("spins_paid_3")
		local payer = GiftRules.check(spins, ShopData.empty(), 0, true, false, false)
		local recipient = GiftRules.check(spins, ShopData.empty(), 0, false, true, false)
		local free = GiftRules.check(spins, ShopData.empty(), 0, false, false, false)
		GiftRules._setGiftable(nil)
		assert(payer == "restricted", `quem paga: {payer}`)
		assert(recipient == "restricted", `quem recebe: {recipient}`)
		assert(free == nil, `livre: {free}`)
	end,

	["recipient who owns a forever kit refuses"] = function()
		GiftRules._setGiftable(GIFTABLE)
		local d = ShopData.empty()
		d.KitsOwned.kit_veteran = true
		local refusal = GiftRules.check(product("kit_kit_veteran"), d, 0, false, false, false)
		GiftRules._setGiftable(nil)
		assert(refusal == "bought", `veio {refusal}`)
		assert(GiftRules.alreadyHas(product("kit_kit_veteran"), d), "já tem")
		assert(not GiftRules.alreadyHas(product("kit_kit_veteran"), ShopData.empty()), "não tem")
	end,

	["ember fallback rounds by the 300 pack"] = function()
		assert(GiftRules.emberFallback(80) == 300, "80 → 300")
		assert(GiftRules.emberFallback(399) == 1496, `399 → {GiftRules.emberFallback(399)}`)
	end,

	["giftable follows the gift ids"] = function()
		GiftRules._setGiftable(GIFTABLE)
		local pack = GiftRules.giftable("pack_300")
		local vip = GiftRules.giftable("vip_30d")
		GiftRules._setGiftable(nil)
		assert(pack and not vip, "pack sim, VIP não")
	end,
}
