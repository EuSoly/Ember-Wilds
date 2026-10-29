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
	["fraction is proportional"] = function()
		near(UIMath.fraction(50, 100), 0.5, "metade")
		near(UIMath.fraction(34, 100), 0.34, "34%")
	end,

	["fraction clamps out of range"] = function()
		near(UIMath.fraction(150, 100), 1, "acima do máximo")
		near(UIMath.fraction(-10, 100), 0, "negativo")
	end,

	["fraction treats NaN as empty"] = function()
		near(UIMath.fraction(0 / 0, 100), 0, "NaN")
	end,

	["ring rotations reveal the arc clockwise"] = function()
		local function expectRing(f: number, right: number, left: number)
			local r, l = UIMath.ringRotations(f)
			near(r, right, `fração {f} metade direita`)
			near(l, left, `fração {f} metade esquerda`)
		end
		expectRing(0, 0, 180) -- vazio
		expectRing(0.25, 90, 180) -- até as 3 h
		expectRing(0.5, 180, 180) -- metade direita cheia
		expectRing(0.75, 180, 270) -- até as 9 h
		expectRing(1, 180, 360) -- cheio
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
