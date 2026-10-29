--!strict
-- Cosméticos equipados (skins). Guarda em memória, por jogador e por slot, o id
-- equipado e grava no personagem o atributo Cosmetic_<slot> (ex. Cosmetic_body).
-- Cada cliente lê esse atributo e pinta o boneco visual: todos veem a mesma skin.
-- Por enquanto todo mundo começa com o padrão de cada slot e só o comando de
-- dev troca (DevBonecoService). Na F4 o equipado virá do perfil salvo
-- (Equipped = slot → id); aqui só muda de onde vem o valor inicial.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)

local CosmeticService = {}

-- jogador → slot → id equipado (slot ausente = padrão do slot).
local equippedByPlayer: { [Player]: { [string]: string } } = {}

-- Id equipado no slot (o padrão do slot se nada foi equipado).
function CosmeticService.equipped(player: Player, slot: string): string
	local equipped = equippedByPlayer[player]
	local id = equipped and equipped[slot]
	if id ~= nil then
		return id
	end
	local slotDef = Defs.CosmeticSlots[slot]
	assert(slotDef ~= nil, `[CosmeticService] slot "{slot}" não existe`)
	return slotDef.default
end

local function writeSlot(character: Model, slot: string, id: string)
	local attribute = StatNames.CosmeticPrefix .. slot
	if character:GetAttribute(attribute) ~= id then
		character:SetAttribute(attribute, id)
	end
end

-- Equipa o cosmético no slot dele. false se o id não existe.
function CosmeticService.equip(player: Player, cosmeticId: string): boolean
	local cosmetic = Defs.Cosmetics[cosmeticId]
	if cosmetic == nil then
		return false
	end
	local equipped = equippedByPlayer[player]
	if equipped == nil then
		equipped = {}
		equippedByPlayer[player] = equipped
	end
	equipped[cosmetic.slot] = cosmeticId
	if player.Character then
		writeSlot(player.Character, cosmetic.slot, cosmeticId)
	end
	return true
end

-- Personagem novo nasce sem atributos: grava todos os slots.
local function writeAll(player: Player, character: Model)
	for slot in Defs.CosmeticSlots do
		writeSlot(character, slot, CosmeticService.equipped(player, slot))
	end
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		writeAll(player, character)
	end)
	if player.Character then
		writeAll(player, player.Character)
	end
end

function CosmeticService.Start(_self)
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		equippedByPlayer[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
end

return CosmeticService
