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
	["temperature ring shows heat when hot"] = function()
		local value, hot = UIMath.temperatureRing(100, 30)
		near(value, 30, "valor com calor")
		assert(hot == true, "modo quente")
		local cold, notHot = UIMath.temperatureRing(60, 0)
		near(cold, 60, "valor sem calor")
		assert(notHot == false, "modo frio")
		local _, nilHot = UIMath.temperatureRing(80, nil :: any)
		assert(nilHot == false, "calor nil = frio")
	end,

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

	["initials of multi-word names skip connectors"] = function()
		assert(UIMath.initials("Picareta de Madeira") == "PM", UIMath.initials("Picareta de Madeira"))
		assert(UIMath.initials("Garrafa d'água") == "GD", UIMath.initials("Garrafa d'água"))
	end,

	["initials of one word use two letters"] = function()
		assert(UIMath.initials("Frutinha") == "Fr", UIMath.initials("Frutinha"))
		assert(UIMath.initials("Ouro") == "Ou", UIMath.initials("Ouro"))
	end,

	["small finger movement is still a tap"] = function()
		assert(UIMath.isDrag(3, 4, 8) == false, "5 px não é arrasto")
		assert(UIMath.isDrag(0, 0, 8) == false, "parado não é arrasto")
	end,

	["movement past threshold is a drag"] = function()
		assert(UIMath.isDrag(6, 8, 8) == true, "10 px é arrasto")
		assert(UIMath.isDrag(-9, 0, 8) == true, "para a esquerda também")
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
