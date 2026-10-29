--!strict
-- Cópia do inventário no cliente, mantida pelo servidor (snapshot + deltas via Net).
-- A interface (hotbar e mochila) só lê daqui; para mudar algo o cliente PEDE ao
-- servidor (MoveSlot, SelectSlot), que valida e manda de volta o que mudou.
-- Mover itens é feito arrastando (ver DragState).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Net = require(script.Parent:WaitForChild("Net"))

export type Item = { id: string, count: number }

local InventoryState = {}

-- Slots ocupados (índice → item). Slots vazios não aparecem na tabela.
InventoryState.slots = vide.source({} :: { [number]: Item })
-- Quantos slots o jogador pode usar (10, ou 16 com a mochila).
InventoryState.capacity = vide.source(10)

local function fromNet(slot: Net.Slot?): Item?
	return if slot then { id = slot.Id, count = slot.Count } else nil
end

-- Liga os ouvintes e SÓ DEPOIS pede o inventário: assim a resposta nunca chega
-- antes de alguém estar escutando.
function InventoryState.start()
	Net.InventorySync.On(function(data)
		local slots: { [number]: Item } = {}
		for index, slot in data.Slots do
			slots[index] = { id = slot.Id, count = slot.Count }
		end
		InventoryState.capacity(data.Capacity)
		InventoryState.slots(slots)
	end)

	Net.InventorySlot.On(function(index, slot)
		local slots = table.clone(vide.untrack(InventoryState.slots))
		local item = fromNet(slot)
		if item then
			slots[index] = item
		else
			slots[index] = nil
		end
		InventoryState.slots(slots)
	end)

	Net.InventoryCapacity.On(function(capacity)
		InventoryState.capacity(capacity)
	end)

	Net.RequestInventory.Fire()
end

return InventoryState
