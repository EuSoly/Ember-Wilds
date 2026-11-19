--!strict
local HudColumn = require("../src/shared/UIFlow/HudColumn")

return {
	["nothing showing: notifications at their usual place"] = function()
		local c = HudColumn.compute(0, 0)
		assert(c.notificationsY == HudColumn.NOTIFICATIONS_ALONE, "lugar de sempre")
	end,

	["tutorial only: pinned slot and notifications go below it"] = function()
		local c = HudColumn.compute(0.1, 0)
		assert(c.tutorialY == HudColumn.TOP, "tutorial no topo da coluna")
		assert(math.abs(c.notificationsY - (HudColumn.TOP + 0.1 + HudColumn.GAP)) < 1e-9, "avisos embaixo do tutorial")
	end,

	["pinned only: it takes the top"] = function()
		local c = HudColumn.compute(0, 0.12)
		assert(c.pinnedY == HudColumn.TOP, "fixado no topo")
		assert(math.abs(c.notificationsY - (HudColumn.TOP + 0.12 + HudColumn.GAP)) < 1e-9, "avisos embaixo")
	end,

	["both: tutorial, then pinned, then notifications"] = function()
		local c = HudColumn.compute(0.1, 0.12)
		assert(c.tutorialY == HudColumn.TOP, "tutorial primeiro")
		assert(math.abs(c.pinnedY - (HudColumn.TOP + 0.1 + HudColumn.GAP)) < 1e-9, "fixado depois")
		assert(math.abs(c.notificationsY - (c.pinnedY + 0.12 + HudColumn.GAP)) < 1e-9, "avisos no fim")
	end,

	["short screens get a minimum height in pixels"] = function()
		local phone = 330
		assert(HudColumn.tutorialHeight(false, phone) * phone >= HudColumn.TUTORIAL_MIN_PX - 1e-6, "tutorial baixo")
		assert(
			HudColumn.tutorialHeight(true, phone) * phone >= HudColumn.TUTORIAL_NEEDS_MIN_PX - 1e-6,
			"tutorial com itens baixo"
		)
		assert(HudColumn.pinnedHeight(2, phone) * phone >= 28 + 2 * 24 + 10 - 1e-6, "fixado baixo")
		-- Tela grande: as frações de sempre, mais os rolos do pergaminho.
		local pc = 1022
		local rolls = HudColumn.scrollExtra(pc) / pc
		assert(math.abs(HudColumn.tutorialHeight(false, pc) - (HudColumn.TUTORIAL_HEIGHT + rolls)) < 1e-9, "PC mudou")
		assert(
			math.abs(HudColumn.tutorialHeight(true, pc) - (HudColumn.TUTORIAL_HEIGHT_NEEDS + rolls)) < 1e-9,
			"PC mudou"
		)
		assert(math.abs(HudColumn.pinnedHeight(2, pc) - (HudColumn.pinnedHeight(2) + rolls)) < 1e-9, "PC mudou")
	end,

	["pinned panel height grows with the ingredients and stations"] = function()
		assert(HudColumn.pinnedHeight(0) == 0, "sem receita fixada: 0")
		assert(HudColumn.pinnedHeight(3) > HudColumn.pinnedHeight(1), "mais itens, mais alto")
		assert(HudColumn.pinnedHeight(4) > HudColumn.pinnedHeight(3), "ingredientes + estação somam linhas")
	end,

	["column starts where it is told (below the round buttons)"] = function()
		local c = HudColumn.compute(0, 0.12, 0.5)
		assert(c.tutorialY == 0.5 and c.pinnedY == 0.5, "começa no topo dado")
		assert(c.notificationsY > 0.5 + 0.12, "avisos embaixo da receita")
		local alone = HudColumn.compute(0, 0, 0.5)
		assert(alone.notificationsY >= 0.5, "sozinhos, os avisos não sobem por cima dos botões")
	end,

	["scroll panels leave room for both rolls and the text"] = function()
		-- Pergaminho (arte 29, 400x600): partes fixas de 112 px em cima e 94 embaixo.
		for _, h in { 330, 375, 720, 1022 } do
			local scale = HudColumn.scrollScale(h)
			local fixed = (HudColumn.SCROLL_SLICE_TOP + HudColumn.SCROLL_SLICE_BOTTOM) * scale
			local textPad = (HudColumn.SCROLL_TEXT_TOP + HudColumn.SCROLL_TEXT_BOTTOM) * scale
			assert(HudColumn.scrollExtra(h) >= fixed, `{h}: rolos amassados`)
			-- O texto continua com a altura mínima de antes, fora dos rolos.
			local tutorial = HudColumn.tutorialHeight(false, h) * h
			assert(tutorial - textPad >= HudColumn.TUTORIAL_MIN_PX - 1e-6, `{h}: texto do tutorial apertado`)
			local pinned = HudColumn.pinnedHeight(1, h) * h
			assert(pinned - textPad >= 28 + 24 - 1e-6, `{h}: texto da receita apertado`)
		end
		assert(HudColumn.scrollScale(330) < HudColumn.scrollScale(1022), "rolos mais finos no celular")
	end,

	["side by side: pinned next to the tutorial, notifications below the taller"] = function()
		-- Celular (18/11/2026): empilhados, a receita descia até o joystick de andar.
		local c = HudColumn.compute(0.3, 0.2, 0.15, true)
		assert(c.pinnedBeside, "receita ao lado")
		assert(c.pinnedY == c.tutorialY, "mesma altura do tutorial")
		assert(math.abs(c.notificationsY - (0.15 + 0.3 + HudColumn.GAP)) < 1e-9, "avisos embaixo do mais alto")
		-- Sem o tutorial, a receita fica no topo da coluna.
		local alone = HudColumn.compute(0, 0.2, 0.15, true)
		assert(not alone.pinnedBeside and alone.pinnedY == 0.15, "sozinha no topo")
		-- PC: empilhados como sempre.
		local pc = HudColumn.compute(0.1, 0.12)
		assert(not pc.pinnedBeside, "PC empilha")
	end,
}
