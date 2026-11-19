--!strict
-- Regras puras do preço MOSTRADO em Robux (testadas no Lune). Quem busca é o
-- cliente (client/LivePrices): o Roblox liga o preço por região (Regional
-- Pricing) e a assinatura VIP só é aprovada se a tela mostrar o preço que o
-- Roblox devolve NA HORA para aquele jogador (a chamada do cliente leva os
-- dados do usuário; a do servidor não). O preço do código (Shop/Products)
-- fica só de reserva, enquanto a busca não chega ou se ela falhar.
-- A cobrança não passa por aqui: continua no RobuxService (o Roblox cobra o
-- preço de lá, não o número da tela).
local Products = require("./Products")
local RobloxIds = require("./RobloxIds")
local ShopConfig = require("./ShopConfig")
local Strings = require("../Strings")

local PriceRules = {}

-- O que veio do Roblox: número em Robux e/ou texto pronto (a assinatura
-- devolve DisplayPrice, já com a moeda do jogador).
export type Live = { robux: number?, text: string? }
export type Home = RobloxIds.Home

-- Onde buscar o preço de um produto da loja: o tipo no Roblox e o id. `gift`
-- = o "Presente: X" (outro produto, com preço próprio). nil = sem id (produto
-- de Golden Ember, ou que não tem presente).
function PriceRules.target(productId: string, gift: boolean?): (Home?, (number | string)?)
	if gift then
		local id = RobloxIds.GIFT[productId]
		if id == nil then
			return nil, nil
		end
		local giftHome: Home = "product"
		return giftHome, id
	end
	local product = Products.get(productId)
	if product == nil or product.price.currency ~= "robux" then
		return nil, nil
	end
	local home = RobloxIds.homeOf(product.kind)
	local id: (number | string)? = if home == "pass"
		then RobloxIds.GAME_PASS[productId]
		elseif home == "subscription" then RobloxIds.SUBSCRIPTION[productId]
		else RobloxIds.PRODUCT[productId]
	if id == nil then
		return nil, nil
	end
	return home :: Home, id
end

local function positiveInt(value: any): number?
	if type(value) == "number" and value == value and value >= 1 and value < math.huge then
		return math.floor(value)
	end
	return nil
end

-- Lê a resposta do Roblox sem confiar em campo nenhum (pode faltar, vir com
-- outro tipo ou 0 quando o item está fora de venda). nil = nada aproveitável.
function PriceRules.read(home: Home, info: any): Live?
	if type(info) ~= "table" then
		return nil
	end
	local robux = positiveInt(info.PriceInRobux)
	local text: string? = nil
	if home == "subscription" then
		local display = info.DisplayPrice
		if type(display) == "string" and string.find(display, "%S") ~= nil then
			text = display
		end
	end
	if robux == nil and text == nil then
		return nil
	end
	return { robux = robux, text = text }
end

-- Número em Robux a mostrar: o que o Roblox devolveu, senão o do código.
function PriceRules.robux(live: Live?, fallback: number): number
	local value = if live then positiveInt(live.robux) else nil
	return value or fallback
end

-- Preço em texto, com a moeda: o texto do Roblox (assinatura) se veio; senão
-- o número (vivo ou do código) com o símbolo do Robux.
function PriceRules.label(live: Live?, fallback: number): string
	if live and live.text then
		return live.text
	end
	return Strings.format("kit.robux", { price = PriceRules.robux(live, fallback) })
end

-- Degrau do revive pelo preço que o servidor mandou na oferta (o LifeEnded só
-- leva o número). Cada degrau é um produto (revive_1..revive_4) e os preços de
-- ShopConfig.REVIVE_ROBUX são todos diferentes. nil = preço desconhecido.
function PriceRules.reviveStep(robux: number): number?
	for step, price in ShopConfig.REVIVE_ROBUX do
		if price == robux then
			return step
		end
	end
	return nil
end

return table.freeze(PriceRules)
