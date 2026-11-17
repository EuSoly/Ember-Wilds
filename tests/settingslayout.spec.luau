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
}
