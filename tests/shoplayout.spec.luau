--!strict
local ShopLayout = require("../src/shared/UIFlow/ShopLayout")

local SIZES = { { 1920, 1080 }, { 1280, 720 }, { 844, 390 }, { 667, 375 }, { 568, 320 } }
local GAP = ShopLayout.GAP

local function cardWidth(l: ShopLayout.Layout, columns: number): number
	return (l.contentWidth - (columns - 1) * GAP) / columns
end

return {
	["content fits the screen"] = function()
		for _, size in SIZES do
			local w, h = size[1], size[2]
			local l = ShopLayout.compute(w, h)
			assert(l.contentX >= 8 and l.contentX + l.contentWidth <= w - 8, `{w}x{h}: conteúdo fora da largura`)
			assert(l.contentTop >= l.top + l.topHeight, `{w}x{h}: conteúdo por cima do topo`)
			assert(l.contentTop < h - 8, `{w}x{h}: sem lugar para o conteúdo`)
		end
	end,

	["top bar has touch-size controls and room for the tabs"] = function()
		for _, size in SIZES do
			local w, h = size[1], size[2]
			local l = ShopLayout.compute(w, h)
			assert(l.topHeight >= 44 and l.backWidth >= 44, `{w}x{h}: topo menor que o toque`)
			assert(l.tabsWidth >= 4 * 44, `{w}x{h}: abas sem lugar ({l.tabsWidth})`)
			assert(l.tabsX + l.tabsWidth <= l.balanceLeft - 8, `{w}x{h}: abas por cima do saldo`)
			assert(l.tabsX >= l.barX + l.backWidth + l.titleWidth, `{w}x{h}: abas por cima do voltar/título`)
		end
	end,

	["cards stay readable"] = function()
		for _, size in SIZES do
			local w, h = size[1], size[2]
			local l = ShopLayout.compute(w, h)
			assert(cardWidth(l, l.passColumns) >= 120, `{w}x{h}: gamepass estreito`)
			assert(cardWidth(l, l.spinColumns) >= 120, `{w}x{h}: giro estreito`)
			assert(
				cardWidth(l, l.emberTop) >= 120 and cardWidth(l, l.emberBottom) >= 120,
				`{w}x{h}: Golden Ember estreito`
			)
			assert(l.bannerHeight >= 120, `{w}x{h}: banner baixo`)
		end
	end,

	["compact uses fewer columns"] = function()
		local pc, phone = ShopLayout.compute(1280, 720), ShopLayout.compute(667, 375)
		assert(not pc.compact and phone.compact, "compacto errado")
		assert(
			pc.passColumns == 5 and pc.spinColumns == 4 and pc.emberTop == 3 and pc.emberBottom == 2,
			"colunas do PC"
		)
		-- 4 tipos de giro (sem Acessórios desde 10/11/2026): uma fileira no PC e
		-- no celular largo; 2x2 só no estreito.
		assert(phone.spinColumns == 4, "giros numa fileira no celular largo")
		assert(ShopLayout.compute(568, 320).spinColumns == 2, "giros 2x2 no celular estreito")
		assert(phone.passColumns < pc.passColumns, "celular devia ter menos colunas")
		assert(phone.titleWidth == 0, "celular sem a placa LOJA")
	end,

	["big screens keep the shop at a comfortable width"] = function()
		local l = ShopLayout.compute(1920, 1080)
		assert(l.contentWidth <= ShopLayout.CONTENT_MAX, `conteúdo largo demais: {l.contentWidth}`)
		assert(math.abs(l.contentX - (1920 - l.contentWidth) / 2) < 1, "conteúdo devia ficar centralizado")
		assert(l.tabsWidth <= ShopLayout.TABS_MAX, `abas largas demais: {l.tabsWidth}`)
		local small = ShopLayout.compute(1024, 640)
		assert(small.contentWidth == 1024 - 16, "em 1024 a loja usa a largura toda")
	end,

	["spin type cards fit under the section title"] = function()
		for _, size in SIZES do
			local w, h = size[1], size[2]
			local l = ShopLayout.compute(w, h)
			local listHeight = h - l.contentTop - ShopLayout.MARGIN
			if l.compact then
				assert(
					l.spinCardHeight + ShopLayout.SECTION_TITLE <= listHeight
						or l.spinCardHeight == ShopLayout.SPIN_CARD_MIN,
					`{w}x{h}: cartão de giro passa da lista ({l.spinCardHeight} em {listHeight})`
				)
			end
			assert(l.spinCardHeight >= ShopLayout.SPIN_CARD_MIN, `{w}x{h}: cartão de giro baixo demais`)
		end
		assert(ShopLayout.compute(1280, 720).spinCardHeight == ShopLayout.SPIN_CARD_HEIGHT, "PC mantém 360")
	end,

	["spin screen sides always side by side"] = function()
		for _, size in SIZES do
			assert(ShopLayout.compute(size[1], size[2]).spinSideBySide, `{size[1]}x{size[2]}: lados empilhados`)
		end
	end,

	["spin screen fits without scrolling"] = function()
		for _, size in SIZES do
			local w, h = size[1], size[2]
			local l = ShopLayout.compute(w, h)
			local used = l.spinBoxTop
				+ ShopLayout.SPIN_PADDING * 2
				+ l.spinTitleRow
				+ l.spinTile
				+ ShopLayout.SPIN_REEL_EXTRA
				+ ShopLayout.SPIN_GAP * 2
				+ l.spinSideHeight
			assert(used <= h - ShopLayout.MARGIN, `{w}x{h}: tela do giro não cabe ({used} > {h - ShopLayout.MARGIN})`)
			local minimum = if l.compact then ShopLayout.SPIN_SIDE_MIN_COMPACT else ShopLayout.SPIN_SIDE_MIN
			assert(l.spinSideHeight >= minimum, `{w}x{h}: lado baixo demais ({l.spinSideHeight})`)
			assert(l.spinTile >= 48, `{w}x{h}: quadradinho pequeno demais`)
		end
	end,

	["phone pages fit the screen"] = function()
		for _, size in { { 749, 330 }, { 844, 390 }, { 667, 375 }, { 599, 264 } } do
			local w, h = size[1], size[2]
			local l = ShopLayout.compute(w, h)
			assert(l.paged, `{w}x{h}: devia paginar`)
			assert(l.contentTop + ShopLayout.SECTION_TITLE + l.pageHeight <= h - 8, `{w}x{h}: página passa da tela`)
			assert(l.bannerHeight == l.pageHeight, `{w}x{h}: banner devia ocupar a página`)
			-- 5 gamepasses hoje (4 kits para sempre + VIP).
			local cols, cardHeight = ShopLayout.passGrid(l, 5)
			local rows = math.ceil(5 / cols)
			assert(rows * cardHeight + (rows - 1) * GAP <= l.pageHeight, `{w}x{h}: gamepasses passam da página`)
			assert(cardHeight >= 120, `{w}x{h}: cartão de gamepass baixo demais ({cardHeight})`)
			assert(ShopLayout.emberCardHeight(l) <= l.pageHeight, `{w}x{h}: Golden Ember passa da página`)
		end
	end,

	["phone passes: one row of 5 at 749"] = function()
		local cols = ShopLayout.passGrid(ShopLayout.compute(749, 330), 5)
		assert(cols == 5, `5 colunas, veio {cols}`)
	end,

	["pc shop unchanged"] = function()
		local l = ShopLayout.compute(1280, 720)
		assert(not l.paged, "PC não pagina")
		local cols, cardHeight = ShopLayout.passGrid(l, 4)
		assert(cols == 5 and cardHeight == 236, "grade do PC")
	end,

	["pc passes with a top row keep the fixed height"] = function()
		local l = ShopLayout.compute(1280, 720)
		local cols, h = ShopLayout.passGrid(l, 6, ShopLayout.topRowHeight(l))
		assert(cols == 5 and h == ShopLayout.PASS_CARD_HEIGHT, "PC ignora a fileira reservada")
	end,

	["phone passes tab fits the page without scrolling"] = function()
		-- Fileira de cima + espaço + grade (VIP, boost, Premium + 4 kits + 2× + livro).
		for _, size in { { 749, 330 }, { 844, 390 }, { 667, 375 }, { 599, 264 } } do
			local w, h = size[1], size[2]
			local l = ShopLayout.compute(w, h)
			assert(l.paged, "celular pagina")
			local top = ShopLayout.topRowHeight(l)
			assert(top == ShopLayout.TOP_ROW_HEIGHT_COMPACT, "fileira baixa no celular")
			local cols, cardHeight = ShopLayout.passGrid(l, 6, top)
			local rows = math.ceil(6 / cols)
			assert(rows == 1, `{w}x{h}: gamepasses numa fileira só ({rows})`)
			local used = top + GAP + rows * cardHeight + (rows - 1) * GAP
			assert(used <= l.pageHeight, `{w}x{h}: aba passa da página ({used} > {l.pageHeight})`)
			assert(cardHeight >= 80, `{w}x{h}: cartão baixo demais ({cardHeight})`)
			assert((l.contentWidth - (cols - 1) * GAP) / cols >= ShopLayout.PASS_MIN_WIDTH, `{w}x{h}: cartão estreito`)
		end
	end,

	["top row weights hide premium slot"] = function()
		local vip, boost, premium = ShopLayout.topRowWeights(true)
		assert(vip == 2 and boost == 1 and premium == 1, "com Premium")
		local _, _, none = ShopLayout.topRowWeights(false)
		assert(none == 0, "sem Premium, o peso some")
	end,
}
