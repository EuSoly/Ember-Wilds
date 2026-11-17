--!strict
-- Medidas da Loja em tela cheia (pixels lógicos), sem depender do Roblox para
-- poder ser testada. Topo: voltar, placa LOJA (some no celular) e as abas,
-- deixando livre o card da Golden Ember do canto (MenuShell). Abaixo, a lista
-- de seções com o número de colunas de cada grade: menos colunas no compacto.
local MenuLayout = require("./MenuLayout")

local ShopLayout = {}

ShopLayout.MARGIN = 8
ShopLayout.GAP = 8 -- entre cartões e entre peças do topo
ShopLayout.BACK_WIDTH = 120
ShopLayout.BACK_WIDTH_COMPACT = 88
ShopLayout.TITLE_WIDTH = 140
-- Em telas grandes a loja não se estica até as bordas: o conteúdo para nesta
-- largura (centralizado) e as abas nesta.
ShopLayout.CONTENT_MAX = 1120
ShopLayout.TABS_MAX = 640
-- Tela do giro: no celular ela sobe até o topo (fica por cima de tudo) e usa
-- título e quadradinhos menores, para os dois lados caberem sem rolar.
ShopLayout.SPIN_PADDING = 10
ShopLayout.SPIN_GAP = 8
ShopLayout.SPIN_REEL_EXTRA = 20 -- a janela do carrossel = quadradinho + isto
ShopLayout.SPIN_SIDES_PAD = 6 -- folga em cima dos lados (o selo "+ CHANCE" passa da borda)
ShopLayout.SPIN_SIDE_MIN = 250 -- altura que um lado completo precisa
ShopLayout.SPIN_SIDE_MIN_COMPACT = 130 -- lado compacto: 3 linhas
ShopLayout.SPIN_SIDE_MAX = 300
-- Cartões "Escolha o tipo" de giro. No celular deitado o cartão de 250 px
-- passava da lista e o Escolher ficava na borda (10/11/2026): agora a altura sai
-- do espaço da lista (título da seção + cartão cabem juntos) e, se a largura
-- der, os 4 tipos ficam numa fileira só.
ShopLayout.SPIN_CARD_HEIGHT = 360
ShopLayout.SPIN_CARD_HEIGHT_COMPACT = 250 -- teto no celular
ShopLayout.SPIN_CARD_MIN = 180
ShopLayout.SPIN_CARD_MIN_WIDTH = 150 -- largura mínima para 4 numa fileira
ShopLayout.SECTION_TITLE = 36 + 10 -- título da seção + espaço até a grade (ShopParts/ShopScreen)
-- Celular (17/11/2026): uma página por aba, e cada seção cabe na página sem
-- mostrar pedaço da seguinte. Os cartões saem da altura livre da página.
ShopLayout.PASS_CARD_HEIGHT = 236
ShopLayout.PASS_MIN_WIDTH = 110 -- largura mínima de um cartão de gamepass na fileira (5 cabem na escala 1,25)
ShopLayout.EMBER_TOP_HEIGHT = 200
ShopLayout.EMBER_BOTTOM_HEIGHT = 170
-- Golden Ember no celular (ajuste do Elizeu, 17/11): os 5 numa fileira
-- espremiam as moedas. Volta às duas fileiras do PC; a de cima ocupa a
-- página e a de baixo aparece um pouco, mostrando que dá para rolar.
ShopLayout.EMBER_PEEK = 24
ShopLayout.LIST_BOTTOM_PAD = 16 -- respiro no fim da lista contínua (PC)

export type Layout = {
	compact: boolean,
	paged: boolean, -- celular: uma seção por vez (a aba troca a página)
	pageHeight: number, -- altura para os cartões de uma página (sem o título da seção)
	listBottomPad: number, -- espaço no fim da lista (0 na página: senão ela rola)
	top: number,
	topHeight: number,
	barX: number, -- começo da barra do topo (voltar, LOJA, abas): na borda da tela
	backWidth: number,
	titleWidth: number, -- 0 = sem a placa LOJA
	tabsX: number,
	tabsWidth: number,
	balanceLeft: number, -- onde começa o card da Golden Ember (MenuShell)
	contentX: number,
	contentWidth: number,
	contentTop: number,
	passColumns: number,
	spinColumns: number,
	spinCardHeight: number,
	emberTop: number, -- cartões de Golden Ember na fileira de cima
	emberBottom: number, -- e na de baixo (maiores)
	bannerHeight: number,
	spinSideBySide: boolean, -- tela do giro: normal e pago lado a lado
	spinBoxTop: number, -- topo da janela do giro
	spinTitleRow: number,
	spinTile: number, -- lado do quadradinho do carrossel
	spinSideHeight: number, -- altura de cada lado (normal / pago)
}

function ShopLayout.compute(width: number, height: number): Layout
	local m = ShopLayout.MARGIN
	local gap = ShopLayout.GAP
	local menu = MenuLayout.compute(width, height)
	local compact = menu.compact

	local backWidth = if compact then ShopLayout.BACK_WIDTH_COMPACT else ShopLayout.BACK_WIDTH
	local titleWidth = if compact then 0 else ShopLayout.TITLE_WIDTH
	local balanceLeft = width - m - menu.podWidth
	local tabsX = m + backWidth + gap + (if titleWidth > 0 then titleWidth + gap else 0)
	local top = m
	local topHeight = MenuLayout.POD_HEIGHT
	local contentWidth = math.min(width - 2 * m, ShopLayout.CONTENT_MAX)

	local contentTop = top + topHeight + m
	local fourFit = contentWidth >= 4 * ShopLayout.SPIN_CARD_MIN_WIDTH + 3 * gap
	local spinCardHeight = if compact
		then math.clamp(
			height - contentTop - m - ShopLayout.SECTION_TITLE,
			ShopLayout.SPIN_CARD_MIN,
			ShopLayout.SPIN_CARD_HEIGHT_COMPACT
		)
		else ShopLayout.SPIN_CARD_HEIGHT

	local pageHeight = math.max(height - contentTop - m - ShopLayout.SECTION_TITLE, 0)

	local spinBoxTop = if compact then m else top + topHeight + m
	local spinTitleRow = if compact then 34 else 50
	local spinTile = if compact then 56 else 100
	local spinSideRoom = height
		- m
		- spinBoxTop
		- 2 * ShopLayout.SPIN_PADDING
		- spinTitleRow
		- spinTile
		- ShopLayout.SPIN_REEL_EXTRA
		- 2 * ShopLayout.SPIN_GAP
		- ShopLayout.SPIN_SIDES_PAD

	return {
		compact = compact,
		paged = compact,
		pageHeight = pageHeight,
		listBottomPad = if compact then 0 else ShopLayout.LIST_BOTTOM_PAD,
		top = top,
		topHeight = topHeight,
		barX = m,
		backWidth = backWidth,
		titleWidth = titleWidth,
		tabsX = tabsX,
		tabsWidth = math.min(balanceLeft - gap - tabsX, ShopLayout.TABS_MAX),
		balanceLeft = balanceLeft,
		contentX = (width - contentWidth) / 2,
		contentWidth = contentWidth,
		contentTop = contentTop,
		passColumns = if compact then 3 else 5,
		-- 4 tipos de giro (MockStore.SPIN_TYPES): uma fileira no PC e no celular
		-- largo; 2x2 só quando não cabe.
		spinColumns = if not compact or fourFit then 4 else 2,
		spinCardHeight = spinCardHeight,
		emberTop = 3,
		emberBottom = 2,
		bannerHeight = if compact then pageHeight else math.clamp(width * 0.2, 180, 300),
		spinSideBySide = true,
		spinBoxTop = spinBoxTop,
		spinTitleRow = spinTitleRow,
		spinTile = spinTile,
		spinSideHeight = math.min(spinSideRoom, ShopLayout.SPIN_SIDE_MAX),
	}
end

-- Grade dos gamepasses: colunas e altura do cartão. No PC, 5 colunas de
-- 236; na página do celular, uma fileira se couber (cartão ≥ PASS_MIN_WIDTH)
-- e a altura dividida entre as fileiras.
function ShopLayout.passGrid(l: Layout, count: number): (number, number)
	if not l.paged then
		return l.passColumns, ShopLayout.PASS_CARD_HEIGHT
	end
	local gap = ShopLayout.GAP
	local fit = math.floor((l.contentWidth + gap) / (ShopLayout.PASS_MIN_WIDTH + gap))
	local columns = math.max(math.min(math.max(count, 1), fit), 1)
	local rows = math.ceil(math.max(count, 1) / columns)
	local cardHeight = math.min(ShopLayout.PASS_CARD_HEIGHT, (l.pageHeight - (rows - 1) * gap) / rows)
	return columns, cardHeight
end

-- Altura das duas fileiras de Golden Ember (de cima, de baixo). No PC as de
-- sempre; na página do celular a de cima vai até quase o fim da página.
function ShopLayout.emberHeights(l: Layout): (number, number)
	if not l.paged then
		return ShopLayout.EMBER_TOP_HEIGHT, ShopLayout.EMBER_BOTTOM_HEIGHT
	end
	local top = math.max(l.pageHeight - ShopLayout.EMBER_PEEK, 0)
	return top, math.min(ShopLayout.EMBER_BOTTOM_HEIGHT, math.max(top, 120))
end

return ShopLayout
