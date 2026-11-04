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
-- Tela do giro: no celular ela sobe até o topo (fica por cima de tudo) e usa
-- título e quadradinhos menores, para os dois lados caberem sem rolar.
ShopLayout.SPIN_PADDING = 10
ShopLayout.SPIN_GAP = 8
ShopLayout.SPIN_REEL_EXTRA = 20 -- a janela do carrossel = quadradinho + isto
ShopLayout.SPIN_SIDE_MIN = 250 -- altura que um lado completo precisa
ShopLayout.SPIN_SIDE_MIN_COMPACT = 130 -- lado compacto: 3 linhas
ShopLayout.SPIN_SIDE_MAX = 300

export type Layout = {
	compact: boolean,
	top: number,
	topHeight: number,
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

	return {
		compact = compact,
		top = top,
		topHeight = topHeight,
		backWidth = backWidth,
		titleWidth = titleWidth,
		tabsX = tabsX,
		tabsWidth = balanceLeft - gap - tabsX,
		balanceLeft = balanceLeft,
		contentX = m,
		contentWidth = width - 2 * m,
		contentTop = top + topHeight + m,
		passColumns = if compact then 3 else 5,
		spinColumns = if compact then 3 else 5,
		emberTop = if compact then 2 else 3,
		emberBottom = 2,
		bannerHeight = if compact then math.clamp(height * 0.42, 120, 200) else math.clamp(width * 0.2, 180, 300),
		spinSideBySide = true,
		spinBoxTop = spinBoxTop,
		spinTitleRow = spinTitleRow,
		spinTile = spinTile,
		spinSideHeight = math.min(spinSideRoom, ShopLayout.SPIN_SIDE_MAX),
	}
end

return ShopLayout
