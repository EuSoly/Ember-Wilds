--!strict
-- Comprar na loja: manda o pedido ao servidor (ShopService) e mostra a
-- resposta no aviso do menu ("Comprado!", "Golden Ember insuficiente"...).
-- Robux ainda não é cobrado: o servidor entrega de graça.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))

local Purchase = {}

function Purchase.buy(productId: string)
	Net.RequestPurchase.Fire({ ProductId = productId })
end

Net.PurchaseResult.On(function(result: { ProductId: string, Ok: boolean, Reason: string? })
	if result.Ok then
		MenuState.notify(Strings.get("shop.result.ok"))
		return
	end
	local key = `shop.result.{result.Reason or "error"}`
	MenuState.notify(Strings.get(if Strings.has(key) then key else "shop.result.error"))
end)

return Purchase
