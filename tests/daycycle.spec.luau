--!strict
local DayCycle = require("../src/shared/DayCycle")

local function expectState(elapsed: number, day: number, isNight: boolean, secondsLeft: number, nightSoon: boolean)
	local s = DayCycle.at(elapsed)
	local label = `at({elapsed})`
	assert(s.day == day, `{label}: dia {s.day}, esperava {day}`)
	assert(s.isNight == isNight, `{label}: isNight {s.isNight}, esperava {isNight}`)
	assert(math.abs(s.secondsLeft - secondsLeft) < 1e-6, `{label}: secondsLeft {s.secondsLeft}, esperava {secondsLeft}`)
	assert(s.nightSoon == nightSoon, `{label}: nightSoon {s.nightSoon}, esperava {nightSoon}`)
end

return {
	["start of the first day"] = function()
		expectState(0, 1, false, 240, false)
	end,

	["night warning 30 seconds before"] = function()
		expectState(215, 1, false, 25, true)
		expectState(209, 1, false, 31, false)
	end,

	["night starts at 240 seconds"] = function()
		expectState(240, 1, true, 240, false)
	end,

	["second day after a full cycle"] = function()
		expectState(480, 2, false, 240, false)
	end,

	["negative elapsed counts as zero"] = function()
		expectState(-5, 1, false, 240, false)
	end,

	["format time as mm:ss"] = function()
		assert(DayCycle.formatTime(130) == "02:10", DayCycle.formatTime(130))
		assert(DayCycle.formatTime(59.9) == "00:59", DayCycle.formatTime(59.9))
		assert(DayCycle.formatTime(0) == "00:00", DayCycle.formatTime(0))
	end,
}
