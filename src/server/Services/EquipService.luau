--!strict
-- Item na mão: grava no personagem o atributo Equipped com o id do item do
-- slot selecionado da hotbar (ou nil com slot vazio). Refaz no respawn.
-- O modelo da ferramenta não existe no servidor: cada cliente desenha o item
-- na mão do boneco visual a partir deste atributo (BonecoModel.setHeldItem).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Inventory = require(ReplicatedStorage.Shared.Inventory)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local InventoryService = require(script.Parent.InventoryService)

local EquipService = {}

-- Slot selecionado atual do jogador (nil = vazio ou sem inventário).
local function selectedItem(player: Player): Inventory.Slot?
	local inv = InventoryService.get(player)
	return inv and inv.slots[InventoryService.selectedSlot(player)]
end

-- Grava o item na mão. Se não mudou, não escreve (não replica à toa).
local function apply(character: Model, item: Inventory.Slot?)
	local itemId = if item then item.id else nil
	if character:GetAttribute(StatNames.Equipped) ~= itemId then
		character:SetAttribute(StatNames.Equipped, itemId)
	end
end

-- Pedidos de troca do mesmo jogador no mesmo quadro viram uma só (um cliente
-- trocando de slot sem parar não faz o atributo replicar a cada pedido).
local pending: { [Player]: boolean } = {}

local function applyToPlayer(player: Player)
	if pending[player] then
		return
	end
	pending[player] = true
	task.defer(function()
		pending[player] = nil
		local character = player.Character
		if character and player.Parent then
			apply(character, selectedItem(player))
		end
	end)
end

local function setupCharacter(player: Player, character: Model)
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
