--!strict
local BuildRules = require("../src/shared/Build/BuildRules")
local MobMove = require("../src/shared/Mobs/MobMove")

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-4
end

return {
	["walks straight without obstacles"] = function()
		local x, z = MobMove.step(0, 0, 1, 0, 3, 1, {}, nil)
		assert(near(x, 3) and near(z, 0), `{x}, {z}`)
	end,

	["does not enter a circle ahead and ends touching, not overlapping"] = function()
		local circle = { x = 5, z = 0, radius = 2 }
		local x, z = MobMove.step(0, 0, 1, 0, 10, 1, { circle }, nil)
		assert(not BuildRules.circlesOverlap(x, z, 1, circle.x, circle.z, circle.radius), `sobrepôs em {x}, {z}`)
		local dist = math.sqrt((x - circle.x) ^ 2 + (z - circle.z) ^ 2)
		assert(math.abs(dist - 3) < 1e-4, `não encostou: {dist}`)
	end,

	["slides along the edge when walking sideways into a circle"] = function()
		-- Círculo à direita e um pouco acima; o mob anda para +X e escorrega para -Z.
		local circle = { x = 5, z = 1, radius = 2 }
		local x, z = MobMove.step(3, 0, 1, 0, 1, 1, { circle }, nil)
		assert(not BuildRules.circlesOverlap(x, z, 1, circle.x, circle.z, circle.radius), "sobrepôs")
		assert(z < 0, `não escorregou no outro eixo: {z}`)
	end,

	["blocked everywhere keeps the mob still"] = function()
		local x, z = MobMove.step(1, 2, 1, 1, 3, 1, {}, function()
			return true
		end)
		assert(x == 1 and z == 2, `{x}, {z}`)
	end,

	["blocked only on the full step tries X then Z alone"] = function()
		-- Bloqueia z > 0: indo na diagonal, ainda avança só em X.
		local x, z = MobMove.step(0, 0, 1, 1, math.sqrt(2), 0.5, {}, function(_, pz)
			return pz > 0
		end)
		assert(near(x, 1) and near(z, 0), `{x}, {z}`)
	end,

	["zero distance or zero direction stays still"] = function()
		local x, z = MobMove.step(4, 5, 1, 0, 0, 1, {}, nil)
		assert(x == 4 and z == 5, `{x}, {z}`)
		x, z = MobMove.step(4, 5, 0, 0, 3, 1, {}, nil)
		assert(x == 4 and z == 5, `{x}, {z}`)
	end,

	["squeezed between two circles never overlaps"] = function()
		local a = { x = 0, z = 2.5, radius = 1.5 }
		local b = { x = 0, z = -2.5, radius = 1.5 }
		local x, z = MobMove.step(0, 0, 1, 0, 0.5, 1, { a, b }, nil)
		for _, c in { a, b } do
			assert(not BuildRules.circlesOverlap(x, z, 1, c.x, c.z, c.radius), "sobrepôs")
		end
	end,
}
