--!strict
local UIMath = require("../src/shared/UIMath")

local function near(a: number, b: number, label: string)
	assert(math.abs(a - b) < 1e-6, `{label}: esperava {b}, veio {a}`)
end

return {
	["fit distance puts the highest point on the frame edge"] = function()
		-- FOV 90° (tan 45° = 1): ponto 1 acima do centro cabe a 1 de distância.
		near(UIMath.fitDistance({ { 0, 1, 0 } }, 90, 1, 0), 1, "ponto em cima")
		near(UIMath.fitDistance({ { 0, -2, 0 } }, 90, 1, 0), 2, "ponto embaixo conta o módulo")
	end,

	["fit distance accounts for points closer to the camera"] = function()
		-- forward = -1: o ponto está 1 mais perto da câmera, precisa recuar mais 1.
		near(UIMath.fitDistance({ { 0, 1, -1 } }, 90, 1, 0), 2, "ponto mais perto")
		near(UIMath.fitDistance({ { 0, 2, 1 } }, 90, 1, 0), 1, "ponto mais longe")
	end,

	["fit distance uses the aspect for the width"] = function()
		-- Quadro 2:1 tem o dobro de largura: ponto 2 para o lado cabe a 1.
		near(UIMath.fitDistance({ { 2, 0, 0 } }, 90, 2, 0), 1, "largura no quadro largo")
		near(UIMath.fitDistance({ { 2, 0, 0 } }, 90, 1, 0), 2, "largura no quadro quadrado")
	end,

	["fit distance keeps the margin and the worst point"] = function()
		near(UIMath.fitDistance({ { 0, 1, 0 } }, 90, 1, 0.1), 1.1, "margem de 10%")
		local d = UIMath.fitDistance({ { 0, 1, 0 }, { 0, 3, 0 }, { 1, 0, 0 } }, 90, 1, 0)
		near(d, 3, "o ponto mais exigente manda")
	end,

	["fit distance never puts the camera on a point"] = function()
		assert(UIMath.fitDistance({}, 30, 1, 0.1) > 0, "sem pontos ainda dá distância")
		assert(UIMath.fitDistance({ { 0, 0, -2 } }, 30, 1, 0) > 2, "câmera fica à frente do ponto")
	end,
}
