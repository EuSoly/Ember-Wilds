--!strict
-- Item na mão: mostra no personagem o item do slot selecionado da hotbar.
--
-- - Grava o atributo "Equipped" no personagem (id do item, ou nil com slot vazio).
-- - Ferramentas ganham um modelo "HeldItem" soldado à mão direita (ToolModel);
--   outros itens (recursos, comida) não aparecem na mão.
-- - Refaz no respawn e quando a mão é trocada (ex.: ApplyDescription recria as
--   partes do avatar), para o modelo nunca ficar solto ou sumir.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ToolModel = require(ReplicatedStorage.Shared.Models.ToolModel)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local InventoryService = require(script.Parent.InventoryService)

local EQUIPPED = "Equipped"
local HELD_ITEM = "HeldItem"
-- R15 usa RightHand; R6 usa "Right Arm".
local HAND_NAMES = { "RightHand", "Right Arm" }
local HAND_TIMEOUT = 10

local EquipService = {}

local function findHand(character: Model): BasePart?
	for _, name in HAND_NAMES do
		local hand = character:FindFirstChild(name)
		if hand and hand:IsA("BasePart") then
			return hand
		end
	end
	return nil
end

-- Slot selecionado atual do jogador (nil = vazio ou sem inventário).
local function selectedItem(player: Player): Inventory.Slot?
	local inv = InventoryService.get(player)
	return inv and inv.slots[InventoryService.selectedSlot(player)]
end

-- Coloca (ou tira) o item na mão do personagem.
local function apply(character: Model, item: Inventory.Slot?)
	character:SetAttribute(EQUIPPED, if item then item.id else nil)

	local old = character:FindFirstChild(HELD_ITEM)
	if old then
		old:Destroy()
	end
	if item == nil then
		return
	end

	local model = ToolModel.build(item.id)
	if model == nil then
		return
	end
	local hand = findHand(character)
	local handle = model.PrimaryPart
	local grip = handle and handle:FindFirstChild("Grip")
	if hand == nil or handle == nil or grip == nil or not grip:IsA("Attachment") then
		model:Destroy()
		return
	end

	-- Alinha o Grip do cabo com o ponto de pegada da mão.
	local handGrip = hand:FindFirstChild("RightGripAttachment")
	local target = if handGrip and handGrip:IsA("Attachment") then handGrip.WorldCFrame else hand.CFrame
	model:PivotTo(target * grip.CFrame:Inverse())

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = handle
	weld.Parent = handle

	model.Parent = character
end

local function applyToPlayer(player: Player)
	local character = player.Character
	if character then
		apply(character, selectedItem(player))
	end
end

local function setupCharacter(player: Player, character: Model)
	-- Mão recriada (ApplyDescription troca partes do avatar): solda de novo.
	character.ChildAdded:Connect(function(child)
		if table.find(HAND_NAMES, child.Name) and character:GetAttribute(EQUIPPED) ~= nil then
			task.defer(apply, character, selectedItem(player))
		end
	end)

	-- A mão pode ainda não existir no CharacterAdded.
	if findHand(character) == nil then
		character:WaitForChild(HAND_NAMES[1], HAND_TIMEOUT)
	end
	if player.Character == character then
		apply(character, selectedItem(player))
	end
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		task.spawn(setupCharacter, player, player.Character)
	end
end

function EquipService.Start(_self)
	-- Trocou de slot ou o conteúdo do slot selecionado mudou.
	InventoryService.onSelected(function(player: Player, _slot)
		applyToPlayer(player)
	end)

	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
end

return EquipService
