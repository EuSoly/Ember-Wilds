--!strict
local Shapes = require("../src/shared/World/Shapes")

local EPS = 1e-6

local function near(a: number, b: number, label: string)
	assert(math.abs(a - b) < EPS, `{label}: esperava {b}, veio {a}`)
end

local function box(cx: number, cz: number, sx: number, sz: number, yaw: number): Shapes.Shape
	return { kind = "box", cx = cx, cz = cz, sx = sx, sz = sz, yaw = yaw }
end

local function disc(cx: number, cz: number, r: number): Shapes.Shape
	return { kind = "disc", cx = cx, cz = cz, r = r }
end

return {
	["box without yaw contains center and not beyond the edge"] = function()
		local shape = box(10, 20, 4, 6, 0)
		assert(Shapes.contains(shape, 10, 20), "deveria conter o centro")
		assert(Shapes.contains(shape, 11.9, 22.9), "deveria conter ponto perto do canto")
		assert(not Shapes.contains(shape, 12.1, 20), "não deveria conter além da borda em X")
		assert(not Shapes.contains(shape, 10, 23.1), "não deveria conter além da borda em Z")
	end,

	["box rotated 45 degrees contains a diagonal point"] = function()
		-- Quadrado 10×10: o canto não girado fica a 5 do centro em X; girado 45°,
		-- a ponta vai até 5·√2 ≈ 7.07 no eixo X.
		local straight = box(0, 0, 10, 10, 0)
		local rotated = box(0, 0, 10, 10, math.rad(45))
		assert(not Shapes.contains(straight, 6.5, 0), "o não girado não deveria conter (6.5, 0)")
		assert(Shapes.contains(rotated, 6.5, 0), "o girado deveria conter (6.5, 0)")
		assert(not Shapes.contains(rotated, 4.5, 4.5), "o girado não deveria conter o canto antigo")
	end,

	["disc contains up to the radius"] = function()
		local shape = disc(5, -5, 10)
		assert(Shapes.contains(shape, 5 + 9.9, -5), "deveria conter a r - 0.1")
		assert(not Shapes.contains(shape, 5 + 10.1, -5), "não deveria conter a r + 0.1")
		assert(Shapes.contains(shape, 5, -5 - 9.9), "deveria conter a r - 0.1 em Z")
	end,

	["area of box and disc"] = function()
		near(Shapes.area(box(0, 0, 10, 20, 0.7)), 200, "área da caixa")
		near(Shapes.area(disc(0, 0, 10)), math.pi * 100, "área do disco")
		assert(math.abs(Shapes.area(disc(0, 0, 10)) - 314.16) < 0.01, "disco r=10 ≈ 314.16")
	end,

	["bounds of box rotated 90 degrees swap the sizes"] = function()
		local minX, minZ, maxX, maxZ = Shapes.bounds(box(100, 50, 10, 20, math.rad(90)))
		near(minX, 90, "minX")
		near(maxX, 110, "maxX")
		near(minZ, 45, "minZ")
		near(maxZ, 55, "maxZ")
	end,

	["bounds of disc"] = function()
		local minX, minZ, maxX, maxZ = Shapes.bounds(disc(1, 2, 3))
		near(minX, -2, "minX")
		near(minZ, -1, "minZ")
		near(maxX, 4, "maxX")
		near(maxZ, 5, "maxZ")
	end,

	["distance outside is zero inside and exact outside"] = function()
		near(Shapes.distanceOutside(disc(0, 0, 10), 3, 4), 0, "dentro do disco")
		near(Shapes.distanceOutside(disc(0, 0, 10), 0, 15), 5, "fora do disco")
		near(Shapes.distanceOutside(box(0, 0, 10, 10, 0), 1, 1), 0, "dentro da caixa")
		near(Shapes.distanceOutside(box(0, 0, 10, 10, 0), 8, 0), 3, "fora da caixa, de lado")
		near(Shapes.distanceOutside(box(0, 0, 10, 10, 0), 8, 9), 5, "fora da caixa, pelo canto")
	end,

	["any contains checks every shape"] = function()
		local shapes = { disc(0, 0, 5), box(100, 0, 10, 10, 0) }
		assert(Shapes.anyContains(shapes, 1, 1), "deveria estar no disco")
		assert(Shapes.anyContains(shapes, 103, 2), "deveria estar na caixa")
		assert(not Shapes.anyContains(shapes, 50, 0), "não deveria estar em nenhuma")
		assert(not Shapes.anyContains({}, 0, 0), "lista vazia não contém nada")
	end,

	["box yaw follows CFrame.Angles (sign check)"] = function()
		-- Caixa comprida (20 × 2) girada +30°: o eixo X local aponta para (cos, -sin).
		local yaw = math.rad(30)
		local long = box(0, 0, 20, 2, yaw)
		assert(
			Shapes.contains(long, 8 * math.cos(yaw), -8 * math.sin(yaw)),
			"ponto no eixo girado deveria estar dentro"
		)
		assert(
			not Shapes.contains(long, 8 * math.cos(yaw), 8 * math.sin(yaw)),
			"o giro com sinal trocado não pode valer"
		)
	end,
}
