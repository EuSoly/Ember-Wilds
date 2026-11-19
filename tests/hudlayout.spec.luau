--!strict
local HudLayout = require("../src/shared/UIFlow/HudLayout")

local function rightOf(hotbar: HudLayout.Hotbar): number
	return hotbar.centerX + hotbar.width / 2
end

local function leftOf(hotbar: HudLayout.Hotbar): number
	return hotbar.centerX - hotbar.width / 2
end

return {
	["phone in the Studio emulator: one row between the sticks"] = function()
		local width, height = 749, 330
		local h = HudLayout.touchHotbar(width, height)
		assert(h.rows == 1 and h.columns == 10, "uma linha")
		assert(h.width == 10 * 44 + 9 * 4, "largura da linha compacta")
		local aimLeft = width - HudLayout.MARGIN - HudLayout.aimSize(height)
		assert(rightOf(h) <= aimLeft - HudLayout.MARGIN, "não encosta no joystick de mirar")
		assert(leftOf(h) >= HudLayout.MOVE_RESERVE, "não encosta no joystick de andar")
	end,

	["small phone: two rows of five"] = function()
		local h = HudLayout.touchHotbar(667, 317)
		assert(h.rows == 2 and h.columns == 5, "duas linhas")
		assert(h.width == 5 * 44 + 4 * 4, "largura de 5")
		assert(h.height == 2 * 44 + 4, "altura de 2 linhas")
		assert(rightOf(h) <= 667 - HudLayout.MARGIN - HudLayout.aimSize(317) - HudLayout.MARGIN, "cabe no vão")
	end,

	["tablet: one row, centred on the screen"] = function()
		local h = HudLayout.touchHotbar(1024, 710)
		assert(h.rows == 1, "uma linha")
		assert(h.centerX == 512, "no centro da tela")
	end,

	["slot never shrinks below the touch minimum"] = function()
		for _, size in { { 568, 300 }, { 667, 317 }, { 749, 330 }, { 932, 372 }, { 1366, 960 } } do
			local h = HudLayout.touchHotbar(size[1], size[2])
			assert(h.slot >= 44, `slot pequeno em {size[1]}x{size[2]}`)
		end
	end,

	["aim stick size stays between min and max"] = function()
		assert(HudLayout.aimSize(330) == HudLayout.AIM_MIN, "celular: mínimo")
		assert(HudLayout.aimSize(2000) == HudLayout.AIM_MAX, "tela enorme: máximo")
		assert(HudLayout.aimSize(600) == 132, "meio: fração")
	end,

	["panels start above the rings"] = function()
		local _, ringHeight = HudLayout.ringsSize()
		assert(ringHeight == 55, "anel de 55 com slot de 44")
		assert(HudLayout.panelLift() == HudLayout.RINGS_LIFT + 55 + HudLayout.PANEL_GAP, "acima dos anéis")
	end,
	["recipe column starts below the score pill on phones"] = function()
		-- Placa do placar (uma linha, do tamanho do antigo selo): 6,6 + 38.
		local bottom = HudLayout.scorePillBottom(749, 330)
		assert(math.abs(bottom - 44.6) < 0.5, `base do placar: {bottom}`)
		assert(HudLayout.craftTop(749, 330) >= bottom + 8, "coluna encosta no selo")
	end,
	["recipe column stays where it was on pc"] = function()
		assert(HudLayout.craftTop(1280, 720) == 0.12 * 720, "PC igual")
	end,
}
