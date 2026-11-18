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
