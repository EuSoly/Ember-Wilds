--!strict
-- Onde fica cada peça da tela principal dos Cosméticos (puro, sem Roblox),
-- em pixels lógicos (a escala da interface já descontada):
--   largo (PC): cartões da esquerda empilhados, vitrine no meio (boneco em
--     cima, caixa embaixo) e cartões da direita centralizados na altura;
--   compacto (celular): tudo numa lista que rola — a vitrine em cima (boneco
--     e caixa lado a lado) e os cartões em duas colunas embaixo.
-- Os retângulos são relativos ao corpo da janela (abaixo do título, acima do
-- Fechar); no compacto, relativos à tela que rola (canvasHeight de altura).
local CosmeticsLayout = {}

export type Rect = { x: number, y: number, w: number, h: number }
export type Layout = {
	compact: boolean,
	windowWidth: number,
	windowHeight: number,
	bodyWidth: number,
	bodyHeight: number,
	canvasHeight: number,
	boneco: Rect,
	crate: Rect,
	cards: { Rect },
}

-- Medidas da janela (iguais às do Perfil).
CosmeticsLayout.TITLE_HEIGHT = 58
CosmeticsLayout.CLOSE_HEIGHT = 50
CosmeticsLayout.BODY_TOP = CosmeticsLayout.TITLE_HEIGHT / 2 + 12
CosmeticsLayout.BODY_SIDE = 16
CosmeticsLayout.BODY_BOTTOM = CosmeticsLayout.CLOSE_HEIGHT + 28
-- Cartão: placa (30) + frase (18) + amostras (>= 30) + respiros.
CosmeticsLayout.CARD_MIN_HEIGHT = 100
CosmeticsLayout.CARD_MIN_WIDTH = 150

local WINDOW_MAX = { w = 960, h = 600 }
local WINDOW_SHARE = { w = 0.92, h = 0.86 }
local GAP = 12
local SIDE_SHARE = 0.3 -- largura de cada coluna de cartões (largo)
local BONECO_SHARE = 0.68 -- altura do boneco na vitrine (largo); o resto é a caixa
local WIDE_MIN_WIDTH = 600
local SCROLL_GUTTER = 10 -- espaço da barra de rolagem (compacto)
-- Vitrine no compacto: uma fração da altura visível, para os cartões
-- aparecerem logo abaixo (mostra que a lista rola).
local SHOWCASE_SHARE = 0.65
local SHOWCASE_HEIGHT = { min = 120, max = 240 }
local COMPACT_BONECO_SHARE = 0.58 -- largura do boneco na vitrine (compacto)
local COMPACT_CARD_HEIGHT = 140

local function rect(x: number, y: number, w: number, h: number): Rect
	return { x = x, y = y, w = w, h = h }
end

local function wide(bodyW: number, bodyH: number, sides: { string }): Layout?
	local left, right = 0, 0
	for _, side in sides do
		if side == "right" then
			right += 1
		else
			left += 1
		end
	end
	local rows = math.max(left, right, 1)
	local rowH = (bodyH - (rows - 1) * GAP) / rows
	local colW = math.floor(bodyW * SIDE_SHARE)
	if bodyW < WIDE_MIN_WIDTH or rowH < CosmeticsLayout.CARD_MIN_HEIGHT then
		return nil
	end
	local centerX = colW + GAP
	local centerW = bodyW - 2 * (colW + GAP)
	local bonecoH = bodyH * BONECO_SHARE

	local cards: { Rect } = {}
	local leftIndex, rightIndex = 0, 0
	local rightTop = (bodyH - (right * rowH + (right - 1) * GAP)) / 2
	for _, side in sides do
		if side == "right" then
			table.insert(cards, rect(bodyW - colW, rightTop + rightIndex * (rowH + GAP), colW, rowH))
			rightIndex += 1
		else
			table.insert(cards, rect(0, leftIndex * (rowH + GAP), colW, rowH))
			leftIndex += 1
		end
	end
	return {
		compact = false,
		windowWidth = 0,
		windowHeight = 0,
		bodyWidth = bodyW,
		bodyHeight = bodyH,
		canvasHeight = bodyH,
		boneco = rect(centerX, 0, centerW, bonecoH),
		crate = rect(centerX, bonecoH, centerW, bodyH - bonecoH),
		cards = cards,
	}
end

local function compact(bodyW: number, bodyH: number, count: number): Layout
	local w = bodyW - SCROLL_GUTTER
	local showH = math.clamp(bodyH * SHOWCASE_SHARE, SHOWCASE_HEIGHT.min, SHOWCASE_HEIGHT.max)
	local bonecoW = w * COMPACT_BONECO_SHARE
	local cardW = (w - GAP) / 2
	local top = showH + GAP
	local cards: { Rect } = {}
	for i = 1, count do
		local column = (i - 1) % 2
		local row = (i - 1) // 2
		table.insert(
			cards,
			rect(column * (cardW + GAP), top + row * (COMPACT_CARD_HEIGHT + GAP), cardW, COMPACT_CARD_HEIGHT)
		)
	end
	local rows = (count + 1) // 2
	return {
		compact = true,
		windowWidth = 0,
		windowHeight = 0,
		bodyWidth = bodyW,
		bodyHeight = bodyH,
		canvasHeight = top + rows * COMPACT_CARD_HEIGHT + math.max(rows - 1, 0) * GAP,
		boneco = rect(0, 0, bonecoW, showH),
		-- A caixa fica embaixo, ao lado do boneco (o chão da vitrine).
		crate = rect(bonecoW, showH * 0.3, w - bonecoW, showH * 0.7),
		cards = cards,
	}
end

-- `sides` = o lado de cada cartão, na ordem dos cartões ("left"/"right").
function CosmeticsLayout.compute(screenW: number, screenH: number, sides: { string }): Layout
	local windowW = math.min(screenW * WINDOW_SHARE.w, WINDOW_MAX.w)
	local windowH = math.min(screenH * WINDOW_SHARE.h - CosmeticsLayout.TITLE_HEIGHT / 2, WINDOW_MAX.h)
	local bodyW = math.max(windowW - 2 * CosmeticsLayout.BODY_SIDE, 1)
	local bodyH = math.max(windowH - CosmeticsLayout.BODY_TOP - CosmeticsLayout.BODY_BOTTOM, 1)
	local layout = wide(bodyW, bodyH, sides) or compact(bodyW, bodyH, #sides)
	layout.windowWidth = windowW
	layout.windowHeight = windowH
	return layout
end

return CosmeticsLayout
