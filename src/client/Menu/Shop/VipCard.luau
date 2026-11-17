--!strict
-- Cartão do VIP (topo da aba de gamepasses): benefícios, "99 por mês" e, com o
-- VIP ativo, "VIP ativo até DD/MM" (a data de VipUntil no horário de Brasília).
-- Comprar de novo soma mais 30 dias ("Renovar"). Quem decide e entrega é o
-- servidor (produto vip_30d); aqui só se pede. Fundo: as camadas 40 com os
-- efeitos em dourado-brasa e a coroa (overlay 40) no lugar do ícone; com o
-- VIP ativo, o brilho de canto por cima.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local Products = require(Shared:WaitForChild("Shop"):WaitForChild("Products"))
local ShopDates = require(Shared:WaitForChild("Shop"):WaitForChild("ShopDates"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local ShopData = require(Client:WaitForChild("ShopData"))
local Purchase = require(script.Parent.Parent:WaitForChild("Purchase"))
local Banner = require(script.Parent:WaitForChild("Banner"))

local R = Theme.rustic

local PURPLE = Color3.fromHex("#8E62E0")
-- Cor do VIP nos efeitos (raios, halo, faíscas): dourado-brasa.
local VIP_GLOW = Color3.fromHex("#FFC66B")

local VipCard = {}

-- Com VIP ativo (VipUntil no futuro, na hora do servidor).
function VipCard.active(): boolean
	return ShopData.vipUntil() > ShopData.now()
end

function VipCard.build(frame: { [any]: any }, compact: () -> boolean): Frame
	local product = Products.get("vip_30d")
	assert(product, "produto vip_30d sumiu de Shop/Products")
	local price = product.price.amount

	local button = Rustic.button({
		Name = "Buy",
		Size = UDim2.fromScale(1, 1),
		kind = "green",
		text = function()
			if VipCard.active() then
				return Strings.format("shop.vip.renew", { price = price })
			end
			return Strings.format("kit.robux", { price = price })
		end,
		maxSize = 22,
		Activated = function()
			Purchase.buy(product.id)
		end,
	})

	return Banner.build({
		name = "Vip",
		theme = PURPLE,
		icon = Banner.icon(
			if MonetizationImages.has(MonetizationImages.VIP_CROWN_OVERLAY)
				then MonetizationImages.VIP_CROWN_OVERLAY
				else MonetizationImages.VIP_NICK,
			"★",
			R.emberLight
		),
		lines = {
			{
				name = "VipName",
				text = function()
					return Strings.get("shop.vip.name")
				end,
				height = 0.3,
				compactHeight = 0.5,
				maxSize = 26,
				title = true,
			},
			{
				name = "VipState",
				text = function()
					if VipCard.active() then
						return Strings.format("shop.vip.active", { date = ShopDates.dayMonth(ShopData.vipUntil()) })
					end
					return Strings.format("shop.vip.month", { price = price })
				end,
				-- Celular: com VIP a data; sem VIP, os benefícios em poucas palavras.
				compactText = function()
					if VipCard.active() then
						return Strings.format("shop.vip.active", { date = ShopDates.dayMonth(ShopData.vipUntil()) })
					end
					return Strings.get("shop.vip.short")
				end,
				height = 0.26,
				compactHeight = 0.5,
				maxSize = 18,
				title = true,
			},
			{
				name = "VipPerks",
				text = function()
					return Strings.get("shop.vip.perks")
				end,
				height = 0.4,
				maxSize = 15,
				wrapped = true,
				hideInCompact = true,
			},
		},
		button = button,
		layers = {
			set = MonetizationImages.VIP_LAYERS,
			size = MonetizationImages.VIP_LAYERS_SIZE,
			slice = MonetizationImages.VIP_LAYERS_SLICE,
			fx = VIP_GLOW,
		},
		art = function()
			local art = MonetizationImages.VIP_CARD
			return if VipCard.active() then art.active else art.normal
		end,
		slice = MonetizationImages.VIP_CARD_SLICE,
		overlay = function()
			return if VipCard.active() then MonetizationImages.VIP_CORNER_GLOW else ""
		end,
		frame = frame,
		compact = compact,
	})
end

return VipCard
