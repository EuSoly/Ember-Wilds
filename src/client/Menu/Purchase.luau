--!strict
-- Comprar na loja: manda o pedido ao servidor (ShopService) e mostra a
-- resposta no aviso do menu ("Comprado!", "Golden Ember insuficiente"...).
-- Com Robux o servidor abre a janela de compra do Roblox (Reason "prompt",
-- sem aviso) e o "Comprado!" chega depois, quando o pagamento entra.
-- Revive (revive_N) cancelado: reativa os botões da oferta na tela de morte.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Strings = require(Shared:WaitForChild("Strings"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))
local ScreenState = require(Client:WaitForChild("ScreenState"))

local Purchase = {}

function Purchase.buy(productId: string)
	Net.RequestPurchase.Fire({ ProductId = productId })
end

Net.PurchaseResult.On(function(result: { ProductId: string, Ok: boolean, Reason: string? })
	if string.sub(result.ProductId, 1, 7) == "revive_" then
		if not result.Ok then
			ScreenState.reviveSending(false)
		end
		return
	end
	if result.Reason == "prompt" then
		return
	end
	if result.Ok then
		MenuState.notify(Strings.get("shop.result.ok"))
		return
	end
	local key = `shop.result.{result.Reason or "error"}`
	MenuState.notify(Strings.get(if Strings.has(key) then key else "shop.result.error"))
end)

return Purchase
