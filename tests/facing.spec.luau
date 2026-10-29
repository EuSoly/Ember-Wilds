--!strict
local Facing = require("../src/shared/Facing")

local EPS = 1e-6

local function near(a: number?, b: number, label: string)
	assert(a ~= nil, `{label}: veio nil`)
	assert(math.abs((a :: number) - b) < EPS, `{label}: esperava {b}, veio {a}`)
end

return {
	["yaw for the four directions"] = function()
		near(Facing.yawFromDirection(0, -1), 0, "frente (-Z)")
		near(Facing.yawFromDirection(1, 0), -math.pi / 2, "+X")
		near(Facing.yawFromDirection(-1, 0), math.pi / 2, "-X")
		local back = Facing.yawFromDirection(0, 1)
		assert(back ~= nil, "trás: veio nil")
		near(math.abs(back :: number), math.pi, "trás (+Z)")
	end,

	["near zero direction gives nil"] = function()
		assert(Facing.yawFromDirection(0, 0) == nil, "(0,0) deveria ser nil")
		assert(Facing.yawFromDirection(0.001, 0.001) == nil, "vetor minúsculo deveria ser nil")
	end,

	["step is limited by maxDelta"] = function()
		near(Facing.stepYaw(0, math.rad(90), math.rad(30)), math.rad(30), "passo limitado")
	end,

	["step reaches close target"] = function()
		near(Facing.stepYaw(0, math.rad(10), math.rad(30)), math.rad(10), "alvo perto")
	end,

	["step takes the short way across pi"] = function()
		-- De 170° para -170° o caminho curto passa por 180° (20°), não volta 340°.
		-- Com passo de 5°, o primeiro passo vai para 175° (e não para 165°).
		near(Facing.stepYaw(math.rad(170), math.rad(-170), math.rad(5)), math.rad(175), "primeiro passo")
		-- Com passo de 30°, os 20° cabem num passo só: chega no alvo.
		local result = Facing.stepYaw(math.rad(170), math.rad(-170), math.rad(30))
		near(result, math.rad(-170), "chega no alvo")
		assert(result > -math.pi and result <= math.pi, `fora de (-π, π]: {result}`)
	end,

	["step result stays in range"] = function()
		local result = Facing.stepYaw(math.rad(178), math.rad(-170), math.rad(5))
		assert(result > -math.pi and result <= math.pi, `fora de (-π, π]: {result}`)
		near(result, math.rad(-177), "passo que cruza π")
	end,
}
