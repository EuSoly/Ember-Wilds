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

function HudColumn.pinnedHeight(rows: number): number
	if rows <= 0 then
		return 0
	end
	return HudColumn.PINNED_HEADER + rows * HudColumn.PINNED_ROW + HudColumn.PINNED_PADDING
end

export type Column = { tutorialY: number, pinnedY: number, notificationsY: number }

-- Onde cada peça começa, dadas as alturas (0 = não aparece).
function HudColumn.compute(tutorialHeight: number, pinnedHeight: number): Column
	local y = HudColumn.TOP
	local tutorialY = y
	if tutorialHeight > 0 then
		y += tutorialHeight + HudColumn.GAP
	end
	local pinnedY = y
	if pinnedHeight > 0 then
		y += pinnedHeight + HudColumn.GAP
	end
	local notificationsY = if y == HudColumn.TOP then HudColumn.NOTIFICATIONS_ALONE else y
	return { tutorialY = tutorialY, pinnedY = pinnedY, notificationsY = notificationsY }
end

return HudColumn
