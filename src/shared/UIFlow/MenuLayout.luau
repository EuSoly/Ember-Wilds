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
-- Celular deitado (17/11/2026): pods, botões e espaço menores para os 6 botões
-- da coluna caberem sem rolar em 330 px de altura. Os botões ficam com 40
-- (abaixo dos 44 de toque): exceção pedida pelo Elizeu; são largos (144).
MenuLayout.POD_HEIGHT_COMPACT = 48
MenuLayout.POD_WIDTH = 0.24 -- fração da largura
MenuLayout.POD_MIN = 200 -- os pods não encolhem abaixo disto (nível + XP + selo)
MenuLayout.POD_MAX = 320
-- Logo no alto, entre os pods: maior no PC, menor no compacto.
MenuLayout.LOGO_ASPECT = 1200 / 804 -- proporção do PNG do logo
MenuLayout.LOGO_HEIGHT = 120
MenuLayout.LOGO_HEIGHT_COMPACT = 64
MenuLayout.LOGO_GAP = 8 -- folga mínima entre o logo e os pods
-- Árvore atrás da coluna (fundo em tela cheia): largura = altura × proporção do PNG.
MenuLayout.TREE_ASPECT = 589 / 916
MenuLayout.COLUMN_WIDTH = 200 -- design system §8: 200 no PC
MenuLayout.COLUMN_WIDTH_COMPACT = 144 -- e 144 no compacto
MenuLayout.BUTTON_HEIGHT = 52 -- botão padrão
MenuLayout.BUTTON_HEIGHT_COMPACT = 40
MenuLayout.BUTTON_GAP = 4
MenuLayout.BUTTON_GAP_COMPACT = 3
MenuLayout.NAV_COUNT = 6 -- Perfil, Cosméticos, Loja, Missões, Ranking, Configurações
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
-- Botão do calendário (check-in): logo abaixo do card do saldo, encostado na
-- borda direita. O logo fica livre entre os pods; a coluna não ganha botão.
MenuLayout.CALENDAR_SIZE = 56
MenuLayout.CALENDAR_SIZE_COMPACT = 44 -- mínimo de toque
MenuLayout.CALENDAR_GAP = 4

export type Layout = {
	compact: boolean,
	podTop: number,
	podBottom: number,
	podHeight: number,
	podWidth: number,
	logoTop: number,
	logoHeight: number,
	bodyTop: number,
	columnX: number,
	columnWidth: number,
	columnBottom: number,
	buttonHeight: number,
	buttonGap: number,
	columnContentHeight: number,
	columnScrolls: boolean,
	panelX: number,
	panelWidth: number,
	panelBottom: number,
	rankingTop: number, -- topo do ranking: no celular sobe até o topo (sem logo e sem saldo)
	contentTop: number,
	heroCenterX: number,
	heroBottom: number,
	heroSize: number,
	actionsY: number,
	actionsHeight: number,
	actionsWidth: number,
	actionsX: number, -- borda esquerda dos botões Kits + JOGAR (o JOGAR fica embaixo do boneco)
	kitsButtonWidth: number,
	playButtonWidth: number,
	actionsGap: number,
	kitPanelX: number,
	kitPanelTop: number, -- no celular sobe até o topo, como o ranking
	kitPanelWidth: number,
	kitsCoverHero: boolean,
	noticeCenterX: number,
	noticeY: number,
	noticeWidth: number,
	calendarX: number, -- borda esquerda do botão do calendário
	calendarY: number,
	calendarSize: number,
}

local function clamp(value: number, low: number, high: number): number
	return math.max(low, math.min(high, value))
end

-- Posições resolvidas para uma tela de width x height (pixels lógicos).
-- kitsOpen: o painel de kits está aberto (muda onde o boneco fica).
function MenuLayout.compute(width: number, height: number, kitsOpen: boolean?): Layout
	local m = MenuLayout.MARGIN
	local compact = width < MenuLayout.COMPACT_WIDTH or height < MenuLayout.COMPACT_HEIGHT
	local podHeight = if compact then MenuLayout.POD_HEIGHT_COMPACT else MenuLayout.POD_HEIGHT
	local bodyTop = m + podHeight + m
	local bottom = height - m

	-- Coluna.
	local columnWidth = if compact then MenuLayout.COLUMN_WIDTH_COMPACT else MenuLayout.COLUMN_WIDTH
	local buttonHeight = if compact then MenuLayout.BUTTON_HEIGHT_COMPACT else MenuLayout.BUTTON_HEIGHT
	local buttonGap = if compact then MenuLayout.BUTTON_GAP_COMPACT else MenuLayout.BUTTON_GAP
	local contentHeight = MenuLayout.NAV_COUNT * buttonHeight + (MenuLayout.NAV_COUNT - 1) * buttonGap
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
	-- O boneco começa onde começava antes dos pods compactos (BODY_TOP): os 8 px
	-- ganhos são da coluna; o aviso e o logo continuam acima da cabeça dele.
	local heroTop = math.max(bodyTop, MenuLayout.BODY_TOP)
	local heroSize = math.min(heroBottom - heroTop, heroAreaWidth * MenuLayout.HERO_WIDTH_SHARE, MenuLayout.HERO_MAX)

	-- Boneco e JOGAR no meio da tela (pedido do Elizeu, 10/11/2026); com os kits
	-- abertos ao lado, no meio da área livre. O JOGAR fica embaixo do boneco e o
	-- botão de kits à esquerda dele; perto da coluna ou dos kits, o centro anda
	-- só o necessário para nada passar por cima.
	local playLeftReach = kitsWidth + gap + playWidth / 2 -- do centro do JOGAR até a borda esquerda dos botões
	local wantedCenter = if kitsOpen and not kitsCover then areaLeft + heroAreaWidth / 2 else width / 2
	local lowest = areaLeft + math.max(heroSize / 2, playLeftReach)
	local highest = heroRight - math.max(heroSize / 2, playWidth / 2)
	local heroCenterX = clamp(wantedCenter, lowest, math.max(lowest, highest))

	-- Aviso de compra simulada: no alto da área do boneco; com os kits cobrindo
	-- tudo (celular), dentro do painel, logo abaixo do título e do fechar.
	-- Logo: o maior que couber entre os pods.
	local podWidth = clamp(width * MenuLayout.POD_WIDTH, MenuLayout.POD_MIN, MenuLayout.POD_MAX)
	local logoTop = m - 4
	local logoRoom = (width - 2 * (m + podWidth) - 2 * MenuLayout.LOGO_GAP) / MenuLayout.LOGO_ASPECT
	local logoHeight =
		math.max(math.min(if compact then MenuLayout.LOGO_HEIGHT_COMPACT else MenuLayout.LOGO_HEIGHT, logoRoom), 0)

	local covering = kitsOpen == true and kitsCover
	-- Kits no celular (ajuste do Elizeu, 17/11): sobem até o topo, sem logo e
	-- sem saldo, para caber duas fileiras de kits sem rolar.
	local kitPanelTop = if compact then m else bodyTop
	local noticeCenterX = areaLeft + heroAreaWidth / 2
	local noticeY = math.max(bodyTop, logoTop + logoHeight) + 4
	local noticeWidth = math.min(heroAreaWidth - 16, MenuLayout.NOTICE_MAX)
	if covering then
		noticeCenterX = kitPanelX + kitPanelWidth / 2
		noticeY = kitPanelTop + MenuLayout.KIT_HEADER_HEIGHT + 4
		noticeWidth = math.min(kitPanelWidth - 32, MenuLayout.NOTICE_MAX)
	end

	local calendarSize = if compact then MenuLayout.CALENDAR_SIZE_COMPACT else MenuLayout.CALENDAR_SIZE

	return {
		compact = compact,
		podTop = m,
		podBottom = m + podHeight,
		podHeight = podHeight,
		podWidth = podWidth,
		logoTop = logoTop,
		logoHeight = logoHeight,
		bodyTop = bodyTop,
		columnX = m,
		columnWidth = columnWidth,
		columnBottom = bottom,
		buttonHeight = buttonHeight,
		buttonGap = buttonGap,
		columnContentHeight = contentHeight,
		columnScrolls = contentHeight > bottom - bodyTop,
		panelX = areaLeft,
		panelWidth = areaRight - areaLeft,
		panelBottom = bottom,
		rankingTop = if compact then m else bodyTop,
		contentTop = bodyTop + MenuLayout.TITLE_ROW,
		heroCenterX = heroCenterX,
		heroBottom = heroBottom,
		heroSize = math.max(heroSize, 0),
		actionsY = actionsY,
		actionsHeight = actionsHeight,
		actionsWidth = actionsWidth,
		actionsX = heroCenterX - playLeftReach,
		kitsButtonWidth = kitsWidth,
		playButtonWidth = playWidth,
		actionsGap = gap,
		kitPanelX = kitPanelX,
		kitPanelTop = kitPanelTop,
		kitPanelWidth = kitPanelWidth,
		kitsCoverHero = covering,
		noticeCenterX = noticeCenterX,
		noticeY = noticeY,
		noticeWidth = noticeWidth,
		calendarX = width - m - calendarSize,
		calendarY = m + podHeight + MenuLayout.CALENDAR_GAP,
		calendarSize = calendarSize,
	}
end

return MenuLayout
