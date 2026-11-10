--!strict
local PointerRules = require("../src/shared/Tutorial/PointerRules")

return {
	["side right: arrow to the right of the target, pointing left"] = function()
		local p = PointerRules.place(20, 80, 52, 52, "right")
		assert(p.rotation == 90, "aponta para a esquerda")
		assert(p.x == 20 + 52 + PointerRules.GAP + PointerRules.SIZE / 2, "logo à direita")
		assert(p.y == 80 + 26, "na altura do meio")
	end,

	["side left: arrow to the left of the target, pointing right"] = function()
		local p = PointerRules.place(1200, 250, 60, 60, "left")
		assert(p.rotation == -90, "aponta para a direita")
		assert(p.x == 1200 - PointerRules.GAP - PointerRules.SIZE / 2, "logo à esquerda")
		assert(p.y == 280, "na altura do meio")
	end,

	["side below: arrow under the target, pointing up"] = function()
		local p = PointerRules.place(600, 100, 80, 40, "below")
		assert(p.rotation == 180, "aponta para cima")
		assert(p.x == 640, "no meio do alvo")
		assert(p.y == 100 + 40 + PointerRules.GAP + PointerRules.SIZE / 2, "logo abaixo")
	end,

	["bob moves away from the target and back"] = function()
		local quarter = math.pi / 2 / PointerRules.BOB_SPEED
		local right = PointerRules.place(20, 80, 52, 52, "right")
		local dx0, dy0 = PointerRules.bob(right, 0)
		local dxMax, dyMax = PointerRules.bob(right, quarter)
		assert(dy0 == 0 and dyMax == 0, "seta horizontal balança na horizontal")
		assert(dxMax > dx0 and dxMax <= PointerRules.BOB + 1e-9, "afasta para a direita, até BOB")
		local bx, by = PointerRules.bob(PointerRules.place(600, 100, 80, 40, "below"), quarter)
		assert(bx == 0 and by > 0, "seta de baixo balança para baixo")
		local lx = PointerRules.bob(PointerRules.place(1200, 250, 60, 60, "left"), quarter)
		assert(lx < 0, "seta da esquerda balança para a esquerda")
	end,
}
