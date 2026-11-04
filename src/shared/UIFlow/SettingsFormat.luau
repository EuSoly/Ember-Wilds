--!strict
-- Grupos, barrinha, troca de opção e texto das configurações (puro, testado
-- no Lune). A tela de configurações calcula o novo valor aqui e pede ao
-- servidor, que valida de novo (SettingsRules); o valor mostrado é sempre o
-- do atributo (menos enquanto o dedo arrasta a barrinha).
local Types = require("../Defs/Types")

type SettingDef = Types.SettingDef
type SettingValue = Types.SettingValue
type SettingGroup = Types.SettingGroup

local SNAP = 0.05 -- a barrinha anda de 5 em 5%

local SettingsFormat = {}

-- Ordem dos grupos na tela (título de cada um: "setting.group.<id>").
local GROUPS: { SettingGroup } = { "sound", "screen", "controls" }
SettingsFormat.GROUPS = table.freeze(GROUPS)

export type Group = { id: SettingGroup, settings: { SettingDef } }

-- Configurações numa lista, na ordem da tela (campo order).
function SettingsFormat.sorted(defs: { [string]: SettingDef }): { SettingDef }
	local list: { SettingDef } = {}
	for _, def in defs do
		table.insert(list, def)
	end
	table.sort(list, function(a: SettingDef, b: SettingDef): boolean
		return a.order < b.order
	end)
	return list
end

-- Grupos na ordem de GROUPS, cada um com as suas configurações na ordem do
-- campo order. Grupo sem nenhuma configuração não aparece.
function SettingsFormat.grouped(defs: { [string]: SettingDef }): { Group }
	local sorted = SettingsFormat.sorted(defs)
	local out: { Group } = {}
	for _, id in GROUPS do
		local list: { SettingDef } = {}
		for _, def in sorted do
			if def.group == id then
				table.insert(list, def)
			end
		end
		if #list > 0 then
			local group: Group = { id = id :: SettingGroup, settings = list }
			table.insert(out, group)
		end
	end
	return out
end

-- Onde o valor fica na barrinha (0 = começo, 1 = fim).
function SettingsFormat.fraction(def: SettingDef, value: number): number
	local min, max = def.min or 0, def.max or 1
	return math.clamp((value - min) / (max - min), 0, 1)
end

-- Valor do ponto `fraction` da barrinha: de 5 em 5%, preso a [min, max] e
-- arredondado a 2 casas (evita 0.30000000000000004, que o servidor aceitaria
-- mas a tela mostraria estranho).
function SettingsFormat.fromFraction(def: SettingDef, fraction: number): number
	local min, max = def.min or 0, def.max or 1
	local raw = min + math.clamp(fraction, 0, 1) * (max - min)
	local snapped = math.clamp(math.round(raw / SNAP) * SNAP, min, max)
	return math.round(snapped * 100) / 100
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
