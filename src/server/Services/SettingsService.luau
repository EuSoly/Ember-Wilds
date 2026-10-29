--!strict
-- Configurações do jogador (volumes, qualidade, tamanho da UI, canhoto), salvas
-- no perfil. Publica cada uma como atributo Setting_<id> no Player (o cliente
-- lê dali) e aceita pedidos de mudança pelo evento Blink SetSetting.
-- O pedido vem do cliente: tudo é validado (SettingsRules) e o inválido é
-- ignorado em silêncio (sem warn: um cliente malicioso não pode encher o Output).
-- A tela de configurações e aplicar volume/qualidade de verdade são da F5.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local SettingsRules = require(ReplicatedStorage.Shared.Data.SettingsRules)
local DataService = require(script.Parent.DataService)
local Net = require(script.Parent.Parent.Net)

local SettingsService = {}

local function attributeOf(id: string): string
	return StatNames.SettingPrefix .. id
end

-- Publica todas as configurações: valor salvo se ainda for válido (a faixa
-- pode ter mudado num update), senão o padrão.
local function publishAll(player: Player, data: { [string]: any })
	for id, def in Defs.Settings do
		local ok, value = SettingsRules.validate(def, data.Settings[id])
		local final = if ok then value else def.default
		data.Settings[id] = final
		player:SetAttribute(attributeOf(id), final)
	end
end

type SetSettingRequest = { Id: string, Number: number?, Flag: boolean?, Choice: string? }

local function onSetSetting(player: Player, request: SetSettingRequest)
	local def = Defs.Settings[request.Id]
	local data = DataService.data(player)
	if def == nil or data == nil then
		return
	end
	local raw: any = if def.kind == "number"
		then request.Number
		elseif def.kind == "boolean" then request.Flag
		else request.Choice
	local ok, value = SettingsRules.validate(def, raw)
	-- Inválido ou igual ao salvo: nada a fazer (não regrava o atributo).
	if not ok or data.Settings[def.id] == value then
		return
	end
	data.Settings[def.id] = value
	player:SetAttribute(attributeOf(def.id), value)
end

function SettingsService.Start(_self)
	DataService.onLoaded(publishAll)
	Net.SetSetting.On(onSetSetting)
end

return SettingsService
