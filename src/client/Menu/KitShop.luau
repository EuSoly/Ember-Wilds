--!strict
-- Kits no menu: a escolha da próxima vida (KitList, compartilhada com a tela
-- de morte) e os kits da loja (saldo de 1 vida, para sempre, ativo), que vêm
-- do servidor (ShopData). Comprar e ativar são pedidos ao servidor; Robux
-- ainda não é cobrado.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local KitChoice = require(Shared:WaitForChild("UIFlow"):WaitForChild("KitChoice"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local ShopData = require(Client:WaitForChild("ShopData"))
local KitList = require(Client:WaitForChild("Screens"):WaitForChild("KitList"))
local Purchase = require(script.Parent:WaitForChild("Purchase"))

local KitShop = {}

-- Escolhe (ou desfaz) o kit pagando com pontos.
function KitShop.choosePoints(kitId: string)
	if vide.untrack(KitList.selected) == kitId and vide.untrack(KitList.source) == "points" then
		KitList.clear()
	else
		KitList.choose(kitId, "points")
	end
end

-- Escolhe (ou desfaz) o kit gastando 1 do saldo de 1 vida.
function KitShop.useBalance(kitId: string)
	if vide.untrack(KitList.selected) == kitId and vide.untrack(KitList.source) == "balance" then
		KitList.clear()
	else
		KitList.choose(kitId, "balance")
	end
end

-- Robux, 1 vida: +1 no saldo do kit (pode comprar quantos quiser).
function KitShop.buyOnce(kitId: string)
	Purchase.buy(`kitonce_{kitId}`)
end

-- Robux, para sempre: a posse; ativar é outro clique.
function KitShop.buyForever(kitId: string)
	Purchase.buy(`kit_{kitId}`)
end

-- Ativa o kit para sempre (ou desativa, se já é o ativo).
function KitShop.toggleActive(kitId: string)
	local active = vide.untrack(ShopData.kitActive)
	Net.SetActiveKit.Fire({ KitId = if active == kitId then nil else kitId })
end

-- Kit que vai na próxima vida e de onde ele sai (reativo), pela mesma regra
-- do servidor (KitChoice).
function KitShop.current(): (string?, KitChoice.Source?)
	local snapshot = ShopData.snapshot()
	-- O verificador alarga "points"/"balance" para string dentro da tabela.
	local request: KitChoice.Request = { kitId = KitList.selected(), source = KitList.source() } :: any
	return KitChoice.resolve(request, {
		points = KitList.points(),
		balance = snapshot.balance,
		owned = snapshot.owned,
		active = snapshot.active,
	}, Defs.Kits)
end

return KitShop
