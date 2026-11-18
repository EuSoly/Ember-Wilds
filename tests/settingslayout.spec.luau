--!strict
local Defs = require("../src/shared/Defs")
local SettingsFormat = require("../src/shared/UIFlow/SettingsFormat")
local SettingsLayout = require("../src/shared/UIFlow/SettingsLayout")

local function ids(groups: { SettingsFormat.Group }): string
	local out = {}
	for _, group in groups do
		table.insert(out, group.id)
	end
	return table.concat(out, ",")
end

return {
	["current settings split sound | screen+controls"] = function()
		local left, right = SettingsLayout.split(SettingsFormat.grouped(Defs.Settings))
		assert(ids(left) == "sound", `esquerda: {ids(left)}`)
		assert(ids(right) == "screen,controls", `direita: {ids(right)}`)
	end,

	["tallest column fits a 749x330 phone window"] = function()
		local left, right = SettingsLayout.split(SettingsFormat.grouped(Defs.Settings))
		local room = 330 * 0.95 - 40 - 16
		local tallest = math.max(SettingsLayout.columnHeight(left), SettingsLayout.columnHeight(right))
		assert(tallest <= room, `coluna de {tallest} não cabe em {room}`)
	end,

	["one group stays whole"] = function()
		local only = SettingsFormat.grouped({ music_volume = Defs.Settings.music_volume })
		local left, right = SettingsLayout.split(only)
		assert(ids(left) == "sound" and #right == 0, "um grupo só fica à esquerda")
	end,
	["pc list fits a 1280x720 window without scrolling"] = function()
		-- Área da janela do PC: 720 menos a barra do Roblox (58) = 662; janela
		-- 0,86 da altura menos metade do título (29); lista = janela menos o
		-- título e a faixa do Fechar (117). Com a linha do zoom, a lista rolava.
		local room = 0.86 * (720 - 58) - 29 - 117
		local groups = SettingsFormat.grouped(Defs.Settings)
		local height =
			SettingsLayout.listHeight(groups, SettingsLayout.ROW_PC, SettingsLayout.HEADER_PC, SettingsLayout.GAP_PC)
		assert(height <= room, `lista de {height} não cabe em {room}`)
		assert(SettingsLayout.ROW_PC >= 44, "linha do PC com alvo de toque")
	end,
}
