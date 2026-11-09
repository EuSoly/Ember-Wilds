--!strict
-- Contas de tamanho da tela do Ranking (UI 6), puras (testadas no Lune).
-- Entra o tamanho da JANELA em pixels lógicos (antes do UIScale); `scale` é a
-- escala de interface, usada só para garantir alvos de toque ≥ 44 px.
-- Compacto = largura < 900 ou altura < 500 (regra do design system): margens
-- menores e as abas na linha do título (sem título nem taça), para sobrar
-- corpo no celular deitado.
local RankingLayout = {}

export type Layout = {
	compact: boolean,
	inlineTabs: boolean, -- abas na linha do título (compacto)
	inset: number, -- margem do conteúdo até a borda da janela
	headerHeight: number, -- linha do título (0 com as abas na linha dele)
	tabTop: number,
	bodyTop: number,
	bodyWidth: number,
	bodyHeight: number,
	stacked: boolean, -- pódio em cima da lista (área estreita e em pé)
	podiumWidth: number,
	listWidth: number,
	gap: number,
	rowHeight: number,
	tabHeight: number,
}

local TOUCH = 44
local STACK_BELOW = 700 -- abaixo desta largura (e em pé), pódio em cima da lista
local PORTRAIT = 0.75 -- "em pé" = altura maior que isto vezes a largura
local GAP = 16
-- A linha "você" é um pouco mais alta que as outras.
RankingLayout.ME_SCALE = 1.25
-- Assento: o avatar fica um pouco para dentro do tampo (fração da altura do pódio).
RankingLayout.SEAT = 0.06

function RankingLayout.compute(width: number, height: number, scale: number): Layout
	local compact = width < 900 or height < 500
	local minTouch = TOUCH / math.max(scale, 0.01)
	local rowHeight = math.max(if compact then 40 else 48, minTouch)
	local tabHeight = math.max(if compact then 44 else 52, minTouch)

	local inset = if compact then 16 else 30
	local headerHeight = if compact then 0 else 58
	local tabTop = if compact then 12 else 14 + headerHeight - 4
	local bodyTop = tabTop + tabHeight + (if compact then 8 else 10)
	local bodyWidth = math.max(width - 2 * inset, 0)
	local bodyHeight = math.max(height - bodyTop - inset, 0)

	local layout: Layout = {
		compact = compact,
		inlineTabs = compact,
		inset = inset,
		headerHeight = headerHeight,
		tabTop = tabTop,
		bodyTop = bodyTop,
		bodyWidth = bodyWidth,
		bodyHeight = bodyHeight,
		stacked = false,
		podiumWidth = 0,
		listWidth = 0,
		gap = GAP,
		rowHeight = rowHeight,
		tabHeight = tabHeight,
	}
	-- Empilha só em área estreita E em pé: deitada e baixa (celular, escala de
	-- interface grande) fica lado a lado, com o pódio menor.
	if bodyWidth < STACK_BELOW and bodyHeight > bodyWidth * PORTRAIT then
		layout.stacked = true
		layout.podiumWidth = math.min(bodyWidth, 420)
		layout.listWidth = bodyWidth
	else
		layout.podiumWidth = math.clamp(bodyWidth * 0.45, math.min(260, bodyWidth * 0.45), 600)
		layout.listWidth = bodyWidth - layout.podiumWidth - GAP
	end
	return layout
end

-- Onde vão, no quadro do pódio de `podiumW` × `podiumH`, o pé do avatar (em
-- cima do tampo do degrau) e o centro da plaquinha. `spot` em frações da
-- imagem (RankingImages.PODIUM_SPOTS).
function RankingLayout.spot(
	spot: { x: number, top: number, plaqueY: number },
	podiumW: number,
	podiumH: number
): (number, number, number, number)
	local x = spot.x * podiumW
	return x, (spot.top + RankingLayout.SEAT) * podiumH, x, spot.plaqueY * podiumH
end

return RankingLayout
