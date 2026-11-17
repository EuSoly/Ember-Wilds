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
			-- Compacto: 40 de altura, exceção pedida pelo Elizeu (17/11/2026) para
			-- os 6 botões caberem no celular deitado.
			local minButton = if l.compact then 40 else 44
			assert(l.buttonHeight >= minButton, "buttons below touch min")
			local expected = MenuLayout.NAV_COUNT * l.buttonHeight + (MenuLayout.NAV_COUNT - 1) * l.buttonGap
			assert(l.columnContentHeight == expected, "content height ignores the gap")
		end)
		-- No menor caso de PC (800x400) os 6 botões ainda cabem sem rolar.
		assert(not MenuLayout.compute(800, 400).columnScrolls, "800x400 should fit")
	end,
	["phone sizes fit the column without scrolling"] = function()
		for _, s in { { 749, 330 }, { 844, 390 }, { 667, 375 } } do
			local l = MenuLayout.compute(s[1], s[2])
			assert(not l.columnScrolls, `{s[1]}x{s[2]}: coluna rola`)
			assert(l.buttonHeight == 40, `{s[1]}x{s[2]}: botão compacto`)
		end
		assert(MenuLayout.compute(749, 330).bodyTop == 64, "corpo começa em 64 no celular")
	end,
	["small phone and big ui scale keep the column inside"] = function()
		for _, s in { { 568, 320 }, { 599, 264 } } do
			local w, h = s[1], s[2]
			local l = MenuLayout.compute(w, h)
			assert(l.columnBottom <= h, `{w}x{h}: coluna sai por baixo`)
			assert(l.bodyTop >= l.podBottom, `{w}x{h}: coluna por cima dos pods`)
		end
	end,
	["ranking starts at the top on phones"] = function()
		assert(MenuLayout.compute(749, 330).rankingTop == 8, "celular: do topo")
		local pc = MenuLayout.compute(1280, 720)
		assert(pc.rankingTop == pc.bodyTop, "PC: abaixo dos pods")
		eachSize(function(w, h, l)
			assert(l.rankingTop < l.panelBottom, `{w}x{h}: ranking sem altura`)
		end)
	end,
	["kits start at the top on phones"] = function()
		local phone = MenuLayout.compute(749, 330, true)
		assert(phone.kitPanelTop == 8, "celular: kits do topo")
		local pc = MenuLayout.compute(1280, 720, true)
		assert(pc.kitPanelTop == pc.bodyTop, "PC: kits abaixo dos pods")
		-- O aviso de compra fica dentro do painel, abaixo do título e do fechar.
		assert(phone.noticeY >= phone.kitPanelTop + MenuLayout.KIT_HEADER_HEIGHT, "aviso por cima do título dos kits")
	end,
	["pc keeps the old sizes"] = function()
		local l = MenuLayout.compute(1280, 720)
		assert(l.podHeight == 56, "pod do PC")
		assert(l.buttonHeight == 52, "botão do PC")
		assert(l.buttonGap == 4, "espaço do PC")
		assert(l.bodyTop == MenuLayout.BODY_TOP, "corpo do PC")
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
			assert(l.actionsX >= left, `{w}x{h}: buttons over the column`)
			assert(l.actionsX + l.actionsWidth <= w - MenuLayout.MARGIN, `{w}x{h}: buttons off the right`)
		end)
	end,
	["hero and play button are centered on the screen when there is room"] = function()
		for _, size in { { 1920, 1080 }, { 1280, 720 }, { 1128, 793 } } do
			local w = size[1]
			local l = MenuLayout.compute(w, size[2])
			assert(l.heroCenterX == w / 2, `{w}: boneco no centro ({l.heroCenterX})`)
			local playCenter = l.actionsX + l.kitsButtonWidth + l.actionsGap + l.playButtonWidth / 2
			assert(math.abs(playCenter - w / 2) < 1e-6, `{w}: JOGAR no centro ({playCenter})`)
		end
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
			assert(l.actionsX + l.actionsWidth <= l.kitPanelX, `{size[1]}: buttons under the kits`)
		end
	end,
	["notice never covers the kits header"] = function()
		for _, size in SIZES do
			local w, h = size[1], size[2]
			local l = MenuLayout.compute(w, h, true)
			local left, right = l.noticeCenterX - l.noticeWidth / 2, l.noticeCenterX + l.noticeWidth / 2
			local top, bottom = l.noticeY, l.noticeY + MenuLayout.NOTICE_HEIGHT
			local headerBottom = l.kitPanelTop + MenuLayout.KIT_HEADER_HEIGHT
			local overlapsX = left < l.kitPanelX + l.kitPanelWidth and right > l.kitPanelX
			local overlapsY = top < headerBottom and bottom > l.kitPanelTop
			assert(not (overlapsX and overlapsY), `{w}x{h}: aviso cobre o título/fechar dos kits`)
			assert(left >= 0 and right <= w and bottom <= h, `{w}x{h}: aviso fora da tela`)
			assert(l.noticeWidth > 0, `{w}x{h}: aviso sem largura`)
		end
	end,

	["logo is bigger on desktop and fits between the pods"] = function()
		assert(
			MenuLayout.compute(1920, 1080).logoHeight > MenuLayout.compute(667, 375).logoHeight,
			"logo do PC devia ser maior"
		)
		for _, size in SIZES do
			local w, h = size[1], size[2]
			local l = MenuLayout.compute(w, h)
			local logoWidth = l.logoHeight * MenuLayout.LOGO_ASPECT
			assert(w / 2 - logoWidth / 2 >= l.columnX + l.podWidth, `{w}x{h}: logo encosta no pod do nível`)
			assert(w / 2 + logoWidth / 2 <= w - MenuLayout.MARGIN - l.podWidth, `{w}x{h}: logo encosta no saldo`)
		end
	end,

	["notice sits below the logo"] = function()
		for _, size in SIZES do
			local w, h = size[1], size[2]
			local l = MenuLayout.compute(w, h)
			assert(l.noticeY >= l.logoTop + l.logoHeight, `{w}x{h}: aviso por cima do logo`)
			assert(
				l.noticeY + MenuLayout.NOTICE_HEIGHT <= l.heroBottom - l.heroSize + 40,
				`{w}x{h}: aviso muito em cima do boneco`
			)
		end
	end,

	["pods have a readable width"] = function()
		for _, size in SIZES do
			local l = MenuLayout.compute(size[1], size[2])
			assert(l.podWidth >= MenuLayout.POD_MIN and l.podWidth <= MenuLayout.POD_MAX, `pod com {l.podWidth}`)
		end
	end,

	["compact kits cover the hero"] = function()
		assert(MenuLayout.compute(667, 375, true).kitsCoverHero, "667x375 should cover")
		assert(not MenuLayout.compute(667, 375, false).kitsCoverHero, "closed kits cover nothing")
	end,
}
