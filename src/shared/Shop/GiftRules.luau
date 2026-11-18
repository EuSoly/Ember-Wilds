--!strict
-- Presentes (puro): o que se pode dar, para quem, e o que acontece se quem
-- recebe já tem. O GiftService confere antes de abrir a compra; a janela
-- Presentear usa as mesmas regras para apagar quem não pode receber.
--   "self"        presentear a si mesmo
--   "notGiftable" item sem produto de presente (VIP, giro normal...)
--   o resto       os motivos de PurchaseRules, contra o perfil de QUEM RECEBE
-- Giros e pacotes com giros: recusados se quem paga OU quem recebe está onde a
-- lei proíbe item aleatório pago.
local PurchaseRules = require("./PurchaseRules")
local Products = require("./Products")
local RobloxIds = require("./RobloxIds")
local ShopData = require("./ShopData")
local ShopTypes = require("./Types")

export type Refusal = PurchaseRules.Refusal | "self" | "notGiftable"

-- Golden Ember por Robux quando o presente já não serve (taxa do pacote de 300).
local EMBER_PER_ROBUX = 300 / 80

local GiftRules = {}

local override: { [string]: boolean }? = nil

-- SÓ TESTES: troca a lista de presenteáveis (nil volta ao RobloxIds.GIFT).
function GiftRules._setGiftable(set: { [string]: boolean }?)
	override = set
end

function GiftRules.giftable(productId: string): boolean
	if override ~= nil then
		return override[productId] == true
	end
	return RobloxIds.GIFT[productId] ~= nil
end

function GiftRules.check(
	product: ShopTypes.Product?,
	recipient: ShopData.ShopData,
	now: number,
	payerBlocked: boolean,
	recipientBlocked: boolean,
	selfGift: boolean
): Refusal?
	if product == nil or product.hidden == true then
		return "unknown"
	end
	if selfGift then
		return "self"
	end
	if not GiftRules.giftable(product.id) then
		return "notGiftable"
	end
	if (payerBlocked or recipientBlocked) and Products.hasRandom(product) then
		return "restricted"
	end
	return PurchaseRules.check(product, recipient, now, math.huge, false)
end

-- Quem recebe já tem o item de uma vez (kit/passe para sempre, pacote comprado)?
function GiftRules.alreadyHas(product: ShopTypes.Product, d: ShopData.ShopData): boolean
	return PurchaseRules.check(product, d, product.startsAt or 0, math.huge, false) == "bought"
end

-- Golden Ember no lugar de um presente que quem recebe já tem.
function GiftRules.emberFallback(robux: number): number
	return math.floor(robux * EMBER_PER_ROBUX + 0.5)
end

return GiftRules
