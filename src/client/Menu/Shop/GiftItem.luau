--!strict
-- Ícone e nome de um item da loja para as telas de presente (janela
-- Presentear e a caixa de quem recebe): "Kit Veterano", "2.600 Golden Ember",
-- "3 Giros especiais", "Kit Veterano (1 vida)".
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Defs = require(Shared:WaitForChild("Defs"))
local MissionImages = require(Shared:WaitForChild("MissionImages"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local Products = require(Shared:WaitForChild("Shop"):WaitForChild("Products"))
local RewardBadge = require(Shared:WaitForChild("Shop"):WaitForChild("RewardBadge"))
local ShopConfig = require(Shared:WaitForChild("Shop"):WaitForChild("ShopConfig"))
local ShopImages = require(Shared:WaitForChild("ShopImages"))
local Strings = require(Shared:WaitForChild("Strings"))
local UiImages = require(Shared:WaitForChild("UiImages"))

-- "ember:<quantidade>": presente que virou Golden Ember (quem recebeu já tinha).
local function emberAmount(productId: string): number?
	local amount = string.match(productId, "^ember:(%d+)$")
	return if amount then tonumber(amount) else nil
end

local GiftItem = {}

-- Imagem do item ("" se não há).
function GiftItem.icon(productId: string): string
	if emberAmount(productId) then
		return UiImages.COIN
	end
	local product = Products.get(productId)
	if product == nil then
		return ""
	end
	local reward = product.rewards[1]
	if product.kind == "kit" or product.kind == "kitOnce" then
		return MonetizationImages.KIT[reward and reward.id or ""] or ""
	elseif productId == "pass_ember2x" then
		return MonetizationImages.EMBER_2X
	elseif productId == "pass_book" then
		return MonetizationImages.BOOK
	elseif product.kind == "boost" then
		return MonetizationImages.XP_BOOST
	elseif product.kind == "pack" and reward then
		for i, pack in ShopConfig.EMBER_PACKS do
			if pack.amount == reward.amount then
				return ShopImages.EMBER_PACK[i] or ""
			end
		end
	elseif product.kind == "spins" then
		return MissionImages.ICON.premio_giro_especial or ""
	elseif product.kind == "bundle" then
		return ShopImages.TAB.packs or ""
	end
	return ""
end

-- Nome do item para quem lê.
function GiftItem.name(productId: string): string
	local ember = emberAmount(productId)
	if ember then
		local badge = RewardBadge.of({ kind = "ember", amount = ember } :: any)
		return `{badge.amount} {badge.label}`
	end
	local product = Products.get(productId)
	if product == nil then
		return productId
	end
	local reward = product.rewards[1]
	if product.kind == "kitOnce" and reward then
		local kit = Defs.Kits[reward.id :: string]
		return Strings.format("gift.item.kitOnce", { name = if kit then Strings.get(kit.nameKey) else "" })
	elseif product.kind == "pack" and reward then
		local badge = RewardBadge.of(reward)
		return `{badge.amount} {badge.label}`
	elseif product.kind == "spins" and reward then
		return `{reward.count} {RewardBadge.of(reward).label}`
	elseif product.nameKey then
		return Strings.get(product.nameKey)
	end
	return productId
end

return GiftItem
