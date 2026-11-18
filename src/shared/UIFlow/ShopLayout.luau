--!strict
-- Medidas da Loja em tela cheia (pixels lógicos), sem depender do Roblox para
-- poder ser testada. Topo: voltar, placa LOJA (some no celular) e as abas,
-- deixando livre o card da Golden Ember do canto (MenuShell). Abaixo, a lista
-- de seções com o número de colunas de cada grade: menos colunas no compacto.
local MenuLayout = require("./MenuLayout")

local ShopLayout = {}

ShopLayout.MARGIN = 8
ShopLayout.GAP = 8 -- entre cartões e entre peças do topo
ShopLayout.BACK_WIDTH = 120
ShopLayout.BACK_WIDTH_COMPACT = 88
ShopLayout.TITLE_WIDTH = 140
-- Em telas grandes a loja não se estica até as bordas: o conteúdo para nesta
-- largura (centralizado) e as abas nesta.
ShopLayout.CONTENT_MAX = 1120
ShopLayout.TABS_MAX = 640
-- Tela do giro: no celular ela sobe até o topo (fica por cima de tudo) e usa
-- título e quadradinhos menores, para os dois lados caberem sem rolar.
ShopLayout.SPIN_PADDING = 10
ShopLayout.SPIN_GAP = 8
ShopLayout.SPIN_REEL_EXTRA = 20 -- a janela do carrossel = quadradinho + isto
ShopLayout.SPIN_SIDE_MIN = 250 -- altura que um lado completo precisa
ShopLayout.SPIN_SIDE_MIN_COMPACT = 130 -- lado compacto: 3 linhas
ShopLayout.SPIN_SIDE_MAX = 300
-- Cartões "Escolha o tipo" de giro. No celular deitado o cartão de 250 px
-- passava da lista e o Escolher ficava na borda (10/11/2026): agora a altura sai
-- do espaço da lista (título da seção + cartão cabem juntos) e, se a largura
-- der, os 4 tipos ficam numa fileira só.
ShopLayout.SPIN_CARD_HEIGHT = 360
ShopLayout.SPIN_CARD_HEIGHT_COMPACT = 250 -- teto no celular
ShopLayout.SPIN_CARD_MIN = 180
ShopLayout.SPIN_CARD_MIN_WIDTH = 150 -- largura mínima para 4 numa fileira
ShopLayout.SECTION_TITLE = 36 + 10 -- título da seção + espaço até a grade (ShopParts/ShopScreen)
-- Celular (17/11/2026): uma página por aba, e cada seção cabe na página sem
-- mostrar pedaço da seguinte. Os cartões saem da altura livre da página.
ShopLayout.PASS_CARD_HEIGHT = 236
ShopLayout.PASS_MIN_WIDTH = 88 -- largura mínima de um cartão de gamepass na fileira do celular (6 cabem em 599 px)
-- PC (teste de 17/11/2026, 1128×793): os 6 cartões (4 kits + 2× + livro) iam
-- para 2 fileiras e a aba rolava. Agora a fileira passa das 5 colunas se cada
-- cartão ainda tiver esta largura.
ShopLayout.PASS_MIN_WIDTH_PC = 150
ShopLayout.EMBER_CARD_HEIGHT = 200
-- Fileira de cima da aba de gamepasses (VIP, boost de XP e Premium): cartões
-- deitados. No celular ela é uma faixa baixa (título, linha curta e botão) e
-- a grade de baixo fica numa fileira só com o que sobra da página: nada rola.
-- Cartão de gamepass mais baixo que PASS_CARD_SHORT esconde a descrição; mais
-- baixo que PASS_CARD_TINY fica só nome e botão.
ShopLayout.TOP_ROW_HEIGHT = 156 -- 140 até 17/11/2026: o boost e o Premium empilhados pedem mais
ShopLayout.TOP_ROW_HEIGHT_COMPACT = 44
ShopLayout.PASS_CARD_SHORT = 170
ShopLayout.PASS_CARD_TINY = 120
-- Peças do cartão de gamepass (passCardParts). Teste de 18/11/2026 no PC: os
-- nomes encostavam na moldura em 6 colunas e a descrição saía minúscula e
-- cortada. Agora os textos ficam recuados da borda, o nome pode quebrar em
-- duas linhas e a descrição tem duas linhas ou não aparece.
ShopLayout.PASS_PAD = 10 -- embaixo do botão
ShopLayout.PASS_BUTTON = 44
ShopLayout.PASS_BUTTON_TINY = 34
ShopLayout.PASS_DESC_MIN = 30 -- duas linhas de ≥ 13 px
ShopLayout.PASS_DESC_MAX = 40
ShopLayout.PASS_TEXT_MIN_PC = 13 -- menor letra da descrição no PC
-- Composição de cada cartão da fileira de cima (bannerParts). No PC os textos
-- ficavam com ~8 px (17/11/2026): a coluna do meio esticava por UIFlexItem e
-- sobrava quase nada. Agora as caixas saem daqui, em pixels. Cartão do PC mais
-- estreito que BANNER_STACK_BELOW (boost, Premium) empilha: ícone e textos em
-- cima, o botão embaixo na largura toda; o largo (VIP) fica em linha: ícone,
-- textos e botão.
ShopLayout.BANNER_PAD = 10
ShopLayout.BANNER_GAP = 8
ShopLayout.BANNER_STACK_BELOW = 420
ShopLayout.BANNER_STACK_ICON = 56
ShopLayout.BANNER_STACK_BUTTON = 40
ShopLayout.BANNER_BUTTON_SHARE = 0.3 -- largura do botão em linha
-- Menor letra dos textos da fileira no PC (título e descrição).
ShopLayout.BANNER_TITLE_MIN = 18
ShopLayout.BANNER_DESC_MIN = 13

export type Box = { x: number, y: number, w: number, h: number }
export type PassCardParts = {
	icon: Box?, -- nil = cartão baixo demais (só nome e botão)
	name: Box,
	desc: Box?, -- nil = sem lugar para duas linhas
	button: Box,
}

export type BannerParts = {
	icon: Box?, -- nil = sem ícone (faixa baixa do celular)
	text: Box,
	button: Box,
	stacked: boolean,
}

export type Layout = {
	compact: boolean,
	paged: boolean, -- celular: uma seção por vez (a aba troca a página)
	pageHeight: number, -- altura para os cartões de uma página (sem o título da seção)
	top: number,
	topHeight: number,
	barX: number, -- começo da barra do topo (voltar, LOJA, abas): na borda da tela
	backWidth: number,
	titleWidth: number, -- 0 = sem a placa LOJA
	tabsX: number,
	tabsWidth: number,
	balanceLeft: number, -- onde começa o card da Golden Ember (MenuShell)
	contentX: number,
	contentWidth: number,
	contentTop: number,
	passColumns: number,
	spinColumns: number,
	spinCardHeight: number,
	emberTop: number, -- cartões de Golden Ember na fileira de cima
	emberBottom: number, -- e na de baixo (maiores)
	bannerHeight: number,
	spinSideBySide: boolean, -- tela do giro: normal e pago lado a lado
	spinBoxTop: number, -- topo da janela do giro
	spinTitleRow: number,
	spinTile: number, -- lado do quadradinho do carrossel
	spinSideHeight: number, -- altura de cada lado (normal / pago)
}

function ShopLayout.compute(width: number, height: number): Layout
	local m = ShopLayout.MARGIN
	local gap = ShopLayout.GAP
	local menu = MenuLayout.compute(width, height)
	local compact = menu.compact

	local backWidth = if compact then ShopLayout.BACK_WIDTH_COMPACT else ShopLayout.BACK_WIDTH
	local titleWidth = if compact then 0 else ShopLayout.TITLE_WIDTH
	local balanceLeft = width - m - menu.podWidth
	local tabsX = m + backWidth + gap + (if titleWidth > 0 then titleWidth + gap else 0)
	local top = m
	local topHeight = MenuLayout.POD_HEIGHT
	local contentWidth = math.min(width - 2 * m, ShopLayout.CONTENT_MAX)

	local contentTop = top + topHeight + m
	local fourFit = contentWidth >= 4 * ShopLayout.SPIN_CARD_MIN_WIDTH + 3 * gap
	local spinCardHeight = if compact
		then math.clamp(
			height - contentTop - m - ShopLayout.SECTION_TITLE,
			ShopLayout.SPIN_CARD_MIN,
			ShopLayout.SPIN_CARD_HEIGHT_COMPACT
		)
		else ShopLayout.SPIN_CARD_HEIGHT

	local pageHeight = math.max(height - contentTop - m - ShopLayout.SECTION_TITLE, 0)

	local spinBoxTop = if compact then m else top + topHeight + m
	local spinTitleRow = if compact then 34 else 50
	local spinTile = if compact then 56 else 100
	local spinSideRoom = height
		- m
		- spinBoxTop
		- 2 * ShopLayout.SPIN_PADDING
		- spinTitleRow
		- spinTile
		- ShopLayout.SPIN_REEL_EXTRA
		- 2 * ShopLayout.SPIN_GAP

	return {
		compact = compact,
		paged = compact,
		pageHeight = pageHeight,
		top = top,
		topHeight = topHeight,
		barX = m,
		backWidth = backWidth,
		titleWidth = titleWidth,
		tabsX = tabsX,
		tabsWidth = math.min(balanceLeft - gap - tabsX, ShopLayout.TABS_MAX),
		balanceLeft = balanceLeft,
		contentX = (width - contentWidth) / 2,
		contentWidth = contentWidth,
		contentTop = contentTop,
		passColumns = if compact then 3 else 5,
		-- 4 tipos de giro (MockStore.SPIN_TYPES): uma fileira no PC e no celular
		-- largo; 2x2 só quando não cabe.
		spinColumns = if not compact or fourFit then 4 else 2,
		spinCardHeight = spinCardHeight,
		emberTop = if compact then 2 else 3,
		emberBottom = 2,
		bannerHeight = if compact then pageHeight else math.clamp(width * 0.2, 180, 300),
		spinSideBySide = true,
		spinBoxTop = spinBoxTop,
		spinTitleRow = spinTitleRow,
		spinTile = spinTile,
		spinSideHeight = math.min(spinSideRoom, ShopLayout.SPIN_SIDE_MAX),
	}
end

-- Grade dos gamepasses: colunas e altura do cartão. No PC, cartões de 236 em
-- pelo menos 5 colunas, e todos numa fileira se cada um ainda tiver
-- PASS_MIN_WIDTH_PC; na página do celular, uma fileira se couber (cartão ≥
-- PASS_MIN_WIDTH) e a altura dividida entre as fileiras.
-- `reserved`: altura já ocupada na página por cima da grade (a fileira do VIP).
function ShopLayout.passGrid(l: Layout, count: number, reserved: number?): (number, number)
	local gap = ShopLayout.GAP
	if not l.paged then
		local fit = math.floor((l.contentWidth + gap) / (ShopLayout.PASS_MIN_WIDTH_PC + gap))
		return math.max(l.passColumns, math.min(count, fit)), ShopLayout.PASS_CARD_HEIGHT
	end
	local fit = math.floor((l.contentWidth + gap) / (ShopLayout.PASS_MIN_WIDTH + gap))
	local columns = math.max(math.min(math.max(count, 1), fit), 1)
	local rows = math.ceil(math.max(count, 1) / columns)
	local room = l.pageHeight - (if reserved then reserved + gap else 0)
	local cardHeight = math.min(ShopLayout.PASS_CARD_HEIGHT, (room - (rows - 1) * gap) / rows)
	return columns, cardHeight
end

-- Altura da fileira de cima (VIP, boost, Premium).
function ShopLayout.topRowHeight(l: Layout): number
	return if l.paged then ShopLayout.TOP_ROW_HEIGHT_COMPACT else ShopLayout.TOP_ROW_HEIGHT
end

-- Pesos de largura na fileira de cima: VIP vale 2, boost e Premium 1; sem o
-- Premium (quem já é Premium não vê o cartão) a fileira é só VIP e boost.
function ShopLayout.topRowWeights(premiumShown: boolean): (number, number, number)
	return 2, 1, if premiumShown then 1 else 0
end

-- Largura (px) de cada cartão da fileira de cima numa lista de `width`: VIP,
-- boost e Premium (0 quando o Premium não aparece).
function ShopLayout.topRowWidths(width: number, premiumShown: boolean): (number, number, number)
	local vip, boost, premium = ShopLayout.topRowWeights(premiumShown)
	local total = vip + boost + premium
	local count = if premiumShown then 3 else 2
	local room = width - ShopLayout.GAP * (count - 1)
	return room * vip / total, room * boost / total, room * premium / total
end

-- Caixas de um cartão da fileira de cima de `width` × `height` (px, relativas
-- ao cartão). `compact`: faixa baixa do celular, sem ícone, textos e botão
-- lado a lado.
local function box(x: number, y: number, w: number, h: number): Box
	return { x = x, y = y, w = math.max(w, 0), h = math.max(h, 0) }
end

-- Recuo dos textos nas laterais do cartão de gamepass: longe da moldura.
function ShopLayout.passInset(width: number): number
	return math.clamp(width * 0.08, 8, 16)
end

-- Caixas do cartão de gamepass de `width` × `height` (px, relativas ao
-- cartão): ícone em cima, nome, descrição (se couber em duas linhas) e o
-- botão de preço embaixo.
function ShopLayout.passCardParts(width: number, height: number): PassCardParts
	local inset = ShopLayout.passInset(width)
	local textW = width - 2 * inset
	local tiny = height < ShopLayout.PASS_CARD_TINY
	local buttonH = if tiny then ShopLayout.PASS_BUTTON_TINY else ShopLayout.PASS_BUTTON
	local buttonW = width * 0.86
	local buttonY = height - ShopLayout.PASS_PAD - buttonH
	local button = box((width - buttonW) / 2, buttonY, buttonW, buttonH)
	if tiny then
		local nameY = height * 0.1
		return { icon = nil, name = box(inset, nameY, textW, buttonY - 4 - nameY), desc = nil, button = button }
	end
	local top = height * 0.06
	local nameH = math.clamp(height * 0.12, 18, 28)
	local room = buttonY - 6 - top -- do alto até acima do botão
	local maxIcon = math.min(width * 0.6, height * 0.42)
	local iconSide = math.min(height * 0.36, maxIcon)
	local descRoom = room - iconSide - 4 - nameH - 2
	local showDesc = height >= ShopLayout.PASS_CARD_SHORT and descRoom >= ShopLayout.PASS_DESC_MIN
	if not showDesc then
		-- Sem descrição, o ícone usa o lugar dela.
		iconSide = math.max(math.min(room - 4 - nameH, maxIcon), 0)
	end
	local icon = box((width - iconSide) / 2, top, iconSide, iconSide)
	local nameY = top + iconSide + 4
	local name = box(inset, nameY, textW, nameH)
	local desc = if showDesc
		then box(inset, nameY + nameH + 2, textW, math.min(descRoom, ShopLayout.PASS_DESC_MAX))
		else nil
	return { icon = icon, name = name, desc = desc, button = button }
end

function ShopLayout.bannerParts(width: number, height: number, compact: boolean): BannerParts
	local pad = ShopLayout.BANNER_PAD
	local gap = ShopLayout.BANNER_GAP
	local innerW = math.max(width - 2 * pad, 0)
	if compact then
		local vpad = 4
		local innerH = math.max(height - 2 * vpad, 0)
		local buttonW = innerW * ShopLayout.BANNER_BUTTON_SHARE
		local buttonH = innerH * 0.82
		local text = box(pad, vpad, innerW - buttonW - gap, innerH)
		local button = box(width - pad - buttonW, (height - buttonH) / 2, buttonW, buttonH)
		return { icon = nil, text = text, button = button, stacked = false }
	end
	if width < ShopLayout.BANNER_STACK_BELOW then
		local side = math.min(ShopLayout.BANNER_STACK_ICON, height * 0.4)
		local buttonH = ShopLayout.BANNER_STACK_BUTTON
		local textX = pad + side + gap
		local icon = box(pad, pad, side, side)
		local text = box(textX, pad, width - textX - pad, height - 2 * pad - buttonH - gap)
		local button = box(pad, height - pad - buttonH, innerW, buttonH)
		return { icon = icon, text = text, button = button, stacked = true }
	end
	local innerH = math.max(height - 2 * pad, 0)
	local side = innerH * 0.8
	local buttonW = innerW * ShopLayout.BANNER_BUTTON_SHARE
	local buttonH = innerH * 0.5
	local textX = pad + side + gap
	local buttonX = width - pad - buttonW
	local icon = box(pad, (height - side) / 2, side, side)
	local text = box(textX, pad, buttonX - gap - textX, innerH)
	local button = box(buttonX, (height - buttonH) / 2, buttonW, buttonH)
	return { icon = icon, text = text, button = button, stacked = false }
end

-- Altura dos cartões de Golden Ember na fileira única da página do celular.
function ShopLayout.emberCardHeight(l: Layout): number
	return math.min(ShopLayout.EMBER_CARD_HEIGHT, l.pageHeight)
end

return ShopLayout
