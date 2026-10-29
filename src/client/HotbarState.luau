--!strict
-- Estado da hotbar no cliente: o que tem em cada slot e qual está selecionado.
--
-- POR ENQUANTO os itens são fixos, só para a hotbar ter o que mostrar.
-- Na Fase 3 `slots` passa a vir do inventário do servidor (snapshot + deltas)
-- e a seleção passa a ser enviada ao servidor.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))

export type Slot = { id: string, count: number }

local SLOT_COUNT = 10

local HotbarState = {}

HotbarState.SLOT_COUNT = SLOT_COUNT

-- Itens de teste (índice = slot).
local testSlots: { [number]: Slot } = {
	[1] = { id = "wood", count = 24 },
	[2] = { id = "stone", count = 12 },
	[3] = { id = "berry", count = 8 },
	[4] = { id = "wood_pickaxe", count = 1 },
}

HotbarState.slots = vide.source(testSlots)

-- Slot selecionado (1 a 10).
HotbarState.selected = vide.source(1)

function HotbarState.select(index: number)
	if index >= 1 and index <= SLOT_COUNT then
		HotbarState.selected(index)
	end
end

return HotbarState
