--!strict
local CameraMath = require("../src/shared/CameraMath")

local function near(a: number, b: number, eps: number, label: string)
	assert(math.abs(a - b) < eps, `{label}: esperava {b}, veio {a}`)
end

return {
	["offset straight down"] = function()
		local height, back = CameraMath.offset(90, 10)
		near(height, 10, 1e-6, "altura a 90°")
		near(back, 0, 1e-6, "recuo a 90°")
	end,

	["offset horizontal"] = function()
		local height, back = CameraMath.offset(0, 10)
		near(height, 0, 1e-6, "altura a 0°")
		near(back, 10, 1e-6, "recuo a 0°")
	end,

	["offset at game pitch"] = function()
		local height, back = CameraMath.offset(65, 34)
		near(height, 30.8145, 1e-3, "altura a 65°")
		near(back, 14.3690, 1e-3, "recuo a 65°")
	end,

	["smooth alpha values"] = function()
		near(CameraMath.smoothAlpha(12, 0), 0, 1e-9, "dt zero")
		near(CameraMath.smoothAlpha(12, 1 / 60), 0.18127, 1e-4, "um frame a 60 fps")
	end,

	["smooth alpha never overshoots"] = function()
		-- alpha em [0, 1]: a câmera nunca passa do alvo nem anda para trás.
		-- Com dt enorme (travada longa) chega exatamente no alvo (alpha = 1).
		for _, dt in { 0, 1 / 240, 1 / 60, 1 / 10, 1, 10 } do
			local alpha = CameraMath.smoothAlpha(12, dt)
			assert(alpha >= 0 and alpha <= 1, `alpha fora de [0, 1] para dt={dt}: {alpha}`)
		end
		assert(CameraMath.smoothAlpha(12, 1 / 10) < 1, "num frame normal não deveria colar no alvo")
	end,
}
