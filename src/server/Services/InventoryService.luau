--!strict
-- Inventário de cada jogador, guardado SÓ no servidor (o cliente recebe cópias).
--
-- - O cliente pede (mover, selecionar) pela rede (Net, gerado pelo Blink); este
--   serviço valida e aplica com a lógica pura de Shared/Inventory.
-- - Toda mudança manda ao cliente apenas os slots alterados.
-- - O inventário não é salvo: morre com a partida (spec, seção 7).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require(ReplicatedStorage.Shared.Defs)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local Net = require(script.Parent.Parent.Net)

local BASE_SLOTS = 10
local BAG_SLOTS = 6
local HOTBAR_SLOTS = 10
-- Atributo do Player que libera os 6 slots da mochila.
local HAS_BAG = "HasBag"

type Slot = Inventory.Slot
type SelectedListener = (Player, Slot?) -> ()

local inventories: { [Player]: Inventory.Inventory } = {}
local selected: { [Player]: number } = {}
local selectedListeners: { SelectedListener } = {}

local InventoryService = {}

local function maxStackOf(id: string): number
	local def = Defs.Items[id]
	return if def then def.maxStack else 1
end

local function capacityFor(player: Player): number
	return BASE_SLOTS + (if player:GetAttribute(HAS_BAG) == true then BAG_SLOTS else 0)
end

local function toNet(slot: Slot?): Net.Slot?
	return if slot then { Id = slot.id, Count = slot.count } else nil
end

local function sendSnapshot(player: Player, inv: Inventory.Inventory)
	local slots: Net.SlotMap = {}
	for index, slot in inv.slots do
		slots[index] = { Id = slot.id, Count = slot.count }
	end
	Net.InventorySync.Fire(player, { Capacity = inv.capacity, Slots = slots })
end

local function notifySelected(player: Player)
	local inv = inventories[player]
	local slot = inv and inv.slots[selected[player] or 1]
	for _, listener in selectedListeners do
		task.spawn(listener, player, slot)
	end
end

-- Manda os slots alterados (sem repetir) e avisa se o slot selecionado mudou.
local function sendChanges(player: Player, inv: Inventory.Inventory, changed: { number })
	local sent: { [number]: boolean } = {}
	local selectedChanged = false
	for _, index in changed do
		if not sent[index] then
			sent[index] = true
			Net.InventorySlot.Fire(player, index, toNet(inv.slots[index]))
			if index == (selected[player] or 1) then
				selectedChanged = true
			end
		end
	end
	if selectedChanged then
		notifySelected(player)
	end
end

-- Inventário do jogador (cria na primeira vez).
local function ensure(player: Player): Inventory.Inventory
	local inv = inventories[player]
	if inv == nil then
		inv = Inventory.new(capacityFor(player))
		inventories[player] = inv
		selected[player] = 1
	end
	return inv
end

function InventoryService.get(player: Player): Inventory.Inventory?
	return inventories[player]
end

function InventoryService.selectedSlot(player: Player): number
	return selected[player] or 1
end

-- Chamado sempre que o item selecionado de um jogador pode ter mudado
-- (trocou de slot, ou o conteúdo do slot selecionado mudou).
function InventoryService.onSelected(listener: SelectedListener)
	table.insert(selectedListeners, listener)
end

-- Dá itens ao jogador. Devolve o que não coube (0 = coube tudo).
function InventoryService.give(player: Player, id: string, count: number): number
	if Defs.Items[id] == nil or count < 1 or count % 1 ~= 0 then
		return count
	end
	local inv = ensure(player)
	local rest, changed = Inventory.add(inv, id, count, maxStackOf(id))
	sendChanges(player, inv, changed)
	return rest
end

-- Tira itens do jogador, tudo ou nada.
function InventoryService.take(player: Player, id: string, count: number): boolean
	local inv = ensure(player)
	local ok, changed = Inventory.remove(inv, id, count)
	sendChanges(player, inv, changed)
	return ok
end

local function onMove(player: Player, from: number, to: number)
	local inv = inventories[player]
	if inv == nil then
		return
	end
	-- Inventory.move ignora índices fora da capacidade, slot vazio e from == to.
	local changed = Inventory.move(inv, from, to, maxStackOf)
	sendChanges(player, inv, changed)
end

local function onSelect(player: Player, index: number)
	if index < 1 or index > HOTBAR_SLOTS or index % 1 ~= 0 then
		return
	end
	ensure(player)
	if selected[player] ~= index then
		selected[player] = index
		notifySelected(player)
	end
end

local function watchBag(player: Player)
	player:GetAttributeChangedSignal(HAS_BAG):Connect(function()
		local inv = ensure(player)
		local before = inv.capacity
		Inventory.setCapacity(inv, capacityFor(player))
		if inv.capacity ~= before then
			Net.InventoryCapacity.Fire(player, inv.capacity)
		end
	end)
end

function InventoryService.Start(_self)
	Net.RequestInventory.On(function(player: Player)
		sendSnapshot(player, ensure(player))
	end)
	Net.MoveSlot.On(onMove)
	Net.SelectSlot.On(onSelect)

	Players.PlayerAdded:Connect(function(player)
		ensure(player)
		watchBag(player)
	end)
	for _, player in Players:GetPlayers() do
		ensure(player)
		watchBag(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		inventories[player] = nil
		selected[player] = nil
	end)
end

return InventoryService
