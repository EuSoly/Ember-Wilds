--!strict
-- Escolha do kit de pontos, compartilhada pelo menu (KitsPanel/KitShop) e pela
-- tela de morte: escolher na morte vale no menu e vice-versa. Kit que custa
-- mais que os pontos (atributo KitPoints) não pode ser escolhido; clicar no
-- escolhido tira a escolha. As linhas de kit de cada tela são feitas por ela.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local KitRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("KitRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Sources = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("Sources"))

local KitList = {}

-- Id do kit escolhido (nil = sem kit).
KitList.selected = vide.source(nil :: string?)

local kitPoints: (() -> number)? = nil

-- Pontos para kit (reativo; 0 antes do start).
function KitList.points(): number
	return if kitPoints then kitPoints() else 0
end

function KitList.toggle(kitId: string)
	local kit = Defs.Kits[kitId]
	if vide.untrack(KitList.selected) == kitId then
		KitList.selected(nil)
	elseif KitRules.canBuy(kit, vide.untrack(KitList.points)) then
		KitList.selected(kitId)
	end
end

-- Liga a fonte dos pontos (uma só) e tira a escolha que ficou cara demais.
-- Chamado no corpo do root Vide do ScreenController, antes das telas (chamar
-- de novo não faz nada): Sources.attribute usa vide.cleanup, e dentro de um
-- effect a conexão cairia a cada reexecução.
function KitList.start()
	if kitPoints ~= nil then
		return
	end
	kitPoints = Sources.attribute(Players.LocalPlayer, StatNames.KitPoints, 0)
	vide.effect(function()
		local value = KitList.points()
		local selectedId = vide.untrack(KitList.selected)
		if selectedId ~= nil and not KitRules.canBuy(Defs.Kits[selectedId], value) then
			KitList.selected(nil)
		end
	end)
end

return KitList
