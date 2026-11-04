--!strict
-- Medidas do menu (MenuShell) em pixels lógicos, sem depender do Roblox para
-- poder ser testada. Pods no topo (nível à esquerda, saldo à direita, logo no
-- meio), coluna de botões à esquerda e, à direita dela, a área do boneco com
-- os botões Kits e JOGAR embaixo. Com os kits abertos, o painel de kits ocupa
-- a direita; se não sobrar lugar para o boneco e os botões ao lado dele
-- (celular), o painel cobre a área toda (`kitsCoverHero`).
-- "Compacto" segue o design system: largura < 900 ou altura < 500.
local MenuLayout = {}

MenuLayout.MARGIN = 8
MenuLayout.POD_HEIGHT = 56 -- dois pods nos cantos; o centro fica livre para o logo
MenuLayout.POD_WIDTH = 0.24 -- fração da largura
MenuLayout.POD_MIN = 200 -- os pods não encolhem abaixo disto (nível + XP + selo)
MenuLayout.POD_MAX = 320
-- Logo no alto, entre os pods: maior no PC, menor no compacto.
MenuLayout.LOGO_ASPECT = 1200 / 804 -- proporção do PNG do logo
MenuLayout.LOGO_HEIGHT = 120
MenuLayout.LOGO_HEIGHT_COMPACT = 64
MenuLayout.LOGO_GAP = 8 -- folga mínima entre o logo e os pods
-- Árvore atrás da coluna: acompanha a altura da tela (proporção do PNG).
MenuLayout.TREE_ASPECT = 589 / 916
MenuLayout.COLUMN_WIDTH = 200 -- design system §8: 200 no PC
MenuLayout.COLUMN_WIDTH_COMPACT = 144 -- e 144 no compacto
MenuLayout.BUTTON_HEIGHT = 52 -- botão padrão
MenuLayout.BUTTON_HEIGHT_COMPACT = 44 -- mínimo de toque
MenuLayout.BUTTON_GAP = 4
MenuLayout.NAV_COUNT = 6 -- Perfil, Cosméticos, Loja, Tutorial, Ranking, Configurações
-- Linha do título do painel: título e Fechar (44 px de toque) cabem nela, e o
-- conteúdo do painel começa logo abaixo.
MenuLayout.TITLE_ROW = 52
MenuLayout.BODY_TOP = MenuLayout.MARGIN + MenuLayout.POD_HEIGHT + MenuLayout.MARGIN
MenuLayout.COMPACT_WIDTH = 900
MenuLayout.COMPACT_HEIGHT = 500

-- Linha Kits + JOGAR embaixo do boneco (botão principal = 60 de altura).
MenuLayout.ACTIONS_HEIGHT = 60
MenuLayout.ACTIONS_HEIGHT_COMPACT = 52
MenuLayout.KITS_BUTTON_WIDTH = 170
MenuLayout.PLAY_BUTTON_WIDTH = 220
MenuLayout.ACTIONS_GAP = 12
MenuLayout.KITS_BUTTON_WIDTH_COMPACT = 130
MenuLayout.PLAY_BUTTON_WIDTH_COMPACT = 160
MenuLayout.ACTIONS_GAP_COMPACT = 8
MenuLayout.ACTIONS_LIFT = 16 -- respiro entre os botões e a borda de baixo (PC)
MenuLayout.HERO_GAP = 8 -- entre o boneco e os botões
MenuLayout.HERO_MAX = 340
MenuLayout.HERO_WIDTH_SHARE = 0.9 -- o boneco usa no máximo 90% da largura livre

-- Painel de kits: fração da largura, entre o mínimo e o máximo.
MenuLayout.KIT_PANEL_SHARE = 0.36
MenuLayout.KIT_PANEL_MIN = 340
MenuLayout.KIT_PANEL_MAX = 520
-- Título + fechar do painel de kits (KitsPanel): o aviso de compra simulada
-- nunca fica por cima disso.
MenuLayout.KIT_HEADER_HEIGHT = 64
MenuLayout.NOTICE_HEIGHT = 36
MenuLayout.NOTICE_MAX = 520

export type Layout = {
	compact: boolean,
	podTop: number,
	podBottom: number,
	podWidth: number,
	logoTop: number,
	logoHeight: number,
	treeWidth: number,
	treeHeight: number,
	bodyTop: number,
	columnX: number,
	columnWidth: number,
	columnBottom: number,
	buttonHeight: number,
	columnContentHeight: number,
	columnScrolls: boolean,
	panelX: number,
	panelWidth: number,
	panelBottom: number,
	contentTop: number,
	heroCenterX: number,
	heroBottom: number,
	heroSize: number,
	actionsY: number,
	actionsHeight: number,
	actionsWidth: number,
	kitsButtonWidth: number,
	playButtonWidth: number,
	actionsGap: number,
	kitPanelX: number,
	kitPanelWidth: number,
	kitsCoverHero: boolean,
	noticeCenterX: number,
	noticeY: number,
	noticeWidth: number,
}

local function clamp(value: number, low: number, high: number): number
	return math.max(low, math.min(high, value))
end

-- Posições resolvidas para uma tela de width x height (pixels lógicos).
-- kitsOpen: o painel de kits está aberto (muda onde o boneco fica).
function MenuLayout.compute(width: number, height: number, kitsOpen: boolean?): Layout
	local m = MenuLayout.MARGIN
	local compact = width < MenuLayout.COMPACT_WIDTH or height < MenuLayout.COMPACT_HEIGHT
	local bodyTop = MenuLayout.BODY_TOP
	local bottom = height - m

	-- Coluna.
	local columnWidth = if compact then MenuLayout.COLUMN_WIDTH_COMPACT else MenuLayout.COLUMN_WIDTH
	local buttonHeight = if compact then MenuLayout.BUTTON_HEIGHT_COMPACT else MenuLayout.BUTTON_HEIGHT
	local contentHeight = MenuLayout.NAV_COUNT * buttonHeight + (MenuLayout.NAV_COUNT - 1) * MenuLayout.BUTTON_GAP
	local areaLeft = m + columnWidth + m
	local areaRight = width - m

	-- Botões Kits + JOGAR.
	local kitsWidth = if compact then MenuLayout.KITS_BUTTON_WIDTH_COMPACT else MenuLayout.KITS_BUTTON_WIDTH
	local playWidth = if compact then MenuLayout.PLAY_BUTTON_WIDTH_COMPACT else MenuLayout.PLAY_BUTTON_WIDTH
	local gap = if compact then MenuLayout.ACTIONS_GAP_COMPACT else MenuLayout.ACTIONS_GAP
	local actionsWidth = kitsWidth + gap + playWidth
	local actionsHeight = if compact then MenuLayout.ACTIONS_HEIGHT_COMPACT else MenuLayout.ACTIONS_HEIGHT
	local actionsY = bottom - actionsHeight - (if compact then 0 else MenuLayout.ACTIONS_LIFT)

	-- Painel de kits à direita; se o que sobra ao lado não comporta os botões,
	-- ele cobre a área toda (celular).
	local kitPanelWidth = clamp(width * MenuLayout.KIT_PANEL_SHARE, MenuLayout.KIT_PANEL_MIN, MenuLayout.KIT_PANEL_MAX)
	local kitPanelX = areaRight - kitPanelWidth
	local besideRoom = kitPanelX - m - areaLeft
	local kitsCover = compact or besideRoom < actionsWidth
	if kitsCover then
		kitPanelX = areaLeft
		kitPanelWidth = areaRight - areaLeft
	end

	-- Área do boneco: à direita da coluna (e à esquerda dos kits, se abertos ao lado).
	local heroRight = if kitsOpen and not kitsCover then kitPanelX - m else areaRight
	local heroAreaWidth = heroRight - areaLeft
	local heroBottom = actionsY - MenuLayout.HERO_GAP
	local heroSize = math.min(heroBottom - bodyTop, heroAreaWidth * MenuLayout.HERO_WIDTH_SHARE, MenuLayout.HERO_MAX)

	-- Aviso de compra simulada: no alto da área do boneco; com os kits cobrindo
	-- tudo (celular), dentro do painel, logo abaixo do título e do fechar.
	-- Logo: o maior que couber entre os pods.
	local podWidth = clamp(width * MenuLayout.POD_WIDTH, MenuLayout.POD_MIN, MenuLayout.POD_MAX)
	local logoTop = m - 4
	local logoRoom = (width - 2 * (m + podWidth) - 2 * MenuLayout.LOGO_GAP) / MenuLayout.LOGO_ASPECT
	local logoHeight =
		math.max(math.min(if compact then MenuLayout.LOGO_HEIGHT_COMPACT else MenuLayout.LOGO_HEIGHT, logoRoom), 0)

	local covering = kitsOpen == true and kitsCover
	local noticeCenterX = areaLeft + heroAreaWidth / 2
	local noticeY = math.max(bodyTop, logoTop + logoHeight) + 4
	local noticeWidth = math.min(heroAreaWidth - 16, MenuLayout.NOTICE_MAX)
	if covering then
		noticeCenterX = kitPanelX + kitPanelWidth / 2
		noticeY = bodyTop + MenuLayout.KIT_HEADER_HEIGHT + 4
		noticeWidth = math.min(kitPanelWidth - 32, MenuLayout.NOTICE_MAX)
	end

	return {
		compact = compact,
		podTop = m,
		podBottom = m + MenuLayout.POD_HEIGHT,
		podWidth = podWidth,
		logoTop = logoTop,
		logoHeight = logoHeight,
		treeWidth = height * MenuLayout.TREE_ASPECT,
		treeHeight = height,
		bodyTop = bodyTop,
		columnX = m,
		columnWidth = columnWidth,
		columnBottom = bottom,
		buttonHeight = buttonHeight,
		columnContentHeight = contentHeight,
		columnScrolls = contentHeight > bottom - bodyTop,
		panelX = areaLeft,
		panelWidth = areaRight - areaLeft,
		panelBottom = bottom,
		contentTop = bodyTop + MenuLayout.TITLE_ROW,
		heroCenterX = areaLeft + heroAreaWidth / 2,
		heroBottom = heroBottom,
		heroSize = math.max(heroSize, 0),
		actionsY = actionsY,
		actionsHeight = actionsHeight,
		actionsWidth = actionsWidth,
		kitsButtonWidth = kitsWidth,
		playButtonWidth = playWidth,
		actionsGap = gap,
		kitPanelX = kitPanelX,
		kitPanelWidth = kitPanelWidth,
		kitsCoverHero = covering,
		noticeCenterX = noticeCenterX,
		noticeY = noticeY,
		noticeWidth = noticeWidth,
	}
end

return MenuLayout
