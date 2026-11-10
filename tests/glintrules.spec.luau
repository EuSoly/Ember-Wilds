--!strict
local GlintRules = require("../src/shared/World/GlintRules")

return {
	["glint starts and ends invisible"] = function()
		assert(GlintRules.transparency(0) == 1, "nasce invisível")
		assert(math.abs(GlintRules.transparency(1) - 1) < 1e-9, "some no fim")
		assert(GlintRules.transparency(2) == GlintRules.transparency(1), "fora do intervalo fica no fim")
	end,

	["glint is most visible in the middle"] = function()
		local mid = GlintRules.transparency(0.5)
		assert(math.abs(mid - (1 - GlintRules.PEAK)) < 1e-9, "no auge, 1 - PEAK")
		assert(
			GlintRules.transparency(0.25) > mid and GlintRules.transparency(0.75) > mid,
			"menos visível fora do meio"
		)
	end,

	["glint stretches while it lives"] = function()
		assert(GlintRules.stretch(0) < GlintRules.stretch(0.5), "estica")
		assert(GlintRules.stretch(0.5) < GlintRules.stretch(1), "continua esticando")
		assert(GlintRules.stretch(1) <= 1, "no máximo o comprimento sorteado")
	end,

	["spots stay inside the radius"] = function()
		for _, uv in { { 0, 0 }, { 1, 0 }, { 1, 0.5 }, { 0.25, 0.75 }, { 0.999, 0.3 } } do
			local x, z = GlintRules.spot(10, -20, uv[1], uv[2])
			local d = math.sqrt((x - 10) ^ 2 + (z + 20) ^ 2)
			assert(d <= GlintRules.RADIUS + 1e-6, "dentro do raio")
		end
		local x, z = GlintRules.spot(10, -20, 0, 0.4)
		assert(x == 10 and z == -20, "u = 0 cai no centro")
	end,
}
