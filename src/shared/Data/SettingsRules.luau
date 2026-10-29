--!strict
-- Validação das configurações do jogador (pura, testada no Lune). O pedido vem
-- do cliente, então nada é corrigido: fora da faixa ou tipo errado é inválido
-- e o servidor ignora.
local Types = require("../Defs/Types")

type SettingDef = Types.SettingDef
type SettingValue = Types.SettingValue

local SettingsRules = {}

-- Devolve (válido?, valor). O valor só vem quando válido.
function SettingsRules.validate(def: SettingDef, value: any): (boolean, SettingValue?)
	if def.kind == "number" then
		-- NaN falha nas duas comparações abaixo (NaN >= x é false).
		if type(value) ~= "number" or value ~= value then
			return false, nil
		end
		local min, max = def.min, def.max
		if min == nil or max == nil or value < min or value > max then
			return false, nil
		end
		return true, value
	elseif def.kind == "boolean" then
		if type(value) ~= "boolean" then
			return false, nil
		end
		return true, value
	elseif def.kind == "choice" then
		local options = def.options
		if type(value) ~= "string" or options == nil or table.find(options, value) == nil then
			return false, nil
		end
		return true, value
	end
	return false, nil
end

-- Padrões de todas as configurações (tabela nova a cada chamada).
function SettingsRules.defaults(defs: { [string]: SettingDef }): { [string]: SettingValue }
	local result: { [string]: SettingValue } = {}
	for id, def in defs do
		result[id] = def.default
	end
	return result
end

return SettingsRules
