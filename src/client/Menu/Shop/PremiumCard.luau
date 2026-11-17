--!strict
-- Cartão do Roblox Premium (fileira de cima da aba de gamepasses): só para
-- quem não é Premium. O botão abre a compra do Premium do próprio Roblox
-- (MarketplaceService:PromptPremiumPurchase); as vantagens (+20% Golden Ember,
-- Kit Iniciante) quem dá é o servidor (PerkService), lendo MembershipType.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local ShopData = require(Client:WaitForChild("ShopData"))
local Banner = require(script.Parent:WaitForChild("Banner"))

local R = Theme.rustic

local BLUE = Color3.fromHex("#3E7BD6")

local PremiumCard = {}

local player = Players.LocalPlayer
local member = vide.source(player.MembershipType == Enum.MembershipType.Premium)
player:GetPropertyChangedSignal("MembershipType"):Connect(function()
	member(player.MembershipType == Enum.MembershipType.Premium)
end)

-- Mostra o cartão? Não, se o servidor já marcou Premium ou o Roblox diz que é.
function PremiumCard.shown(): boolean
	return not ShopData.perk("premium") and not member()
end

function PremiumCard.build(frame: { [any]: any }, compact: () -> boolean): Frame
	local button = Rustic.button({
		Name = "Subscribe",
		Size = UDim2.fromScale(1, 1),
		kind = "ember",
		text = Strings.get("shop.premium.button"),
		maxSize = 20,
		Activated = function()
			MarketplaceService:PromptPremiumPurchase(player)
		end,
	})
	frame.Visible = PremiumCard.shown
	return Banner.build({
		name = "Premium",
		theme = BLUE,
		icon = Banner.icon("", "P+", R.emberLight),
		lines = {
			{
				name = "PremiumName",
				text = function()
					return Strings.get("shop.premium.title")
				end,
				height = 0.34,
				compactHeight = 0.5,
				maxSize = 22,
				title = true,
			},
			{
				name = "PremiumInfo",
				text = function()
					return Strings.get("shop.premium.desc")
				end,
				compactText = function()
					return Strings.get("shop.premium.short")
				end,
				height = 0.5,
				compactHeight = 0.5,
				maxSize = 15,
				wrapped = true,
			},
		},
		button = button,
		art = function()
			return MonetizationImages.PREMIUM_CARD
		end,
		slice = MonetizationImages.PREMIUM_CARD_SLICE,
		frame = frame,
		compact = compact,
	})
end

return PremiumCard
