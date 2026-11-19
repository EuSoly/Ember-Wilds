--!strict
local PriceRules = require("../src/shared/Shop/PriceRules")
local Products = require("../src/shared/Shop/Products")
local RobloxIds = require("../src/shared/Shop/RobloxIds")
local ShopConfig = require("../src/shared/Shop/ShopConfig")
local Strings = require("../src/shared/Strings")

return {
	["live price wins when it arrived"] = function()
		assert(PriceRules.robux({ robux = 87 }, 99) == 87, "vivo")
		assert(PriceRules.robux(nil, 99) == 99, "não chegou: o do código")
		assert(PriceRules.robux({ robux = nil, text = "R$ 4,90" }, 99) == 99, "sem número: o do código")
	end,

	["bad live numbers fall back to the code price"] = function()
		for _, bad in { 0, -5, 0 / 0, math.huge } do
			assert(PriceRules.robux({ robux = bad }, 49) == 49, `inválido: {bad}`)
		end
		assert(PriceRules.robux({ robux = 12.7 }, 49) == 12, "arredonda para baixo")
	end,

	["label prefers the roblox display text"] = function()
		assert(PriceRules.label({ text = "R$ 4,90", robux = 99 }, 99) == "R$ 4,90", "texto do Roblox")
		assert(PriceRules.label({ robux = 80 }, 99) == Strings.format("kit.robux", { price = 80 }), "número vivo")
		assert(PriceRules.label(nil, 99) == Strings.format("kit.robux", { price = 99 }), "o do código")
	end,

	["read trusts no field"] = function()
		assert(PriceRules.read("product", nil) == nil, "sem resposta")
		assert(PriceRules.read("product", "x") == nil, "resposta estranha")
		assert(PriceRules.read("product", {}) == nil, "sem PriceInRobux")
		assert(PriceRules.read("pass", { PriceInRobux = 0 }) == nil, "fora de venda")
		assert(PriceRules.read("pass", { PriceInRobux = "99" }) == nil, "texto no lugar do número")
		local live = PriceRules.read("product", { PriceInRobux = 75 })
		assert(live and live.robux == 75 and live.text == nil, "produto")
		-- O texto só conta na assinatura (DisplayPrice).
		local other = PriceRules.read("product", { PriceInRobux = 75, DisplayPrice = "R$ 1" })
		assert(other and other.text == nil, "DisplayPrice fora da assinatura")
	end,

	["subscription reads display price and robux"] = function()
		local both = PriceRules.read("subscription", { DisplayPrice = "R$ 4,90", PriceInRobux = 99 })
		assert(both and both.text == "R$ 4,90" and both.robux == 99, "os dois")
		local text = PriceRules.read("subscription", { DisplayPrice = "$0.99", PriceInRobux = 0 })
		assert(text and text.text == "$0.99" and text.robux == nil, "só o texto (0 = sem Robux)")
		local robux = PriceRules.read("subscription", { DisplayPrice = "  ", PriceInRobux = 99 })
		assert(robux and robux.text == nil and robux.robux == 99, "texto vazio é ignorado")
		assert(PriceRules.read("subscription", { DisplayPrice = 5 }) == nil, "texto de outro tipo")
	end,

	["target points at the right roblox id"] = function()
		local home, id = PriceRules.target("pass_book")
		assert(home == "pass" and id == RobloxIds.GAME_PASS.pass_book, "gamepass")
		home, id = PriceRules.target("kit_kit_starter")
		assert(home == "pass" and id == RobloxIds.GAME_PASS.kit_kit_starter, "kit para sempre")
		home, id = PriceRules.target("pack_300")
		assert(home == "product" and id == RobloxIds.PRODUCT.pack_300, "produto")
		home, id = PriceRules.target("vip_30d")
		assert(home == "subscription" and id == RobloxIds.SUBSCRIPTION.vip_30d, "assinatura")
		home, id = PriceRules.target("pack_300", true)
		assert(home == "product" and id == RobloxIds.GIFT.pack_300, "presente é outro produto")
		home, id = PriceRules.target("vip_30d", true)
		assert(home == nil and id == nil, "VIP não tem presente")
		home, id = PriceRules.target("spins_normal_1")
		assert(home == nil and id == nil, "Golden Ember não busca preço")
		home, id = PriceRules.target("nao_existe")
		assert(home == nil and id == nil, "produto que não existe")
	end,

	["every robux product has a live price target"] = function()
		for _, product in Products.all() do
			if product.price.currency == "robux" then
				local home, id = PriceRules.target(product.id)
				assert(home ~= nil and id ~= nil, `{product.id} sem id para buscar o preço`)
			end
		end
	end,

	["revive step comes from the offered price"] = function()
		for step, price in ShopConfig.REVIVE_ROBUX do
			assert(PriceRules.reviveStep(price) == step, `degrau {step}`)
			assert(PriceRules.target(`revive_{step}`) == "product", `revive_{step} é produto`)
		end
		assert(PriceRules.reviveStep(1) == nil, "preço que não é de degrau")
	end,

	-- reviveStep acha o degrau pelo preço: dois degraus com o mesmo preço
	-- mostrariam o preço vivo do degrau errado.
	["revive prices are all different"] = function()
		local seen: { [number]: boolean } = {}
		for _, price in ShopConfig.REVIVE_ROBUX do
			assert(not seen[price], `preço de revive repetido: {price}`)
			seen[price] = true
		end
	end,
}
