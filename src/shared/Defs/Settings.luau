--!strict
-- Configurações do jogador salvas no perfil. O cliente pede mudança (Blink,
-- SetSetting) e o servidor valida contra estas defs (tipo, faixa, opções).
-- Configuração nova = uma entrada aqui + o texto "setting.<id>" em Strings/ptBR.luau.
local Types = require("./Types")

type SettingDef = Types.SettingDef

local Settings: { [string]: SettingDef } = {
	music_volume = {
		id = "music_volume",
		nameKey = "setting.music_volume",
		kind = "number",
		default = 0.8,
		min = 0,
		max = 1,
	},
	ambient_volume = {
		id = "ambient_volume",
		nameKey = "setting.ambient_volume",
		kind = "number",
		default = 0.8,
		min = 0,
		max = 1,
	},
	effects_volume = {
		id = "effects_volume",
		nameKey = "setting.effects_volume",
		kind = "number",
		default = 0.8,
		min = 0,
		max = 1,
	},
	quality = {
		id = "quality",
		nameKey = "setting.quality",
		kind = "choice",
		default = "auto",
		options = { "auto", "low", "medium", "high" },
	},
	ui_scale = {
		id = "ui_scale",
		nameKey = "setting.ui_scale",
		kind = "number",
		default = 1,
		min = 0.8,
		max = 1.25,
	},
	left_handed = { id = "left_handed", nameKey = "setting.left_handed", kind = "boolean", default = false },
}

for _, setting in Settings do
	if setting.options ~= nil then
		table.freeze(setting.options)
	end
	table.freeze(setting)
end

return table.freeze(Settings)
