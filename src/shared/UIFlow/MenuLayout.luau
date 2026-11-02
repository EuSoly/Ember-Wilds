--!strict
-- Medidas da casca do menu (MenuShell) em pixels lógicos, sem depender do
-- Roblox para poder ser testada. A casca usa estes números como offsets (só a
-- largura dos pods é em escala), então o encaixe vale em qualquer tela de
-- ~800x400 até 1920x1080: pods no topo, coluna e painéis abaixo deles, e a
-- coluna rola quando os 6 botões não cabem.
local MenuLayout = {}

MenuLayout.MARGIN = 8
MenuLayout.POD_HEIGHT = 56 -- dois pods nos cantos; o centro fica livre para o logo
MenuLayout.POD_WIDTH = 0.24 -- fração da largura
MenuLayout.COLUMN_WIDTH = 120
MenuLayout.BUTTON_HEIGHT = 44 -- mínimo de toque
MenuLayout.BUTTON_GAP = 4
MenuLayout.NAV_COUNT = 6
-- Linha do título do painel: título e Fechar (44 px de toque) cabem nela, e o
-- conteúdo do painel começa logo abaixo.
MenuLayout.TITLE_ROW = 52
MenuLayout.BODY_TOP = MenuLayout.MARGIN + MenuLayout.POD_HEIGHT + MenuLayout.MARGIN

export type Layout = {
	podTop: number,
	podBottom: number,
	podWidth: number,
	bodyTop: number,
	columnX: number,
	columnWidth: number,
	columnBottom: number,
	columnContentHeight: number,
	columnScrolls: boolean,
	panelX: number,
	panelWidth: number,
	panelBottom: number,
	contentTop: number,
}

-- Posições resolvidas para uma tela de width x height (pixels lógicos).
function MenuLayout.compute(width: number, height: number): Layout
	local m = MenuLayout.MARGIN
	local bodyTop = MenuLayout.BODY_TOP
	local columnBottom = height - m
	local contentHeight = MenuLayout.NAV_COUNT * MenuLayout.BUTTON_HEIGHT
		+ (MenuLayout.NAV_COUNT - 1) * MenuLayout.BUTTON_GAP
	local panelX = m + MenuLayout.COLUMN_WIDTH + m
	return {
		podTop = m,
		podBottom = m + MenuLayout.POD_HEIGHT,
		podWidth = width * MenuLayout.POD_WIDTH,
		bodyTop = bodyTop,
		columnX = m,
		columnWidth = MenuLayout.COLUMN_WIDTH,
		columnBottom = columnBottom,
		columnContentHeight = contentHeight,
		columnScrolls = contentHeight > columnBottom - bodyTop,
		panelX = panelX,
		panelWidth = width - panelX - m,
		panelBottom = height - m,
		contentTop = bodyTop + MenuLayout.TITLE_ROW,
	}
end

return MenuLayout
