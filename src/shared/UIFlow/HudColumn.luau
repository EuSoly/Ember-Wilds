--!strict
-- Coluna da direita do HUD, embaixo do minimapa e dos botões redondos (puro,
-- testado no Lune): o quadrinho do tutorial, a receita fixada e os avisos,
-- um embaixo do outro, sem se sobrepor. Medidas em fração da altura da tela.
local HudColumn = {}

HudColumn.TOP = 0.355 -- logo abaixo dos botões redondos (vão até ~0,34)
HudColumn.GAP = 0.01
HudColumn.NOTIFICATIONS_ALONE = 0.4 -- onde os avisos ficam quando não há mais nada
HudColumn.WIDTH = 0.24 -- largura dos painéis (fração da largura da tela)

-- Altura do quadrinho do tutorial: só o texto, ou com a linha do que pegar.
HudColumn.TUTORIAL_HEIGHT = 0.1
HudColumn.TUTORIAL_HEIGHT_NEEDS = 0.155

-- Altura do painel da receita fixada: o título e uma linha por ingrediente.
HudColumn.PINNED_HEADER = 0.045
HudColumn.PINNED_ROW = 0.042
HudColumn.PINNED_PADDING = 0.02

-- Mínimos em pixels: no celular deitado (tela de ~330 px) as frações davam um
-- quadrinho de 33 px com o texto ilegível (10/11/2026). Em tela grande as
-- frações já passam destes mínimos e nada muda.
HudColumn.TUTORIAL_MIN_PX = 70
HudColumn.TUTORIAL_NEEDS_MIN_PX = 100
HudColumn.PINNED_HEADER_MIN_PX = 28
HudColumn.PINNED_ROW_MIN_PX = 24
HudColumn.PINNED_PADDING_MIN_PX = 10

-- A fração `share`, mas nunca menos que `px` numa tela de `screenHeight` px
-- (sem a altura da tela, só a fração).
local function atLeast(share: number, px: number, screenHeight: number?): number
	if screenHeight == nil or screenHeight <= 0 then
		return share
	end
	return math.max(share, px / screenHeight)
end

-- Altura do quadrinho do tutorial (fração da tela).
function HudColumn.tutorialHeight(hasNeeds: boolean, screenHeight: number?): number
	if hasNeeds then
		return atLeast(HudColumn.TUTORIAL_HEIGHT_NEEDS, HudColumn.TUTORIAL_NEEDS_MIN_PX, screenHeight)
	end
	return atLeast(HudColumn.TUTORIAL_HEIGHT, HudColumn.TUTORIAL_MIN_PX, screenHeight)
end

function HudColumn.pinnedHeight(rows: number, screenHeight: number?): number
	if rows <= 0 then
		return 0
	end
	return atLeast(HudColumn.PINNED_HEADER, HudColumn.PINNED_HEADER_MIN_PX, screenHeight)
		+ rows * atLeast(HudColumn.PINNED_ROW, HudColumn.PINNED_ROW_MIN_PX, screenHeight)
		+ atLeast(HudColumn.PINNED_PADDING, HudColumn.PINNED_PADDING_MIN_PX, screenHeight)
end

export type Column = { tutorialY: number, pinnedY: number, notificationsY: number }

-- Onde cada peça começa, dadas as alturas (0 = não aparece). `top` = onde a
-- coluna começa (fração da tela; padrão TOP): desde 11/11 o minimapa e os botões
-- têm tamanho em px (MinimapRules.layout), e a coluna começa logo abaixo deles.
function HudColumn.compute(tutorialHeight: number, pinnedHeight: number, top: number?): Column
	local start = top or HudColumn.TOP
	local y = start
	local tutorialY = y
	if tutorialHeight > 0 then
		y += tutorialHeight + HudColumn.GAP
	end
	local pinnedY = y
	if pinnedHeight > 0 then
		y += pinnedHeight + HudColumn.GAP
	end
	local notificationsY = if y == start then math.max(HudColumn.NOTIFICATIONS_ALONE, start) else y
	return { tutorialY = tutorialY, pinnedY = pinnedY, notificationsY = notificationsY }
end

return HudColumn
