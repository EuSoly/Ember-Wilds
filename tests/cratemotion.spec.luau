--!strict
local CrateMotion = require("../src/shared/Models/CrateMotion")

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

return {
	["the box itself does not move"] = function()
		assert(CrateMotion.of("caixa") == nil, "caixa parada")
	end,

	["rotor and spiral spin, ring spins slower the other way"] = function()
		local rotor = CrateMotion.of("anim_rotor") :: any
		local spiral = CrateMotion.of("anim_espiral") :: any
		local ring = CrateMotion.of("anim_anel") :: any
		assert(rotor and rotor.kind == "spin" and rotor.speed > 0, "rotor gira")
		assert(spiral and spiral.kind == "spin" and spiral.speed > 0, "espiral gira")
		assert(ring and ring.kind == "spin" and ring.speed < 0, "anel gira ao contrário")
		assert(math.abs(ring.speed) < rotor.speed, "anel mais devagar")
	end,

	["feathers, clouds and crystals float out of step"] = function()
		for _, base in { "anim_pena_", "anim_nuvem_", "anim_cristal_" } do
			local first = CrateMotion.of(base .. "01") :: any
			local second = CrateMotion.of(base .. "02") :: any
			assert(first and first.kind == "bob" and second and second.kind == "bob", base .. " flutua")
			assert(first.phase ~= second.phase, base .. " fora de compasso")
		end
	end,

	["unknown animated part stays still"] = function()
		assert(CrateMotion.of("anim_desconhecida") == nil, "papel sem regra fica parado")
	end,

	["spin turns with time"] = function()
		local rotor = CrateMotion.of("anim_rotor") :: CrateMotion.Motion
		local angle, height = CrateMotion.pose(rotor, 2)
		assert(near(angle, (rotor :: any).speed * 2) and height == 0, "ângulo = velocidade × tempo")
	end,

	["bob stays within its amplitude"] = function()
		local feather = CrateMotion.of("anim_pena_01") :: CrateMotion.Motion
		for t = 0, 10, 0.37 do
			local angle, height = CrateMotion.pose(feather, t)
			assert(angle == 0 and math.abs(height) <= (feather :: any).amplitude + 1e-9, `t={t}: {height}`)
		end
	end,
}
