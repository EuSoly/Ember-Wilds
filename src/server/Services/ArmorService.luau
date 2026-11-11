--!strict
-- Peça de cabeça vestida (32 itens do Starve; veja docs/guia/armaduras.md).
-- Uma por vez; fica no atributo Armor do Player (id do item). Os efeitos (defesa no combate, barras caindo mais
-- devagar) vêm do bloco `armor` do item em Defs/Items, via ArmorRules.
-- Contrato (igual ao InventoryService.equipBag): wear NÃO tira nem devolve
-- itens do inventário; quem chamar no futuro (tela de equipamento) cuida disso.
-- Quem chama: WearService (segurar e usar), DevArmor e a morte (tira a peça).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ArmorRules = require(ReplicatedStorage.Shared.Survival.ArmorRules)
local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local SurvivalConfig = require(ReplicatedStorage.Shared.SurvivalConfig)

local ArmorService = {}

-- Instantes que só o servidor usa (fora dos atributos do Player, que têm limite
-- de tamanho): fim da espera de troca e fim do "explorador desligado".
local lockUntil: { [Player]: number } = {}
local offUntil: { [Player]: number } = {}

-- Veste a armadura `itemId` (category "armor"), ou tira com nil.
-- Devolve false se o item não existe ou não é armadura.
function ArmorService.wear(player: Player, itemId: string?): boolean
	if itemId ~= nil then
		local def = Defs.Items[itemId]
		if def == nil or def.category ~= "armor" then
			return false
		end
	end
	player:SetAttribute(StatNames.Armor, itemId)
	-- Tirar a peça (morte, dev) zera a trava de troca e o explorador.
	if itemId == nil then
		lockUntil[player] = nil
		offUntil[player] = nil
	end
	return true
end

-- Modificadores da armadura vestida (sem armadura, ou id que sumiu das Defs = neutro).
function ArmorService.modifiers(player: Player): ArmorRules.Modifiers
	local itemId = player:GetAttribute(StatNames.Armor)
	if type(itemId) ~= "string" then
		return ArmorRules.NONE
	end
	return ArmorRules.modifiers(Defs.Items[itemId])
end

-- Item da peça vestida (nil sem peça ou id que sumiu das Defs).
function ArmorService.worn(player: Player): Defs.ItemDef?
	local itemId = player:GetAttribute(StatNames.Armor)
	return if type(itemId) == "string" then Defs.Items[itemId] else nil
end

-- Dá para vestir outra peça agora? (espera de ARMOR_SWAP_LOCK depois de vestir)
function ArmorService.canSwap(player: Player): boolean
	return ArmorRules.canSwap(lockUntil[player], Workspace:GetServerTimeNow())
end

-- Começa a espera de troca (chamar depois de vestir pelo jogo).
function ArmorService.startSwapLock(player: Player)
	lockUntil[player] = Workspace:GetServerTimeNow() + SurvivalConfig.ARMOR_SWAP_LOCK
end

-- O jogador bateu em algo: o Chapéu de Explorador para de esconder por
-- EXPLORER_OFF s. Grava com qualquer peça (vestir o chapéu logo depois de bater
-- não engana o mob que apanhou).
function ArmorService.markHit(player: Player)
	offUntil[player] = ArmorRules.hitOffUntil(Workspace:GetServerTimeNow())
end

-- Mobs agressivos ignoram o jogador agora? (Chapéu de Explorador ligado)
function ArmorService.isStealthy(player: Player): boolean
	return ArmorRules.isStealthy(ArmorService.modifiers(player), offUntil[player], Workspace:GetServerTimeNow())
end

function ArmorService.Start(_self)
	Players.PlayerRemoving:Connect(function(player)
		lockUntil[player] = nil
		offUntil[player] = nil
	end)
end

return ArmorService
