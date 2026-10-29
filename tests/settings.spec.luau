--!strict
local Defs = require("../src/shared/Defs")
local SettingsRules = require("../src/shared/Data/SettingsRules")

return {
	["number setting validates range and type"] = function()
		local def = Defs.Settings.music_volume
		local ok, value = SettingsRules.validate(def, 0.5)
		assert(ok == true and value == 0.5, "0.5 é válido")
		assert(SettingsRules.validate(def, 0) == true, "mínimo é válido")
		assert(SettingsRules.validate(def, 1) == true, "máximo é válido")
		assert(SettingsRules.validate(def, 1.5) == false, "acima do máximo")
		assert(SettingsRules.validate(def, -0.1) == false, "abaixo do mínimo")
		assert(SettingsRules.validate(def, 0 / 0) == false, "NaN")
		assert(SettingsRules.validate(def, "0.5") == false, "texto")
		assert(SettingsRules.validate(def, true) == false, "booleano")
	end,

	["choice setting validates options"] = function()
		local def = Defs.Settings.quality
		local ok, value = SettingsRules.validate(def, "high")
		assert(ok == true and value == "high", "high é válido")
		assert(SettingsRules.validate(def, "ultra") == false, "opção inexistente")
		assert(SettingsRules.validate(def, 1) == false, "número")
	end,

	["boolean setting validates type"] = function()
		local def = Defs.Settings.left_handed
		local ok, value = SettingsRules.validate(def, true)
		assert(ok == true and value == true, "true é válido")
		assert(SettingsRules.validate(def, false) == true, "false é válido")
		assert(SettingsRules.validate(def, 1) == false, "número")
		assert(SettingsRules.validate(def, nil) == false, "nil")
	end,

	["defaults come from defs"] = function()
		local defaults = SettingsRules.defaults(Defs.Settings)
		assert(defaults.quality == "auto", `qualidade {defaults.quality}`)
		assert(defaults.music_volume == 0.8, `música {defaults.music_volume}`)
		assert(defaults.left_handed == false, "canhoto desligado")
		assert(defaults.ui_scale == 1, "escala 1")
	end,
}
