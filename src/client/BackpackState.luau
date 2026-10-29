--!strict
-- Estado da mochila no cliente:
-- - `hasBag`: o jogador tem slots além da hotbar (mochila vestida e/ou bônus do
--   gamepass). Sem isso, o botão e o painel não aparecem e a tecla B não faz nada;
-- - `open`: o painel está aberto.
-- Vem da capacidade que o servidor manda (InventoryState.capacity).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local InventoryConfig = require(Shared:WaitForChild("InventoryConfig"))
local InventoryState = require(script.Parent:WaitForChild("InventoryState"))

local BackpackState = {}

BackpackState.hasBag = vide.source(false)
BackpackState.open = vide.source(false)

local function refresh()
	local hasBag = vide.untrack(InventoryState.capacity) > InventoryConfig.HOTBAR_SLOTS
	BackpackState.hasBag(hasBag)
	-- Perdeu a mochila (ex.: morreu): fecha o painel.
	if not hasBag then
		BackpackState.open(false)
	end
end

-- Acompanha a capacidade (chamado uma vez pelo InventoryController).
function BackpackState.start()
	vide.root(function()
		vide.effect(function()
			InventoryState.capacity() -- reage a mudanças de capacidade
			task.defer(refresh) -- escreve outras fontes fora do efeito
		end)
	end)
end

-- Abre/fecha o painel. Sem mochila, não faz nada.
function BackpackState.toggle()
	if vide.untrack(BackpackState.hasBag) then
		BackpackState.open(not vide.untrack(BackpackState.open))
	end
end

return BackpackState
