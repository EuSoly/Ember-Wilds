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
		assert(cols == 6 and h == ShopLayout.PASS_CARD_HEIGHT, "PC ignora a fileira reservada")
	end,

	["pc passes: the 6 cards fit one row"] = function()
		-- Teste no Studio de 17/11/2026 (1128×793): 4 kits + 2× + livro iam para 2 fileiras.
		for _, size in { { 1128, 793 }, { 1024, 640 }, { 1280, 720 }, { 1920, 1080 } } do
			local w, h = size[1], size[2]
			local l = ShopLayout.compute(w, h)
			assert(not l.paged, `{w}x{h}: PC não pagina`)
			local cols, cardHeight = ShopLayout.passGrid(l, 6, ShopLayout.topRowHeight(l))
			assert(cols == 6, `{w}x{h}: 6 numa fileira, veio {cols}`)
			assert(cardHeight == ShopLayout.PASS_CARD_HEIGHT, `{w}x{h}: altura do PC`)
			assert(cardWidth(l, cols) >= ShopLayout.PASS_MIN_WIDTH_PC, `{w}x{h}: cartão estreito`)
		end
		-- Com até 5 cartões o PC continua com as 5 colunas de antes.
		local cols = ShopLayout.passGrid(ShopLayout.compute(1128, 793), 4)
		assert(cols == 5, "4 cartões: 5 colunas")
	end,

	["pc tab fits 1128x793 without scrolling"] = function()
		local l = ShopLayout.compute(1128, 793)
		local _, cardHeight = ShopLayout.passGrid(l, 6, ShopLayout.topRowHeight(l))
		local used = l.contentTop + ShopLayout.SECTION_TITLE + ShopLayout.topRowHeight(l) + GAP + cardHeight
		assert(used <= 793 - ShopLayout.MARGIN, `aba de gamepasses passa da tela ({used})`)
	end,

	["top row widths add up the row"] = function()
		for _, shown in { true, false } do
			local vip, boost, premium = ShopLayout.topRowWidths(1000, shown)
			local count = if shown then 3 else 2
			assert(math.abs(vip + boost + premium + GAP * (count - 1) - 1000) < 0.01, "soma da fileira")
			assert(vip > boost, "VIP maior")
			assert((premium == 0) == not shown, "Premium some sem o cartão")
		end
	end,

	["pc banners: readable text, nothing overlaps"] = function()
		local function inside(b: ShopLayout.Box, w: number, h: number): boolean
			return b.x >= 0 and b.y >= 0 and b.x + b.w <= w + 0.01 and b.y + b.h <= h + 0.01
		end
		local function apart(a: ShopLayout.Box, b: ShopLayout.Box): boolean
			return a.x + a.w <= b.x + 0.01
				or b.x + b.w <= a.x + 0.01
				or a.y + a.h <= b.y + 0.01
				or b.y + b.h <= a.y + 0.01
		end
		for _, size in { { 1128, 793 }, { 1024, 640 }, { 1280, 720 }, { 1920, 1080 } } do
			local l = ShopLayout.compute(size[1], size[2])
			local height = ShopLayout.topRowHeight(l)
			-- A lista tem 10 px de folga à direita (ShopScreen).
			for _, shown in { true, false } do
				local widths = { ShopLayout.topRowWidths(l.contentWidth - 10, shown) }
				for slot, width in widths do
					if width > 0 then
						local parts = ShopLayout.bannerParts(width, height, false)
						local tag = `{size[1]}x{size[2]} cartão {slot}`
						local icon = parts.icon
						assert(icon ~= nil, `{tag}: PC tem ícone`)
						-- Título (≥ 18 px) e descrição em 2 linhas (≥ 13 px) cabem na coluna.
						assert(parts.text.w >= 150, `{tag}: coluna de texto estreita ({parts.text.w})`)
						assert(parts.text.h >= 80, `{tag}: coluna de texto baixa ({parts.text.h})`)
						assert(parts.button.w >= 88 and parts.button.h >= 40, `{tag}: botão pequeno`)
						for _, b in { icon, parts.text, parts.button } do
							assert(inside(b, width, height), `{tag}: peça fora do cartão`)
						end
						assert(apart(icon, parts.text) and apart(icon, parts.button), `{tag}: ícone por cima`)
						assert(apart(parts.text, parts.button), `{tag}: texto por cima do botão`)
					end
				end
			end
		end
	end,

	["phone banners keep the low strip"] = function()
		for _, size in { { 749, 330 }, { 599, 264 }, { 667, 375 } } do
			local l = ShopLayout.compute(size[1], size[2])
			local height = ShopLayout.topRowHeight(l)
			for _, width in { ShopLayout.topRowWidths(l.contentWidth - 10, true) } do
				local parts = ShopLayout.bannerParts(width, height, true)
				assert(parts.icon == nil and not parts.stacked, "celular: faixa sem ícone")
				assert(parts.text.x + parts.text.w <= parts.button.x, "texto antes do botão")
				assert(parts.button.y + parts.button.h <= height, "botão dentro da faixa")
			end
		end
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

	["pass cards: texts inside the frame, desc two lines or none"] = function()
		local function inside(b: ShopLayout.Box, w: number, h: number): boolean
			return b.x >= 0 and b.y >= 0 and b.x + b.w <= w + 0.01 and b.y + b.h <= h + 0.01
		end
		local function below(a: ShopLayout.Box, b: ShopLayout.Box): boolean
			return a.y + a.h <= b.y + 0.01
		end
		for _, size in
			{ { 1128, 793 }, { 1024, 640 }, { 1920, 1080 }, { 844, 390 }, { 749, 330 }, { 667, 375 }, { 599, 264 } }
		do
			local w, h = size[1], size[2]
			local l = ShopLayout.compute(w, h)
			local cols, cardH = ShopLayout.passGrid(l, 6, ShopLayout.topRowHeight(l))
			-- A lista tem 10 px de folga à direita (ShopScreen).
			local cardW = (l.contentWidth - 10 - (cols - 1) * GAP) / cols
			local parts = ShopLayout.passCardParts(cardW, cardH)
			local tag = `{w}x{h} ({math.floor(cardW)}x{math.floor(cardH)})`
			local inset = ShopLayout.passInset(cardW)
			assert(inset >= 8, `{tag}: texto sem recuo`)
			for _, b in { parts.name, parts.button } do
				assert(inside(b, cardW, cardH), `{tag}: peça fora do cartão`)
			end
			assert(
				parts.name.x >= inset - 0.01 and parts.name.x + parts.name.w <= cardW - inset + 0.01,
				`{tag}: nome na moldura`
			)
			assert(parts.name.h >= 18, `{tag}: nome baixo ({parts.name.h})`)
			assert(below(parts.name, parts.button), `{tag}: nome por cima do botão`)
			local icon = parts.icon
			if icon then
				assert(inside(icon, cardW, cardH) and below(icon, parts.name), `{tag}: ícone`)
			end
			local desc = parts.desc
			if desc then
				assert(desc.h >= ShopLayout.PASS_DESC_MIN, `{tag}: descrição sem duas linhas`)
				assert(below(parts.name, desc) and below(desc, parts.button), `{tag}: descrição fora do lugar`)
				assert(
					desc.x >= inset - 0.01 and desc.x + desc.w <= cardW - inset + 0.01,
					`{tag}: descrição na moldura`
				)
			end
			if not l.paged then
				assert(desc ~= nil and icon ~= nil, `{tag}: PC com ícone e descrição`)
			end
		end
	end,
}
