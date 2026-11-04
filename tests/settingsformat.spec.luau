--!strict
local Defs = require("../src/shared/Defs")
local SettingsFormat = require("../src/shared/UIFlow/SettingsFormat")

-- Strings falsas: devolve a própria chave, para o teste ver qual foi pedida.
local function fake(key: string): string
	return key
end

return {
	["fraction places the value along the bar"] = function()
		assert(SettingsFormat.fraction(Defs.Settings.music_volume, 0.3) == 0.3, "música 30%")
		local ui = Defs.Settings.ui_scale
		assert(SettingsFormat.fraction(ui, 0.8) == 0, "mínimo no começo")
		assert(SettingsFormat.fraction(ui, 1.25) == 1, "máximo no fim")
		assert(math.abs(SettingsFormat.fraction(ui, 1.025) - 0.5) < 1e-9, "meio")
		assert(SettingsFormat.fraction(ui, 2) == 1 and SettingsFormat.fraction(ui, 0) == 0, "fora da faixa prende")
	end,

	["fromFraction snaps to 5% and stays in range"] = function()
		local music = Defs.Settings.music_volume
		assert(SettingsFormat.fromFraction(music, 0.33) == 0.35, `{SettingsFormat.fromFraction(music, 0.33)}`)
		assert(SettingsFormat.fromFraction(music, 0.31) == 0.3, `{SettingsFormat.fromFraction(music, 0.31)}`)
		assert(SettingsFormat.fromFraction(music, -0.2) == 0, "antes do começo")
		assert(SettingsFormat.fromFraction(music, 1.3) == 1, "depois do fim")
		local ui = Defs.Settings.ui_scale
		assert(SettingsFormat.fromFraction(ui, 0) == 0.8, "mínimo da escala")
		assert(SettingsFormat.fromFraction(ui, 1) == 1.25, "máximo da escala")
		assert(SettingsFormat.fromFraction(ui, 0.6) == 1.05, `{SettingsFormat.fromFraction(ui, 0.6)}`)
	end,

	["grouped follows the group order and then the order field"] = function()
		local parts: { string } = {}
		for _, group in SettingsFormat.grouped(Defs.Settings) do
			local ids: { string } = {}
			for _, def in group.settings do
				table.insert(ids, def.id)
			end
			table.insert(parts, `{group.id}:{table.concat(ids, ",")}`)
		end
		local expected = "sound:music_volume,ambient_volume,effects_volume|screen:ui_scale,quality|controls:left_handed"
		assert(table.concat(parts, "|") == expected, table.concat(parts, "|"))
	end,

	["grouped skips empty groups"] = function()
		local only = { left_handed = Defs.Settings.left_handed }
		local groups = SettingsFormat.grouped(only :: any)
		assert(#groups == 1 and groups[1].id == "controls", `{#groups}`)
	end,

	["every group has a title text"] = function()
		local ptBR = require("../src/shared/Strings/ptBR") :: { [string]: string }
		for _, id in SettingsFormat.GROUPS do
			assert(ptBR[`setting.group.{id}`] ~= nil, id)
		end
	end,

	["cycle wraps around"] = function()
		local def = Defs.Settings.quality
		assert(SettingsFormat.cycle(def, "high", 1) == "auto", "high → auto")
		assert(SettingsFormat.cycle(def, "auto", -1) == "high", "auto ← high")
		assert(SettingsFormat.cycle(def, "auto", 1) == "low", "auto → low")
		assert(SettingsFormat.cycle(def, "ultra", 1) == "auto", "opção desconhecida volta à primeira")
	end,

	["sorted follows the order field"] = function()
		local ids: { string } = {}
		for _, def in SettingsFormat.sorted(Defs.Settings) do
			table.insert(ids, def.id)
		end
		local expected = "music_volume,ambient_volume,effects_volume,ui_scale,quality,left_handed"
		assert(table.concat(ids, ",") == expected, `ordem: {table.concat(ids, ",")}`)
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
