--!strict
-- Pode comprar? (puro). O servidor chama antes de cobrar e entregar; a tela
-- usa os mesmos motivos para explicar a recusa.
--   "unknown" produto que não existe
--   "closed"  fora da data (pacote que ainda não começou ou já acabou)
--   "bought"  produto "once" que o jogador já comprou
--   "balance" Golden Ember insuficiente
-- Preço em Robux ainda não é cobrado: nunca recusa por saldo de Robux.
local Rewards = require("./Rewards")
local ShopData = require("./ShopData")
local ShopDates = require("./ShopDates")
local ShopTypes = require("./Types")

export type Refusal = "unknown" | "closed" | "bought" | "balance"

local PurchaseRules = {}

function PurchaseRules.check(
	product: ShopTypes.Product?,
	d: ShopData.ShopData,
	now: number,
	emberBalance: number
): Refusal?
	if product == nil then
		return "unknown"
	end
	if not ShopDates.isOpen(product.startsAt, product.endsAt, now) then
		return "closed"
	end
	if product.once and d.Purchased[product.id] == true then
		return "bought"
	end
	-- Kit ou passe para sempre que já veio por outro caminho (ex. num pacote).
	-- Pacotes não entram: o que falta dentro deles ainda é entregue.
	if product.kind ~= "bundle" and Rewards.allOwned(product.rewards, d) then
		return "bought"
	end
	if product.price.currency == "ember" then
		-- NaN/infinito no saldo nunca pagam.
		local valid = emberBalance == emberBalance and emberBalance ~= math.huge
		if not valid or emberBalance < product.price.amount then
			return "balance"
		end
	end
	return nil
end

return PurchaseRules
