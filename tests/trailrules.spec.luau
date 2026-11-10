--!strict
local TrailRules = require("../src/shared/Tutorial/TrailRules")

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

return {
	["dots_are_spaced_on_the_line"] = function()
		local dots = TrailRules.dots(0, 0, 20, 0)
		assert(#dots > 0, "tem pontos")
		for i, dot in dots do
			assert(near(dot.x, TrailRules.START_GAP + (i - 1) * TrailRules.SPACING), `ponto {i} no lugar`)
			assert(near(dot.z, 0), "na linha")
			assert(dot.x <= 20 - TrailRules.END_GAP + 1e-6, "para antes do alvo")
		end
		assert(near(dots[1].x, 2) and near(dots[2].x, 4.5), "2, 4,5, ...")
	end,

	["close_target_has_no_dots"] = function()
		assert(#TrailRules.dots(0, 0, 4, 0) == 0, "alvo colado: sem rastro")
	end,

	["long_trail_is_capped"] = function()
		assert(#TrailRules.dots(0, 0, 0, 500) == TrailRules.MAX_DOTS, "no máximo MAX_DOTS")
	end,
}
