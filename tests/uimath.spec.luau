--!strict
local UIMath = require("../src/shared/UIMath")

local function near(a: number, b: number, label: string)
	assert(math.abs(a - b) < 1e-6, `{label}: esperava {b}, veio {a}`)
end

local function expectStick(dx: number, dy: number, x: number, y: number, active: boolean)
	local rx, ry, ra = UIMath.stick(dx, dy, 60, 10)
	local label = `stick({dx}, {dy})`
	near(rx, x, label .. " x")
	near(ry, y, label .. " y")
	assert(ra == active, `{label}: active {ra}, esperava {active}`)
end

return {
	["filled count proportional"] = function()
		assert(UIMath.filledCount(50, 100, 20) == 10, "metade")
		assert(UIMath.filledCount(34, 100, 20) == 7, "34%")
	end,

	["filled count clamps out of range"] = function()
		assert(UIMath.filledCount(150, 100, 20) == 20, "acima do máximo")
		assert(UIMath.filledCount(-10, 100, 20) == 0, "negativo")
	end,

	["filled count treats NaN as empty"] = function()
		assert(UIMath.filledCount(0 / 0, 100, 20) == 0, "NaN")
	end,

	["segment angles start at the top"] = function()
		near(UIMath.segmentAngle(1, 20), -math.pi / 2, "segmento 1")
		near(UIMath.segmentAngle(6, 20), 0, "segmento 6")
	end,

	["stick gives unit direction"] = function()
		expectStick(30, 0, 1, 0, true)
		expectStick(0, -30, 0, -1, true)
		expectStick(120, 0, 1, 0, true)
	end,

	["stick inside deadzone is inactive"] = function()
		expectStick(3, 4, 0, 0, false)
	end,
}
