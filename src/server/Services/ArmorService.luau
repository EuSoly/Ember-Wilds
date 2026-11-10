--!strict
-- Armadura vestida (G1: só a base, ainda não existe nenhum item de armadura).
-- Uma por vez, como o item de cabeça do Starve; fica no atributo Armor do
-- Player (id do item). Os efeitos (defesa no combate, barras caindo mais
-- devagar) vêm do bloco `armor` do item em Defs/Items, via ArmorRules.
-- Contrato (igual ao InventoryService.equipBag): wear NÃO tira nem devolve
-- itens do inventário; quem chamar no futuro (tela de equipamento) cuida disso.
-- Quem chama: WearService (segurar e usar), DevArmor e a morte (tira a peça).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local ArmorRules = require(ReplicatedStorage.Shared.Survival.ArmorRules)
local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local SurvivalConfig = require(ReplicatedStorage.Shared.SurvivalConfig)

local ArmorService = {}

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
		player:SetAttribute(StatNames.ArmorLockUntil, nil)
		player:SetAttribute(StatNames.ExplorerOffUntil, nil)
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

-- Dá para vestir outra peça agora? (espera de ARMOR_SWAP_LOCK depois de vestir)
function ArmorService.canSwap(player: Player): boolean
	local lockUntil = player:GetAttribute(StatNames.ArmorLockUntil)
	return ArmorRules.canSwap(if type(lockUntil) == "number" then lockUntil else nil, Workspace:GetServerTimeNow())
end

-- Começa a espera de troca (chamar depois de vestir pelo jogo).
function ArmorService.startSwapLock(player: Player)
	player:SetAttribute(StatNames.ArmorLockUntil, Workspace:GetServerTimeNow() + SurvivalConfig.ARMOR_SWAP_LOCK)
end

-- O jogador bateu em algo: o Chapéu de Explorador para de esconder por EXPLORER_OFF s.
function ArmorService.markHit(player: Player)
	if ArmorService.modifiers(player).explorer then
		player:SetAttribute(StatNames.ExplorerOffUntil, Workspace:GetServerTimeNow() + SurvivalConfig.EXPLORER_OFF)
	end
end

-- Mobs agressivos ignoram o jogador agora? (Chapéu de Explorador ligado)
function ArmorService.isStealthy(player: Player): boolean
	local offUntil = player:GetAttribute(StatNames.ExplorerOffUntil)
	return ArmorRules.isStealthy(
		ArmorService.modifiers(player),
		if type(offUntil) == "number" then offUntil else nil,
		Workspace:GetServerTimeNow()
	)
end

return ArmorService
