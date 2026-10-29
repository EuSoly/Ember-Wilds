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

-- Coloca (ou tira) o item na mão do personagem. Se o mesmo item já está na
-- mão, não faz nada (a menos que `force`, usado quando a mão foi recriada).
local function apply(character: Model, item: Inventory.Slot?, force: boolean?)
	local itemId = if item then item.id else nil
	local old = character:FindFirstChild(HELD_ITEM)
	if
		not force
		and character:GetAttribute(EQUIPPED) == itemId
		and (old == nil or old:GetAttribute("ItemId") == itemId)
	then
		return
	end
	character:SetAttribute(EQUIPPED, itemId)

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

	-- Posição: o ponto de pegada da mão. Orientação: a do personagem, não a da
	-- mão. Sem a animação de "segurar Tool" o braço fica caído, e a ferramenta
	-- apontaria para o chão; vista de cima ela precisa apontar para a frente,
	-- com a cabeça deitada (Grip: Y = ao longo do cabo, X = lado da cabeça).
	local handGrip = hand:FindFirstChild("RightGripAttachment")
	local gripPosition = if handGrip and handGrip:IsA("Attachment") then handGrip.WorldPosition else hand.Position
	local root = character:FindFirstChild("HumanoidRootPart")
	local facing = if root and root:IsA("BasePart") then root.CFrame else hand.CFrame
	local target = CFrame.fromMatrix(gripPosition, facing.RightVector, facing.LookVector)
	model:PivotTo(target * grip.CFrame:Inverse())

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = hand
	weld.Part1 = handle
	weld.Parent = handle

	model.Parent = character
end

-- Pedidos de troca do mesmo jogador no mesmo quadro viram uma só (um cliente
-- trocando de slot sem parar não faz o servidor criar/destruir peças a cada pedido).
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
	-- Mão recriada (ApplyDescription troca partes do avatar): solda de novo.
	character.ChildAdded:Connect(function(child)
		if table.find(HAND_NAMES, child.Name) and character:GetAttribute(EQUIPPED) ~= nil then
			task.defer(apply, character, selectedItem(player), true)
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
