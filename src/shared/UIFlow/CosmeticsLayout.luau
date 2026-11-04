--!strict
-- Onde fica cada peça da tela principal dos Cosméticos (puro, sem Roblox),
-- em pixels lógicos (a escala da interface já descontada):
--   largo (PC): cartões da esquerda empilhados, vitrine no meio (boneco em
--     cima, caixa embaixo) e cartões da direita centralizados na altura;
--   compacto (celular): tudo numa lista que rola — a vitrine em cima (boneco
--     e caixa lado a lado) e os cartões em duas colunas embaixo.
-- Os retângulos são relativos ao corpo da janela (abaixo do título, acima do
-- Fechar); no compacto, relativos à tela que rola (canvasHeight de altura).
--
-- Tela da categoria (`category`, igual no PC e no celular): sem o Fechar (o
-- Voltar fica na coluna da esquerda), o corpo desce até perto da borda. Na
-- esquerda a vitrine, o nome e a raridade da skin selecionada e o Voltar; na
-- direita a placa da categoria, a grade 3×3 e as setas dos lados da grade.
-- Retângulos relativos ao corpo da categoria (width × height).
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
	category: CategoryLayout,
}
export type CategoryLayout = {
	width: number,
	height: number,
	showcase: Rect,
	name: Rect,
	rarity: Rect,
	back: Rect,
	plate: Rect,
	prev: Rect,
	next: Rect,
	tiles: { Rect },
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
-- Tela da categoria: 9 skins por página; quadradinho com espaço para o item
-- e o nome; corpo até 16 px da borda de baixo (o Fechar some).
CosmeticsLayout.PER_PAGE = 9
CosmeticsLayout.TILE_MIN = 56
CosmeticsLayout.CATEGORY_BOTTOM = 16

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
-- Tela da categoria.
local GRID = 3 -- colunas e linhas da grade
local TILE_GAP = 6
local CATEGORY_LEFT_SHARE = 0.4 -- largura da coluna da vitrine
local CATEGORY_PLATE_HEIGHT = 30
local ARROW = 44 -- setas quadradas, no tamanho mínimo de toque
local NAME_HEIGHT = 24
local RARITY_HEIGHT = 18
local BACK = { w = 200, h = 44 }

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
		category = nil :: any, -- preenchido no compute
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
		category = nil :: any, -- preenchido no compute
	}
end

local function category(w: number, h: number): CategoryLayout
	-- Esquerda: Voltar no pé, raridade e nome acima, a vitrine no resto.
	local leftW = math.floor(w * CATEGORY_LEFT_SHARE)
	local backW = math.min(BACK.w, leftW)
	local back = rect((leftW - backW) / 2, h - BACK.h, backW, BACK.h)
	local rarity = rect(0, back.y - TILE_GAP - RARITY_HEIGHT, leftW, RARITY_HEIGHT)
	local name = rect(0, rarity.y - NAME_HEIGHT, leftW, NAME_HEIGHT)
	local showcase = rect(0, 0, leftW, math.max(name.y - TILE_GAP, 1))

	-- Direita: o maior quadradinho que cabe com as setas dos lados e a placa
	-- em cima; o bloco (placa + grade) fica centralizado na coluna.
	local rightX = leftW + GAP
	local rightW = w - rightX
	local spacing = (GRID - 1) * TILE_GAP
	local byWidth = (rightW - 2 * (ARROW + GAP) - spacing) / GRID
	local byHeight = (h - CATEGORY_PLATE_HEIGHT - TILE_GAP - spacing) / GRID
	local tile = math.max(math.floor(math.min(byWidth, byHeight)), 1)
	local gridSize = GRID * tile + spacing
	local blockH = CATEGORY_PLATE_HEIGHT + TILE_GAP + gridSize
	local gridX = rightX + (rightW - gridSize) / 2
	local top = math.max((h - blockH) / 2, 0)
	local gridY = top + CATEGORY_PLATE_HEIGHT + TILE_GAP

	local tiles: { Rect } = {}
	for i = 1, CosmeticsLayout.PER_PAGE do
		local row, column = (i - 1) // GRID, (i - 1) % GRID
		table.insert(tiles, rect(gridX + column * (tile + TILE_GAP), gridY + row * (tile + TILE_GAP), tile, tile))
	end
	local arrowY = gridY + (gridSize - ARROW) / 2
	local prev = rect(gridX - GAP - ARROW, arrowY, ARROW, ARROW)
	local next = rect(gridX + gridSize + GAP, arrowY, ARROW, ARROW)
	return {
		width = w,
		height = h,
		showcase = showcase,
		name = name,
		rarity = rarity,
		back = back,
		plate = rect(prev.x, top, next.x + next.w - prev.x, CATEGORY_PLATE_HEIGHT),
		prev = prev,
		next = next,
		tiles = tiles,
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
	local categoryH = math.max(windowH - CosmeticsLayout.BODY_TOP - CosmeticsLayout.CATEGORY_BOTTOM, 1)
	layout.category = category(bodyW, categoryH)
	return layout
end

return CosmeticsLayout
