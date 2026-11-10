--!strict
-- Inventário de cada jogador, guardado SÓ no servidor (o cliente recebe cópias).
--
-- - O cliente pede (mover, selecionar) pela rede (Net, gerado pelo Blink); este
--   serviço valida e aplica com a lógica pura de Shared/Inventory.
-- - Toda mudança manda ao cliente apenas os slots alterados.
-- - O inventário não é salvo: morre com a partida (spec, seção 7).
-- - Capacidade = base + mochila vestida + bônus do gamepass VIP (InventoryConfig).
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Defs = require(ReplicatedStorage.Shared.Defs)
local HeldItem = require(ReplicatedStorage.Shared.HeldItem)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local InventoryConfig = require(ReplicatedStorage.Shared.InventoryConfig)
local ItemAccess = require(ReplicatedStorage.Shared.ItemAccess)
local Net = require(script.Parent.Parent.Net)

local HOTBAR_SLOTS = InventoryConfig.HOTBAR_SLOTS
local VIP_PASS = InventoryConfig.vipPass

type Slot = Inventory.Slot
type SelectedListener = (Player, Slot?) -> ()

local inventories: { [Player]: Inventory.Inventory } = {}
local selected: { [Player]: number } = {}
-- Mochila vestida (id do item) e slots extras do gamepass, por jogador.
local bags: { [Player]: string? } = {}
local passBonus: { [Player]: number } = {}
local selectedListeners: { SelectedListener } = {}

local InventoryService = {}

local function maxStackOf(id: string): number
	local def = Defs.Items[id]
	return if def then def.maxStack else 1
end

local function bagSlotsOf(bagId: string?): number
	local def = bagId and Defs.Items[bagId]
	return if def and def.bagSlots then def.bagSlots else 0
end

local function capacityFor(player: Player): number
	return Inventory.capacityFor(bagSlotsOf(bags[player]), passBonus[player] or 0)
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
	if not ItemAccess.isAvailable(id, RunService:IsStudio()) or count < 1 or count % 1 ~= 0 then
		return count
	end
	local inv = ensure(player)
	local rest, changed = Inventory.add(inv, id, count, maxStackOf(id))
	sendChanges(player, inv, changed)
	return rest
end

-- Tira itens do jogador, tudo ou nada.
function InventoryService.take(player: Player, id: string, count: number): boolean
	if count < 1 or count % 1 ~= 0 then
		return false
	end
	local inv = ensure(player)
	local ok, changed = Inventory.remove(inv, id, count)
	sendChanges(player, inv, changed)
	return ok
end

-- Tira `count` do slot `index` (não de outra pilha do mesmo item), tudo ou nada.
function InventoryService.takeAt(player: Player, index: number, count: number): boolean
	local inv = inventories[player]
	if inv == nil then
		return false
	end
	local ok, changed = Inventory.removeAt(inv, index, count)
	sendChanges(player, inv, changed)
	return ok
end

-- Troca, no próprio slot `index`, o item `fromId` (1 unidade) por `toId`: o
-- item na mão vira outro sem mudar de lugar (balde ↔ balde com água).
-- false (nada muda) se o slot não tem exatamente 1 de `fromId` ou `toId` não
-- está disponível ao jogador (testOnly fora do Studio).
function InventoryService.swapAt(player: Player, index: number, fromId: string, toId: string): boolean
	local inv = inventories[player]
	local slot = inv and inv.slots[index]
	if
		inv == nil
		or slot == nil
		or slot.id ~= fromId
		or slot.count ~= 1
		or Defs.Items[toId] == nil
		or maxStackOf(toId) < 1
		or not ItemAccess.isAvailable(toId, RunService:IsStudio())
	then
		return false
	end
	inv.slots[index] = { id = toId, count = 1 }
	sendChanges(player, inv, { index })
	return true
end

-- Quanto de `id` caberia agora no inventário (0 sem inventário), sem mudar nada.
function InventoryService.spaceFor(player: Player, id: string): number
	local inv = inventories[player]
	if inv == nil or Defs.Items[id] == nil then
		return 0
	end
	return Inventory.spaceFor(inv, id, maxStackOf(id))
end

-- Recalcula a capacidade (mochila + gamepass) e avisa o cliente se mudou.
-- Devolve false se não deu para diminuir (slots que sumiriam não estão vazios).
local function refreshCapacity(player: Player): boolean
	local inv = ensure(player)
	local before = inv.capacity
	local ok = Inventory.setCapacity(inv, capacityFor(player))
	if inv.capacity ~= before then
		Net.InventoryCapacity.Fire(player, inv.capacity)
	end
	return ok
end

-- Veste a mochila `bagId` (um item com category "bag"), ou tira com nil.
-- A mochila vestida não ocupa slot. Trocar por uma menor (ou tirar) só funciona
-- se os slots que vão sumir estiverem vazios. Devolve true se deu certo.
-- Contrato: esta função NÃO tira o item da mochila do inventário nem devolve a
-- mochila antiga; quem chama (crafting/equipamentos) cuida disso.
-- (Hoje quem chama é o DevItemsService.)
function InventoryService.equipBag(player: Player, bagId: string?): boolean
	if bagId ~= nil then
		local def = Defs.Items[bagId]
		if def == nil or def.category ~= "bag" then
			return false
		end
	end
	local previous = bags[player]
	bags[player] = bagId
	if not refreshCapacity(player) then
		bags[player] = previous
		return false
	end
	player:SetAttribute(StatNames.Bag, bagId)
	return true
end

-- Confere uma troca completa de mochila sem alterar o inventário: tira uma
-- mochila nova do slot selecionado, aplica a nova capacidade e testa devolver
-- a antiga. O WearService usa isto antes de fazer qualquer mudança real.
function InventoryService.canSwapBag(player: Player, newBagId: string, selectedItemId: string): boolean
	local newDef = Defs.Items[newBagId]
	local inv = inventories[player]
	if newDef == nil or newDef.category ~= "bag" or inv == nil then
		return false
	end
	local copy: Inventory.Inventory = { capacity = inv.capacity, slots = {} }
	for index, slot in inv.slots do
		copy.slots[index] = { id = slot.id, count = slot.count }
	end
	if not Inventory.remove(copy, selectedItemId, 1) then
		return false
	end
	local capacity = Inventory.capacityFor(bagSlotsOf(newBagId), passBonus[player] or 0)
	if not Inventory.setCapacity(copy, capacity) then
		return false
	end
	local previous = bags[player]
	if previous ~= nil then
		local rest = Inventory.add(copy, previous, 1, maxStackOf(previous))
		if rest > 0 then
			return false
		end
	end
	return true
end

-- Zera o inventário (a morte perde tudo): inventário novo vazio, sem mochila,
-- slot 1 selecionado. Manda o snapshot inteiro e avisa os ouvintes de seleção
-- (o EquipService limpa a mão). Sem a regra de "slots vazios" do equipBag,
-- porque o inventário novo já está todo vazio.
function InventoryService.reset(player: Player)
	if player.Parent == nil then
		return
	end
	bags[player] = nil
	player:SetAttribute(StatNames.Bag, nil)
	local inv = Inventory.new(capacityFor(player))
	inventories[player] = inv
	selected[player] = 1
	sendSnapshot(player, inv)
	notifySelected(player)
end

-- Slots extras do VIP vindos da loja (ShopService: passe salvo no perfil).
-- O gamepass real (checkVipPass) continua valendo; os dois dão o mesmo bônus.
function InventoryService.setPassBonus(player: Player, slots: number)
	if player.Parent == nil then
		return
	end
	passBonus[player] = math.max(passBonus[player] or 0, slots)
	refreshCapacity(player)
end

-- Gamepass VIP: confere se o jogador tem o passe e soma os slots extras.
local function checkVipPass(player: Player)
	if VIP_PASS.gamePassId == 0 then
		return -- gamepass ainda não criado (InventoryConfig.vipPass.gamePassId)
	end
	local ok, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_PASS.gamePassId)
	end)
	if ok and owns and player.Parent then
		passBonus[player] = VIP_PASS.bonusSlots
		refreshCapacity(player)
	end
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
	if player.Parent == nil or index < 1 or index > HOTBAR_SLOTS or index % 1 ~= 0 then
		return
	end
	local inv = ensure(player)
	-- Arma recém-equipada fica presa na mão (EquipService grava a trava).
	local current = inv.slots[selected[player] or 1]
	local character = player.Character
	if
		current
		and character
		and HeldItem.isLocked(
			Defs.Items[current.id],
			character:GetAttribute(StatNames.EquipLockUntil),
			Workspace:GetServerTimeNow()
		)
	then
		return
	end
	if selected[player] ~= index then
		selected[player] = index
		notifySelected(player)
	end
end

function InventoryService.Start(_self)
	Net.RequestInventory.On(function(player: Player)
		-- Pedido que chegou depois de o jogador sair: não recria o estado dele.
		if player.Parent == nil then
			return
		end
		sendSnapshot(player, ensure(player))
	end)
	Net.MoveSlot.On(onMove)
	Net.SelectSlot.On(onSelect)

	local function onPlayer(player: Player)
		ensure(player)
		task.spawn(checkVipPass, player) -- consulta a Roblox (pode demorar)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	-- Comprou o passe durante a partida: libera na hora.
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
		if purchased and gamePassId == VIP_PASS.gamePassId then
			passBonus[player] = VIP_PASS.bonusSlots
			refreshCapacity(player)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		inventories[player] = nil
		selected[player] = nil
		bags[player] = nil
		passBonus[player] = nil
	end)
end

return InventoryService
