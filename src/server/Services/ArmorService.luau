--!strict
-- Armadura vestida (G1: só a base, ainda não existe nenhum item de armadura).
-- Uma por vez, como o item de cabeça do Starve; fica no atributo Armor do
-- Player (id do item). Os efeitos (defesa no combate, barras caindo mais
-- devagar) vêm do bloco `armor` do item em Defs/Items, via ArmorRules.
-- Contrato (igual ao InventoryService.equipBag): wear NÃO tira nem devolve
-- itens do inventário; quem chamar no futuro (tela de equipamento) cuida disso.
-- Hoje quem chama é o comando de dev DevArmor e a morte (tira a armadura).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ArmorRules = require(ReplicatedStorage.Shared.Survival.ArmorRules)
local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)

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

return ArmorService
