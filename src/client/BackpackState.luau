--!strict
-- Estado da mochila no cliente:
-- - `hasBag`: o jogador tem a mochila equipada (atributo HasBag do Player). Sem
--   ela, o botão e o painel não aparecem e a tecla B não faz nada;
-- - `open`: o painel está aberto.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local StatNames = require(Shared:WaitForChild("StatNames"))

local BackpackState = {}

BackpackState.hasBag = vide.source(false)
BackpackState.open = vide.source(false)

local function refreshBag()
	local hasBag = Players.LocalPlayer:GetAttribute(StatNames.HasBag) == true
	BackpackState.hasBag(hasBag)
	-- Perdeu a mochila (ex.: morreu): fecha o painel.
	if not hasBag then
		BackpackState.open(false)
	end
end

-- Acompanha o atributo HasBag (chamado uma vez pelo InventoryController).
function BackpackState.start()
	refreshBag()
	Players.LocalPlayer:GetAttributeChangedSignal(StatNames.HasBag):Connect(refreshBag)
end

-- Abre/fecha o painel. Sem mochila equipada, não faz nada.
function BackpackState.toggle()
	if vide.untrack(BackpackState.hasBag) then
		BackpackState.open(not vide.untrack(BackpackState.open))
	end
end

return BackpackState
