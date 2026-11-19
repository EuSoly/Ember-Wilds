--!strict
-- Cópia do inventário no cliente, mantida pelo servidor (snapshot + deltas via Net).
-- A interface (hotbar e mochila) só lê daqui; para mudar algo o cliente PEDE ao
-- servidor (MoveSlot, SelectSlot), que valida e manda de volta o que mudou.
-- Mover itens é feito arrastando (ver DragState).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Players = game:GetService("Players")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local StatNames = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StatNames"))
local Net = require(script.Parent:WaitForChild("Net"))

export type Item = { id: string, count: number }

local InventoryState = {}

-- Slots ocupados (índice → item). Slots vazios não aparecem na tabela.
InventoryState.slots = vide.source({} :: { [number]: Item })
-- Quantos slots o jogador pode usar (10 + mochila + gamepass, até 40).
InventoryState.capacity = vide.source(10)
-- Peça de cabeça vestida (atributo Armor do Player), ou nil. Fica aqui porque
-- o craft a conta como ingrediente (capacete de pedra pede o de madeira) e o
-- livro, a coluna e a receita fixada leem daqui sem depender um do outro.
InventoryState.worn = vide.source(nil :: string?)

local function readWorn()
	local value = Players.LocalPlayer:GetAttribute(StatNames.Armor)
	local id = if type(value) == "string" then value else nil
	if vide.untrack(InventoryState.worn) ~= id then
		InventoryState.worn(id)
	end
end

-- Contagem por id dos slots, com a peça vestida somada (é o que o servidor
-- aceita no craft: CraftRules.withWorn).
function InventoryState.craftCounts(): { [string]: number }
	local result: { [string]: number } = {}
	for _, slot in InventoryState.slots() do
		result[slot.id] = (result[slot.id] or 0) + slot.count
	end
	local worn = InventoryState.worn()
	if worn then
		result[worn] = (result[worn] or 0) + 1
	end
	return result
end

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

	-- Atributo no Player (não no personagem previsto), então o sinal dispara.
	Players.LocalPlayer:GetAttributeChangedSignal(StatNames.Armor):Connect(readWorn)
	readWorn()

	Net.RequestInventory.Fire()
end

return InventoryState
