--!strict
-- Cópia do inventário no cliente, mantida pelo servidor (snapshot + deltas via Net).
-- A interface (hotbar e mochila) só lê daqui; para mudar algo o cliente PEDE ao
-- servidor (MoveSlot, SelectSlot), que valida e manda de volta o que mudou.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Net = require(script.Parent:WaitForChild("Net"))

export type Item = { id: string, count: number }

local InventoryState = {}

-- Slots ocupados (índice → item). Slots vazios não aparecem na tabela.
InventoryState.slots = vide.source({} :: { [number]: Item })
-- Quantos slots o jogador pode usar (10, ou 16 com a mochila).
InventoryState.capacity = vide.source(10)
-- Slot escolhido como origem de um "mover" (primeiro toque); nil = nenhum.
InventoryState.pick = vide.source(nil :: number?)

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

-- Toque num slot com a mochila aberta: o primeiro toque escolhe a origem (só
-- se tiver item); o segundo, em outro slot, pede ao servidor para mover.
-- Tocar de novo na origem cancela.
function InventoryState.tap(index: number)
	local origin = vide.untrack(InventoryState.pick)
	if origin == nil then
		if vide.untrack(InventoryState.slots)[index] ~= nil then
			InventoryState.pick(index)
		end
	elseif origin == index then
		InventoryState.pick(nil)
	else
		Net.MoveSlot.Fire(origin, index)
		InventoryState.pick(nil)
	end
end

return InventoryState
