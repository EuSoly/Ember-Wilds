--!strict
-- Onde fica cada peça da tela de morte (puro, sem Roblox), em pixels lógicos
-- (a escala da interface já descontada). Janela escura no centro, com a placa
-- "VOCÊ MORREU" pregada no alto e os botões Menu / Jogar de novo embaixo.
--   largo: duas colunas lado a lado, o resumo (folha de papel) à esquerda e os
--     kits à direita; a lista de kits rola sozinha se não couber;
--   empilhado (janela estreita): o resumo em cima e os kits embaixo, numa
--     coluna só que rola inteira (a lista de kits não rola por dentro).
-- Os retângulos são relativos ao corpo da janela (abaixo da placa, acima dos
-- botões); no empilhado, relativos à tela que rola (canvasHeight de altura).
local DeathLayout = {}

export type Rect = { x: number, y: number, w: number, h: number }
export type Layout = {
	compact: boolean,
	stacked: boolean,
	panelWidth: number,
	panelHeight: number,
	bodyWidth: number,
	bodyHeight: number,
	canvasHeight: number,
	summary: Rect,
	kits: Rect,
}

DeathLayout.TITLE_HEIGHT = 58
DeathLayout.BUTTONS_HEIGHT = 52
DeathLayout.BODY_TOP = DeathLayout.TITLE_HEIGHT / 2 + 12
DeathLayout.BODY_SIDE = 16
DeathLayout.BODY_BOTTOM = DeathLayout.BUTTONS_HEIGHT + 16 + 12
DeathLayout.COLUMN_GAP = 12
-- Kits: título + pontos em cima, uma linha por kit (alvo de toque de 44).
DeathLayout.KITS_HEADER = 50
DeathLayout.KITS_PADDING = 8
DeathLayout.KIT_ROW = 44
DeathLayout.KIT_GAP = 6
-- Respiro em cima e embaixo da lista, para o contorno de brasa do kit
-- escolhido não ser cortado pela borda da lista.
DeathLayout.KIT_LIST_INSET = 3
-- Altura do resumo quando empilhado (no largo ocupa a coluna inteira).
DeathLayout.SUMMARY_STACKED = 210

local PANEL_MAX = { w = 760, h = 460 }
local STACK_BELOW = 560 -- janela mais estreita que isso: uma coluna só
local MARGIN = 24
local MARGIN_COMPACT = 12

-- Altura da lista de kits inteira (cabeçalho, linhas e respiro de baixo).
function DeathLayout.kitsHeight(kitCount: number): number
	local rows = math.max(kitCount, 0)
	local gaps = math.max(rows - 1, 0)
	return DeathLayout.KITS_HEADER
		+ DeathLayout.KIT_LIST_INSET * 2
		+ rows * DeathLayout.KIT_ROW
		+ gaps * DeathLayout.KIT_GAP
		+ DeathLayout.KITS_PADDING
end

-- Tela de `width` × `height` (pixels lógicos) com `kitCount` kits.
function DeathLayout.compute(width: number, height: number, kitCount: number): Layout
	-- Mesmo critério do design system: compacto = largura < 900 ou altura < 500.
	local compact = width < 900 or height < 500
	local margin = if compact then MARGIN_COMPACT else MARGIN
	local panelWidth = math.max(math.min(PANEL_MAX.w, width - margin * 2), 0)
	-- Metade da placa sai por cima da janela: desconta para ela não cortar.
	local panelHeight = math.max(math.min(PANEL_MAX.h, height - margin * 2 - DeathLayout.TITLE_HEIGHT / 2), 0)
	local bodyWidth = math.max(panelWidth - DeathLayout.BODY_SIDE * 2, 0)
	local bodyHeight = math.max(panelHeight - DeathLayout.BODY_TOP - DeathLayout.BODY_BOTTOM, 0)
	local stacked = panelWidth < STACK_BELOW

	if stacked then
		local summary = { x = 0, y = 0, w = bodyWidth, h = DeathLayout.SUMMARY_STACKED }
		local kitsY = summary.h + DeathLayout.COLUMN_GAP
		local kits = { x = 0, y = kitsY, w = bodyWidth, h = DeathLayout.kitsHeight(kitCount) }
		return {
			compact = compact,
			stacked = true,
			panelWidth = panelWidth,
			panelHeight = panelHeight,
			bodyWidth = bodyWidth,
			bodyHeight = bodyHeight,
			canvasHeight = kits.y + kits.h,
			summary = summary,
			kits = kits,
		}
	end

	local columnWidth = (bodyWidth - DeathLayout.COLUMN_GAP) / 2
	return {
		compact = compact,
		stacked = false,
		panelWidth = panelWidth,
		panelHeight = panelHeight,
		bodyWidth = bodyWidth,
		bodyHeight = bodyHeight,
		canvasHeight = bodyHeight,
		summary = { x = 0, y = 0, w = columnWidth, h = bodyHeight },
		kits = { x = columnWidth + DeathLayout.COLUMN_GAP, y = 0, w = columnWidth, h = bodyHeight },
	}
end

return DeathLayout
