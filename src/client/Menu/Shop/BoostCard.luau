--!strict
-- Cartão do boost de XP (fileira de cima da aba de gamepasses): 49 Robux por
-- +1 h; enquanto o boost corre, mostra o tempo que falta (o mesmo do selo do
-- HUD, UI/XpBoostBadge). Comprar de novo soma mais 1 h.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local Products = require(Shared:WaitForChild("Shop"):WaitForChild("Products"))
local ShopDates = require(Shared:WaitForChild("Shop"):WaitForChild("ShopDates"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local ShopData = require(Client:WaitForChild("ShopData"))
local Purchase = require(script.Parent.Parent:WaitForChild("Purchase"))
local Banner = require(script.Parent:WaitForChild("Banner"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))

local R = Theme.rustic

local TEAL = Color3.fromHex("#2FA39A")

local BoostCard = {}

function BoostCard.build(frame: { [any]: any }): Frame
	local product = Products.get("xpboost_1h")
	assert(product, "produto xpboost_1h sumiu de Shop/Products")

	local function left(): number
		return ShopData.xpBoostUntil() - ShopData.now()
	end

	return Banner.build({
		name = "Boost",
		theme = TEAL,
		icon = Banner.icon(MonetizationImages.XP_BOOST, "XP", R.emberLight),
		lines = {
			{
				name = "BoostName",
				text = function()
					return Strings.get("shop.boost.name")
				end,
				height = 0.34,
				maxSize = 22,
				title = true,
			},
			{
				name = "BoostInfo",
				text = function()
					if left() > 0 then
						return Strings.format("shop.boost.left", { time = ShopDates.clock(left()) })
					end
					return Strings.get("shop.boost.desc")
				end,
				height = 0.5,
				maxSize = 15,
				wrapped = true,
			},
		},
		button = ShopParts.priceButton({
			robux = product.price.amount,
			onClick = function()
				Purchase.buy(product.id)
			end,
			size = UDim2.fromScale(1, 1),
			textSize = 20,
		}),
		frame = frame,
	})
end

return BoostCard
