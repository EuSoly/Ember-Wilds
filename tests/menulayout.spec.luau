--!strict
local MenuLayout = require("../src/shared/UIFlow/MenuLayout")

-- Telas do critério de aceite do design system (PC, notebook, celulares deitados).
local SIZES = { { 800, 400 }, { 1130, 793 }, { 1920, 1080 }, { 1280, 720 }, { 844, 390 }, { 667, 375 }, { 568, 320 } }

local function eachSize(check: (w: number, h: number, l: MenuLayout.Layout) -> ())
	for _, size in SIZES do
		check(size[1], size[2], MenuLayout.compute(size[1], size[2]))
		check(size[1], size[2], MenuLayout.compute(size[1], size[2], true))
	end
end

return {
	["pods end above the body"] = function()
		eachSize(function(_, _, l)
			assert(l.podBottom <= l.bodyTop, "pods overlap the body")
			assert(l.podTop >= 0, "pod above the screen")
		end)
	end,
	["column and panels end inside the screen"] = function()
		eachSize(function(w, h, l)
			assert(l.columnBottom <= h and l.panelBottom <= h, "runs off the bottom")
			assert(l.columnBottom > l.bodyTop and l.panelBottom > l.contentTop, "no room left")
			assert(l.panelX + l.panelWidth <= w, "panel runs off the right")
			assert(l.panelX >= l.columnX + l.columnWidth, "panel overlaps the column")
		end)
	end,
	["column buttons fit at touch min or the column scrolls"] = function()
		eachSize(function(_, _, l)
			local room = l.columnBottom - l.bodyTop
			assert(l.columnScrolls == (l.columnContentHeight > room), "scroll flag wrong")
			assert(l.buttonHeight >= 44, "buttons below touch min")
			assert(l.columnContentHeight >= MenuLayout.NAV_COUNT * 44, "buttons below touch min")
		end)
		-- No menor caso de PC (800x400) os 6 botões ainda cabem sem rolar.
		assert(not MenuLayout.compute(800, 400).columnScrolls, "800x400 should fit")
	end,
	["title row holds a touch-size close button"] = function()
		assert(MenuLayout.TITLE_ROW >= 44, "title row too short")
	end,
	["tiny screens scroll the column instead of overflowing"] = function()
		assert(MenuLayout.compute(800, 300).columnScrolls, "300 high should scroll")
	end,
	["compact by width or height"] = function()
		assert(MenuLayout.compute(899, 700).compact, "899 wide is compact")
		assert(MenuLayout.compute(1280, 499).compact, "499 high is compact")
		assert(not MenuLayout.compute(1280, 720).compact, "1280x720 is not compact")
	end,
	["hero and actions stay inside the play area"] = function()
		eachSize(function(w, h, l)
			local left = l.columnX + l.columnWidth
			assert(l.heroSize > 0, `{w}x{h}: hero has no room`)
			assert(l.heroCenterX - l.heroSize / 2 >= left, `{w}x{h}: hero over the column`)
			assert(l.heroBottom <= l.actionsY, `{w}x{h}: hero over the buttons`)
			assert(l.heroBottom - l.heroSize >= l.bodyTop, `{w}x{h}: hero under the pods`)
			assert(l.actionsY + l.actionsHeight <= h - MenuLayout.MARGIN, `{w}x{h}: buttons off the bottom`)
			assert(l.actionsHeight >= 44, `{w}x{h}: buttons below touch min`)
			assert(l.heroCenterX - l.actionsWidth / 2 >= left, `{w}x{h}: buttons over the column`)
			assert(l.heroCenterX + l.actionsWidth / 2 <= w - MenuLayout.MARGIN, `{w}x{h}: buttons off the right`)
		end)
	end,
	["kits panel never overlaps the column and fits"] = function()
		eachSize(function(w, h, l)
			assert(l.kitPanelX >= l.columnX + l.columnWidth, `{w}x{h}: kits over the column`)
			assert(l.kitPanelX + l.kitPanelWidth <= w - MenuLayout.MARGIN, `{w}x{h}: kits off the right`)
			assert(l.kitPanelWidth >= 280, `{w}x{h}: kits too narrow ({l.kitPanelWidth})`)
		end)
	end,
	["desktop kits keep the hero and buttons visible"] = function()
		for _, size in { { 1920, 1080 }, { 1280, 720 } } do
			local l = MenuLayout.compute(size[1], size[2], true)
			assert(not l.kitsCoverHero, `{size[1]}: kits should not cover the hero`)
			assert(l.heroCenterX + l.heroSize / 2 <= l.kitPanelX, `{size[1]}: hero under the kits`)
			assert(l.heroCenterX + l.actionsWidth / 2 <= l.kitPanelX, `{size[1]}: buttons under the kits`)
		end
	end,
	["notice never covers the kits header"] = function()
		for _, size in SIZES do
			local w, h = size[1], size[2]
			local l = MenuLayout.compute(w, h, true)
			local left, right = l.noticeCenterX - l.noticeWidth / 2, l.noticeCenterX + l.noticeWidth / 2
			local top, bottom = l.noticeY, l.noticeY + MenuLayout.NOTICE_HEIGHT
			local headerBottom = l.bodyTop + MenuLayout.KIT_HEADER_HEIGHT
			local overlapsX = left < l.kitPanelX + l.kitPanelWidth and right > l.kitPanelX
			local overlapsY = top < headerBottom and bottom > l.bodyTop
			assert(not (overlapsX and overlapsY), `{w}x{h}: aviso cobre o título/fechar dos kits`)
			assert(left >= 0 and right <= w and bottom <= h, `{w}x{h}: aviso fora da tela`)
			assert(l.noticeWidth > 0, `{w}x{h}: aviso sem largura`)
		end
	end,

	["compact kits cover the hero"] = function()
		assert(MenuLayout.compute(667, 375, true).kitsCoverHero, "667x375 should cover")
		assert(not MenuLayout.compute(667, 375, false).kitsCoverHero, "closed kits cover nothing")
	end,
}
