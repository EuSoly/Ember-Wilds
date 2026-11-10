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
		-- Tela grande: as frações de sempre.
		assert(HudColumn.tutorialHeight(false, 1022) == HudColumn.TUTORIAL_HEIGHT, "PC mudou")
		assert(HudColumn.tutorialHeight(true, 1022) == HudColumn.TUTORIAL_HEIGHT_NEEDS, "PC mudou")
		assert(HudColumn.pinnedHeight(2, 1022) == HudColumn.pinnedHeight(2), "PC mudou")
	end,

	["pinned panel height grows with the ingredients"] = function()
		assert(HudColumn.pinnedHeight(0) == 0, "sem receita fixada: 0")
		assert(HudColumn.pinnedHeight(3) > HudColumn.pinnedHeight(1), "mais itens, mais alto")
	end,
}
