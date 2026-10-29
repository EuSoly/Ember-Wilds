--!strict
-- Passo, troca de opção e texto das configurações (puro, testado no Lune).
-- A tela de configurações calcula o novo valor aqui e pede ao servidor, que
-- valida de novo (SettingsRules); o valor mostrado é sempre o do atributo.
local Types = require("../Defs/Types")

type SettingDef = Types.SettingDef
type SettingValue = Types.SettingValue

local STEP = 0.1

local SettingsFormat = {}

-- Valor ±0.1, preso a [min, max] e arredondado a 2 casas (evita 0.30000000000000004,
-- que o servidor aceitaria mas a tela mostraria estranho).
function SettingsFormat.step(def: SettingDef, value: number, direction: number): number
	local min, max = def.min or 0, def.max or 1
	local sign = if direction < 0 then -1 else 1
	local nextValue = math.clamp(value + sign * STEP, min, max)
	return math.round(nextValue * 100) / 100
end

-- Próxima (direction > 0) ou anterior opção, dando a volta. Valor fora da
-- lista volta para a primeira opção.
function SettingsFormat.cycle(def: SettingDef, value: string, direction: number): string
	local options = def.options or {}
	local count = #options
	if count == 0 then
		return value
	end
	local index = table.find(options, value)
	if index == nil then
		return options[1]
	end
	local sign = if direction < 0 then -1 else 1
	return options[(index - 1 + sign) % count + 1]
end

-- Texto do valor. getString vem de fora (o cliente passa Strings.get) para
-- este módulo continuar puro.
function SettingsFormat.display(def: SettingDef, value: SettingValue, getString: (string) -> string): string
	if def.kind == "number" and type(value) == "number" then
		return `{math.round(value * 100)}%`
	elseif def.kind == "boolean" then
		return getString(if value == true then "setting.on" else "setting.off")
	elseif def.kind == "choice" and type(value) == "string" then
		return getString(`setting.{def.id}.{value}`)
	end
	return tostring(value)
end

return SettingsFormat
