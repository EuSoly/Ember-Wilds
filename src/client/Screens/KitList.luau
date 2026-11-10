--!strict
-- Escolha do kit da próxima vida, compartilhada pelo menu (KitsPanel/KitShop)
-- e pela tela de morte: escolher numa vale na outra. A escolha é o kit e de
-- onde ele sai (KitChoice): "points" (pontos da última vida, atributo
-- KitPoints) ou "balance" (saldo de 1 vida comprado na loja, gasta 1).
-- Clicar no escolhido tira a escolha. As linhas de kit de cada tela são
-- feitas por ela. Sem escolha, o servidor usa o kit para sempre ativo.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local KitChoice = require(Shared:WaitForChild("UIFlow"):WaitForChild("KitChoice"))
local KitRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("KitRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Client = script.Parent.Parent
local ShopData = require(Client:WaitForChild("ShopData"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))

export type Source = "points" | "balance"

local KitList = {}

-- Id do kit escolhido (nil = sem escolha) e de onde ele sai.
KitList.selected = vide.source(nil :: string?)
KitList.source = vide.source(nil :: Source?)

local kitPoints: (() -> number)? = nil

-- Pontos para kit (reativo; 0 antes do start).
function KitList.points(): number
	return if kitPoints then kitPoints() else 0
end

-- Escolhe o kit por uma origem dada (botões do painel de kits do menu).
-- false se a origem não dá (sem pontos, sem saldo).
function KitList.choose(kitId: string, source: Source): boolean
	local kit = Defs.Kits[kitId]
	local ok = if source == "points"
		then KitRules.canBuy(kit, vide.untrack(KitList.points))
		else vide.untrack(function()
			return ShopData.kitBalance(kitId)
		end) >= 1
	if kit == nil or not ok then
		return false
	end
	KitList.selected(kitId)
	KitList.source(source)
	return true
end

function KitList.clear()
	KitList.selected(nil)
	KitList.source(nil)
end

-- Clique na linha do kit: tira se já é o escolhido; senão escolhe pela origem
-- automática (pontos se der, para guardar o saldo; senão o saldo).
function KitList.toggle(kitId: string)
	if vide.untrack(KitList.selected) == kitId then
		KitList.clear()
		return
	end
	local source = KitChoice.auto(kitId, vide.untrack(KitList.points), vide.untrack(ShopData.balances), Defs.Kits)
	if source == "points" or source == "balance" then
		KitList.selected(kitId)
		KitList.source(source)
	end
end

-- Liga a fonte dos pontos (uma só) e tira a escolha que deixou de dar (pontos
-- ou saldo acabaram). Chamado no corpo do root Vide do ScreenController,
-- antes das telas (chamar de novo não faz nada): Sources.attribute usa
-- vide.cleanup, e dentro de um effect a conexão cairia a cada reexecução.
function KitList.start()
	if kitPoints ~= nil then
		return
	end
	kitPoints = Sources.attribute(Players.LocalPlayer, StatNames.KitPoints, 0)
	vide.effect(function()
		local points = KitList.points()
		local balances = ShopData.balances()
		local selectedId = vide.untrack(KitList.selected)
		local source = vide.untrack(KitList.source)
		if selectedId == nil then
			return
		end
		local stillOk = if source == "points"
			then KitRules.canBuy(Defs.Kits[selectedId], points)
			else (balances[selectedId] or 0) >= 1
		if not stillOk then
			KitList.clear()
		end
	end)
end

return KitList
