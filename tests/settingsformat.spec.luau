--!strict
local Defs = require("../src/shared/Defs")
local SettingsFormat = require("../src/shared/UIFlow/SettingsFormat")

-- Strings falsas: devolve a própria chave, para o teste ver qual foi pedida.
local function fake(key: string): string
	return key
end

return {
	["step moves by 0.1 inside the range"] = function()
		local def = Defs.Settings.music_volume
		assert(SettingsFormat.step(def, 0.8, 1) == 0.9, `{SettingsFormat.step(def, 0.8, 1)}`)
		assert(SettingsFormat.step(def, 0.8, -1) == 0.7, `{SettingsFormat.step(def, 0.8, -1)}`)
		assert(SettingsFormat.step(def, 1, 1) == 1, "preso no máximo")
		assert(SettingsFormat.step(def, 0, -1) == 0, "preso no mínimo")
	end,

	["step clamps ui_scale to its own range"] = function()
		local def = Defs.Settings.ui_scale
		assert(SettingsFormat.step(def, 1.2, 1) == 1.25, `{SettingsFormat.step(def, 1.2, 1)}`)
		assert(SettingsFormat.step(def, 0.85, -1) == 0.8, `{SettingsFormat.step(def, 0.85, -1)}`)
	end,

	["cycle wraps around"] = function()
		local def = Defs.Settings.quality
		assert(SettingsFormat.cycle(def, "high", 1) == "auto", "high → auto")
		assert(SettingsFormat.cycle(def, "auto", -1) == "high", "auto ← high")
		assert(SettingsFormat.cycle(def, "auto", 1) == "low", "auto → low")
		assert(SettingsFormat.cycle(def, "ultra", 1) == "auto", "opção desconhecida volta à primeira")
	end,

	["display formats each kind"] = function()
		assert(SettingsFormat.display(Defs.Settings.music_volume, 0.8, fake) == "80%", "número em %")
		assert(SettingsFormat.display(Defs.Settings.ui_scale, 1.25, fake) == "125%", "escala em %")
		assert(SettingsFormat.display(Defs.Settings.left_handed, true, fake) == "setting.on", "ligado")
		assert(SettingsFormat.display(Defs.Settings.left_handed, false, fake) == "setting.off", "desligado")
		assert(
			SettingsFormat.display(Defs.Settings.quality, "low", fake) == "setting.quality.low",
			"opção vem de setting.<id>.<opção>"
		)
	end,
}
