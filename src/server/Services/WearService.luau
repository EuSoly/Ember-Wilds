--!strict
-- Usar capacete, protetor ou mochila consome o item segurado e devolve o usado.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require(ReplicatedStorage.Shared.Defs)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local ArmorService = require(script.Parent.ArmorService)
local InventoryService = require(script.Parent.InventoryService)

local WearService = {}

local function canReturnArmor(player: Player, heldId: string, oldId: string?): boolean
	if oldId == nil then
		return true
	end
	local inv = InventoryService.get(player)
	if inv == nil then
		return false
	end
	local copy: Inventory.Inventory = { capacity = inv.capacity, slots = {} }
	for index, slot in inv.slots do
		copy.slots[index] = { id = slot.id, count = slot.count }
	end
	if not Inventory.remove(copy, heldId, 1) then
		return false
	end
	local def = Defs.Items[oldId]
	if def == nil then
		return false
	end
	return Inventory.add(copy, oldId, 1, def.maxStack) == 0
end

local function wear(player: Player, character: Model)
	if character:GetAttribute(StatNames.CraftRecipe) ~= nil then
		return
	end
	local heldId = character:GetAttribute(StatNames.Equipped)
	if type(heldId) ~= "string" then
		return
	end
	local item = Defs.Items[heldId]
	if item == nil or (item.category ~= "armor" and item.category ~= "bag") then
		return
	end
	local inv = InventoryService.get(player)
	local selected = inv and inv.slots[InventoryService.selectedSlot(player)]
	if selected == nil or selected.id ~= heldId or selected.count < 1 then
		return
	end

	if item.category == "armor" then
		local previous = player:GetAttribute(StatNames.Armor)
		local oldId = if type(previous) == "string" then previous else nil
		if not canReturnArmor(player, heldId, oldId) then
			return
		end
		if not InventoryService.take(player, heldId, 1) then
			return
		end
		if not ArmorService.wear(player, heldId) then
			InventoryService.give(player, heldId, 1)
			return
		end
		if oldId then
			InventoryService.give(player, oldId, 1)
		end
	elseif item.category == "bag" then
		if not InventoryService.canSwapBag(player, heldId, heldId) then
			return
		end
		local previous = player:GetAttribute(StatNames.Bag)
		local oldId = if type(previous) == "string" then previous else nil
		if not InventoryService.take(player, heldId, 1) then
			return
		end
		if not InventoryService.equipBag(player, heldId) then
			InventoryService.give(player, heldId, 1)
			return
		end
		if oldId then
			InventoryService.give(player, oldId, 1)
		end
	end
end

local function setupCharacter(player: Player, character: Model)
	local held = character:GetAttribute(StatNames.Using) == true
	character:GetAttributeChangedSignal(StatNames.Using):Connect(function()
		local using = character:GetAttribute(StatNames.Using) == true
		if not using then
			held = false
		elseif not held then
			held = true
			if player.Character == character then
				wear(player, character)
			end
		end
	end)
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		setupCharacter(player, player.Character)
	end
end

function WearService.Start(_self)
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
end

return WearService
