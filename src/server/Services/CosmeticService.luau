--!strict
-- Cosméticos (skins): posse e equipado ficam no perfil salvo
-- (Cosmetics.Owned = id → true, Cosmetics.Equipped = slot → id). Guarda em
-- memória, por jogador e por slot, o id equipado e grava no personagem o
-- atributo Cosmetic_<slot> (ex. Cosmetic_body). Cada cliente lê esse atributo e
-- pinta o boneco visual: todos veem a mesma skin.
-- O mesmo atributo vai também no Player: no menu não há personagem, e o boneco
-- do menu (MenuBoneco) mostra a skin equipada lendo dali.
-- O padrão de cada slot conta como possuído sempre. Equipar um cosmético não
-- possuído falha. Até a loja (F5), a posse vem do comando de dev (DevDataService).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local DataService = require(script.Parent.DataService)
local Net = require(script.Parent.Parent.Net)

local CosmeticService = {}

-- jogador → slot → id equipado (slot ausente = padrão do slot).
local equippedByPlayer: { [Player]: { [string]: string } } = {}

-- Intervalo mínimo entre pedidos de equipar do mesmo jogador (s).
local EQUIP_COOLDOWN = 0.2
-- jogador → os.clock() do último pedido de equipar.
local lastEquipRequest: { [Player]: number } = {}

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

-- Grava o id no atributo do slot (no personagem ou no Player), só se mudou.
local function writeSlot(target: Instance, slot: string, id: string)
	local attribute = StatNames.CosmeticPrefix .. slot
	if target:GetAttribute(attribute) ~= id then
		target:SetAttribute(attribute, id)
	end
end

-- true se o cosmético existe e o jogador o possui (o padrão do slot conta sempre).
function CosmeticService.owns(player: Player, cosmeticId: string): boolean
	local cosmetic = Defs.Cosmetics[cosmeticId]
	if cosmetic == nil then
		return false
	end
	local slotDef = Defs.CosmeticSlots[cosmetic.slot]
	if slotDef ~= nil and slotDef.default == cosmeticId then
		return true
	end
	local data = DataService.data(player)
	return data ~= nil and data.Cosmetics.Owned[cosmeticId] == true
end

-- Dá a posse de um cosmético (loja/dev). false se não existe ou sem perfil.
function CosmeticService.grantOwnership(player: Player, cosmeticId: string): boolean
	local data = DataService.data(player)
	if Defs.Cosmetics[cosmeticId] == nil or data == nil then
		return false
	end
	data.Cosmetics.Owned[cosmeticId] = true
	player:SetAttribute(StatNames.OwnedPrefix .. cosmeticId, true)
	return true
end

-- Põe o id no slot (memória + Player + personagem atual), sem checar posse.
local function apply(player: Player, slot: string, cosmeticId: string)
	local equipped = equippedByPlayer[player]
	if equipped == nil then
		equipped = {}
		equippedByPlayer[player] = equipped
	end
	equipped[slot] = cosmeticId
	writeSlot(player, slot, cosmeticId)
	if player.Character then
		writeSlot(player.Character, slot, cosmeticId)
	end
end

-- Equipa o cosmético no slot dele e grava no perfil. false se o id não existe,
-- se o jogador não o possui ou se o perfil ainda não carregou.
function CosmeticService.equip(player: Player, cosmeticId: string): boolean
	local cosmetic = Defs.Cosmetics[cosmeticId]
	local data = DataService.data(player)
	if cosmetic == nil or data == nil or not CosmeticService.owns(player, cosmeticId) then
		return false
	end
	data.Cosmetics.Equipped[cosmetic.slot] = cosmeticId
	apply(player, cosmetic.slot, cosmeticId)
	DataService.save(player)
	return true
end

-- Perfil carregou: usa o equipado salvo de cada slot se ainda for válido
-- (existe, é do slot certo e é possuído); senão o padrão.
local function loadEquipped(player: Player, data: { [string]: any })
	for slot, slotDef in Defs.CosmeticSlots do
		local saved = data.Cosmetics.Equipped[slot]
		local cosmetic = if type(saved) == "string" then Defs.Cosmetics[saved] else nil
		local valid = cosmetic ~= nil and cosmetic.slot == slot and CosmeticService.owns(player, saved)
		apply(player, slot, if valid then saved else slotDef.default)
	end
end

-- Perfil carregou: publica no Player um atributo Owns_<id> por cosmético possuído.
local function publishOwned(player: Player, data: { [string]: any })
	for id, owned in data.Cosmetics.Owned do
		if owned == true and Defs.Cosmetics[id] ~= nil then
			player:SetAttribute(StatNames.OwnedPrefix .. id, true)
		end
	end
end

-- Pedido do cliente: vem de fora, então tudo é validado e o inválido é ignorado
-- em silêncio (sem warn).
local function onEquipRequest(player: Player, request: { Id: string })
	local now = os.clock()
	local last = lastEquipRequest[player]
	if last ~= nil and now - last < EQUIP_COOLDOWN then
		return
	end
	lastEquipRequest[player] = now
	CosmeticService.equip(player, request.Id)
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
	DataService.onLoaded(publishOwned)
	DataService.onLoaded(loadEquipped)
	Net.EquipCosmetic.On(onEquipRequest)
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		equippedByPlayer[player] = nil
		lastEquipRequest[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
end

return CosmeticService
