--!strict
-- Configurações do jogador salvas no perfil. O cliente pede mudança (Blink,
-- SetSetting) e o servidor valida contra estas defs (tipo, faixa, opções).
-- Configuração nova = uma entrada aqui + o texto "setting.<id>" em Strings/ptBR.luau.
-- group = em qual grupo da tela ela aparece ("sound", "screen" ou "controls").
-- order = posição na tela de configurações (inteiro ≥ 1, sem repetir).
local Types = require("./Types")

type SettingDef = Types.SettingDef

local Settings: { [string]: SettingDef } = {
	music_volume = {
		id = "music_volume",
		nameKey = "setting.music_volume",
		group = "sound",
		order = 1,
		kind = "number",
		default = 0.8,
		min = 0,
		max = 1,
	},
	ambient_volume = {
		id = "ambient_volume",
		nameKey = "setting.ambient_volume",
		group = "sound",
		order = 2,
		kind = "number",
		default = 0.8,
		min = 0,
		max = 1,
	},
	effects_volume = {
		id = "effects_volume",
		nameKey = "setting.effects_volume",
		group = "sound",
		order = 3,
		kind = "number",
		default = 0.8,
		min = 0,
		max = 1,
	},
	ui_scale = {
		id = "ui_scale",
		nameKey = "setting.ui_scale",
		group = "screen",
		order = 4,
		kind = "number",
		default = 1,
		min = 0.8,
		max = 1.25,
	},
	quality = {
		id = "quality",
		nameKey = "setting.quality",
		group = "screen",
		order = 5,
		kind = "choice",
		default = "auto",
		options = { "auto", "low", "medium", "high" },
	},
	left_handed = {
		id = "left_handed",
		nameKey = "setting.left_handed",
		group = "controls",
		order = 6,
		kind = "boolean",
		default = false,
	},
}

for _, setting in Settings do
	if setting.options ~= nil then
		table.freeze(setting.options)
	end
	table.freeze(setting)
end

return table.freeze(Settings)
