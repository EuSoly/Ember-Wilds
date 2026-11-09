--!strict
-- Contas de tamanho da tela do Ranking (UI 6), puras (testadas no Lune).
-- Tudo em pixels lógicos da área do painel (antes do UIScale); `scale` é a
-- escala de interface, usada só para garantir alvos de toque ≥ 44 px.
-- Compacto = largura < 900 ou altura < 500 (regra do design system).
local RankingLayout = {}

export type Layout = {
	compact: boolean,
	stacked: boolean, -- pódio em cima da lista (tela estreita)
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
-- Assento: o avatar fica um pouco para dentro do tampo (fração da altura do pódio).
RankingLayout.SEAT = 0.06

function RankingLayout.compute(width: number, height: number, scale: number): Layout
	local compact = width < 900 or height < 500
	local minTouch = TOUCH / math.max(scale, 0.01)
	local rowHeight = math.max(if compact then 40 else 48, minTouch)
	local tabHeight = math.max(if compact then 44 else 52, minTouch)
	-- Empilha só em área estreita E em pé: deitada e baixa (celular, escala de
	-- interface grande) fica lado a lado, com o pódio menor.
	if width < STACK_BELOW and height > width * PORTRAIT then
		return {
			compact = compact,
			stacked = true,
			podiumWidth = math.min(width, 420),
			listWidth = width,
			gap = GAP,
			rowHeight = rowHeight,
			tabHeight = tabHeight,
		}
	end
	local podiumWidth = math.clamp(width * 0.45, 260, 600)
	return {
		compact = compact,
		stacked = false,
		podiumWidth = podiumWidth,
		listWidth = width - podiumWidth - GAP,
		gap = GAP,
		rowHeight = rowHeight,
		tabHeight = tabHeight,
	}
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
