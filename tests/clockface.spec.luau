--!strict
local ClockFace = require("../src/shared/UIFlow/ClockFace")
local DayCycle = require("../src/shared/DayCycle")

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

return {
	["the cycle starts at 06:00 and night at 18:00"] = function()
		assert(near(DayCycle.at(0).hours, 6), `começo: {DayCycle.at(0).hours}`)
		assert(near(DayCycle.at(DayCycle.DAY_SECONDS / 2).hours, 12), "meio do dia = 12:00")
		assert(near(DayCycle.at(DayCycle.DAY_SECONDS).hours, 18), "noite = 18:00")
		assert(near(DayCycle.at(DayCycle.DAY_SECONDS + DayCycle.NIGHT_SECONDS / 2).hours, 0), "meio da noite = 00:00")
		local next = DayCycle.at(DayCycle.DAY_SECONDS + DayCycle.NIGHT_SECONDS)
		assert(near(next.hours, 6) and next.day == 2, "amanhecer seguinte: 06:00 do dia 2")
	end,

	["24 h label in portuguese"] = function()
		assert(ClockFace.timeText(14.55, false) == "14:30", ClockFace.timeText(14.55, false))
		assert(ClockFace.timeText(0.1, false) == "00:00", ClockFace.timeText(0.1, false))
		assert(ClockFace.timeText(6, false) == "06:00", ClockFace.timeText(6, false))
	end,

	["12 h label in english"] = function()
		assert(ClockFace.timeText(14.55, true) == "2:30 PM", ClockFace.timeText(14.55, true))
		assert(ClockFace.timeText(0.2, true) == "12:10 AM", ClockFace.timeText(0.2, true))
		assert(ClockFace.timeText(12, true) == "12:00 PM", ClockFace.timeText(12, true))
		assert(ClockFace.timeText(9.5, true) == "9:30 AM", ClockFace.timeText(9.5, true))
	end,

	["english for any en locale"] = function()
		assert(ClockFace.isEnglish("en-us") and ClockFace.isEnglish("en-gb") and ClockFace.isEnglish("EN"), "en-*")
		assert(not ClockFace.isEnglish("pt-br") and not ClockFace.isEnglish(""), "outros: 24 h")
	end,

	["sky colors by time of day"] = function()
		local noonTop = ClockFace.sky(12)
		local nightTop = ClockFace.sky(1)
		assert(noonTop ~= nightTop, "dia e noite com céus diferentes")
		local dawnTop = ClockFace.sky(6)
		assert(dawnTop ~= noonTop and dawnTop ~= nightTop, "amanhecer tem cor própria")
		local a = ClockFace.sky(23.99)
		local b = ClockFace.sky(0)
		assert(a == b, "meia-noite sem salto de cor")
	end,

	["sun by day, moon by night, crossing left to right"] = function()
		local isDay, p = ClockFace.body(6)
		assert(isDay and near(p, 0), "06:00: sol começa à esquerda")
		isDay, p = ClockFace.body(12)
		assert(isDay and near(p, 0.5), "12:00: sol no meio")
		isDay, p = ClockFace.body(18)
		assert(not isDay and near(p, 0), "18:00: lua começa")
		isDay, p = ClockFace.body(0)
		assert(not isDay and near(p, 0.5), "00:00: lua no meio")
	end,

	["stars only at night, fading at dusk and dawn"] = function()
		assert(ClockFace.stars(12) == 0, "dia sem estrelas")
		assert(ClockFace.stars(1) == 1, "noite com estrelas")
		local dusk = ClockFace.stars(19)
		assert(dusk > 0 and dusk < 1, `entardecer acendendo: {dusk}`)
	end,
}
