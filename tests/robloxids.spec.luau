--!strict
local Products = require("../src/shared/Shop/Products")
local RobloxIds = require("../src/shared/Shop/RobloxIds")

return {
	["every robux product has its roblox id"] = function()
		local missing: { string } = {}
		for _, product in Products.all() do
			if product.price.currency == "robux" then
				local where = RobloxIds.homeOf(product.kind)
				local id: any = if where == "pass"
					then RobloxIds.GAME_PASS[product.id]
					elseif where == "subscription" then RobloxIds.SUBSCRIPTION[product.id]
					else RobloxIds.PRODUCT[product.id]
				if id == nil then
					table.insert(missing, `{product.id} ({where})`)
				end
			end
		end
		assert(#missing == 0, "sem id no Roblox: " .. table.concat(missing, ", "))
	end,

	["roblox ids map back to the shop product"] = function()
		assert(RobloxIds.fromProduct(RobloxIds.PRODUCT.revive_2) == "revive_2", "produto")
		assert(RobloxIds.fromGamePass(RobloxIds.GAME_PASS.pass_book) == "pass_book", "gamepass")
		assert(RobloxIds.fromSubscription(RobloxIds.SUBSCRIPTION.vip_30d) == "vip_30d", "assinatura")
		assert(RobloxIds.fromProduct(1) == nil, "id de fora")
	end,

	["every giftable item has a gift product"] = function()
		local expected = {
			"kit_kit_starter",
			"kit_kit_explorer",
			"kit_kit_survivor",
			"kit_kit_veteran",
			"pass_ember2x",
			"pass_book",
			"pack_300",
			"pack_600",
			"pack_2600",
			"pack_7000",
			"pack_20000",
			"spins_paid_1",
			"spins_paid_3",
			"spins_paid_10",
			"kitonce_kit_starter",
			"kitonce_kit_explorer",
			"kitonce_kit_survivor",
			"kitonce_kit_veteran",
			"xpboost_1h",
			"bundle_mar",
			"bundle_gelo",
			"bundle_floresta",
		}
		local count = 0
		for _ in RobloxIds.GIFT do
			count += 1
		end
		assert(count == #expected, `{count} presentes, esperava {#expected}`)
		for _, productId in expected do
			assert(RobloxIds.GIFT[productId] ~= nil, `{productId} sem presente`)
		end
		assert(RobloxIds.GIFT.vip_30d == nil, "VIP não se presenteia")
		for productId in RobloxIds.GIFT do
			assert(string.sub(productId, 1, 7) ~= "revive_", "revive não se presenteia")
		end
		local used: { [number]: boolean } = {}
		for _, list in { RobloxIds.PRODUCT, RobloxIds.GAME_PASS } do
			for _, id in list do
				used[id] = true
			end
		end
		for productId, id in RobloxIds.GIFT do
			assert(not used[id], `{productId}: id de presente repete outro`)
			used[id] = true
		end
	end,

	["gift ids map back with the gift flag"] = function()
		local id, gift = RobloxIds.fromProduct(RobloxIds.PRODUCT.pack_300)
		assert(id == "pack_300" and gift == false, "produto normal não é presente")
		for productId, robloxId in RobloxIds.GIFT do
			local back, isGift = RobloxIds.fromProduct(robloxId)
			assert(back == productId and isGift == true, `{productId}: presente`)
		end
	end,

	["no stale ids and no id used twice"] = function()
		local seen: { [number]: string } = {}
		for _, list in { RobloxIds.GAME_PASS, RobloxIds.PRODUCT } do
			for productId, id in list do
				assert(Products.get(productId) ~= nil, `{productId}: não existe mais na loja`)
				assert(seen[id] == nil, `{productId}: id repetido com {seen[id]}`)
				seen[id] = productId
			end
		end
		for productId, id in RobloxIds.SUBSCRIPTION do
			assert(Products.get(productId) ~= nil, `{productId}: não existe mais na loja`)
			assert(string.match(id, "^EXP%-%d+$") ~= nil, `{productId}: id de assinatura é EXP-…`)
		end
	end,
}
