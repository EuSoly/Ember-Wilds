--!strict
local Products = require("../src/shared/Shop/Products")
local RobloxIds = require("../src/shared/Shop/RobloxIds")

-- Onde cada tipo de produto vive no Roblox.
local function home(kind: string): string
	if kind == "kit" or kind == "pass" then
		return "pass"
	elseif kind == "vip" then
		return "subscription"
	end
	return "product"
end

return {
	["every robux product has its roblox id"] = function()
		local missing: { string } = {}
		for _, product in Products.all() do
			if product.price.currency == "robux" then
				local where = home(product.kind)
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
