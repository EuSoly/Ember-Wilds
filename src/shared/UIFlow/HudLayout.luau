--!strict
-- Faixa de baixo do HUD no toque (puro, testado no Lune): joystick de mirar,
-- hotbar e anéis de status sem se sobreporem (12/11/2026). Medidas em px
-- lógicos da área do HUD (sem a barra do Roblox, já dividido pelo "Tamanho da
-- interface"). No PC a hotbar continua com o layout por escala de sempre.
--
-- Regra da seção 8 do design system: a hotbar cabe no espaço medido ENTRE os
-- controles (joystick de andar à esquerda, de mirar à direita). Se a linha de
-- 10 não couber, vira duas linhas de 5 (1–5 em cima, 6–0 embaixo). O slot
-- nunca encolhe abaixo do mínimo de toque.
local HudColumn = require("./HudColumn")

local HudLayout = {}

HudLayout.MARGIN = 12 -- px da borda da tela até os controles
HudLayout.SLOT = 44 -- px: mínimo de toque (Theme.slotMinSize)
HudLayout.GAP = 4 -- px entre slots
-- Borda direita do joystick de andar do Roblox em repouso (ThumbstickStart do
-- PlayerModule, medido: x 29..103 no celular deitado) mais uma folga.
HudLayout.MOVE_RESERVE = 112
-- Joystick de mirar: fração da altura, entre o mínimo e o máximo.
HudLayout.AIM_SHARE = 0.22
HudLayout.AIM_MIN = 110
HudLayout.AIM_MAX = 170
-- Anéis de status: um pouco maiores que o slot, presos acima da hotbar.
HudLayout.RING_SCALE = 1.25
HudLayout.RING_GAP = 6
HudLayout.RINGS_LIFT = 8 -- px entre a hotbar e os anéis
HudLayout.RING_COUNT = 4
-- Folga entre os anéis e os painéis que sobem acima deles (baú, caixa, peça).
HudLayout.PANEL_GAP = 8

function HudLayout.aimSize(height: number): number
	return math.clamp(math.round(height * HudLayout.AIM_SHARE), HudLayout.AIM_MIN, HudLayout.AIM_MAX)
end

export type Hotbar = {
	rows: number,
	columns: number,
	slot: number,
	gap: number,
	width: number,
	height: number,
	centerX: number, -- px, centro da hotbar
}

local function block(columns: number, rows: number): (number, number)
	local s, g = HudLayout.SLOT, HudLayout.GAP
	return columns * s + (columns - 1) * g, rows * s + (rows - 1) * g
end

-- Hotbar de 10 slots numa tela de toque `width` × `height`.
function HudLayout.touchHotbar(width: number, height: number): Hotbar
	local left = HudLayout.MOVE_RESERVE
	local right = width - HudLayout.MARGIN - HudLayout.aimSize(height) - HudLayout.MARGIN
	local columns, rows = 10, 1
	local w, h = block(columns, rows)
	if w > right - left then
		columns, rows = 5, 2
		w, h = block(columns, rows)
	end
	-- No centro da tela quando cabe; senão, o mais perto dele dentro do vão.
	local low, high = left + w / 2, right - w / 2
	local centerX = if low <= high then math.clamp(width / 2, low, high) else (left + right) / 2
	return {
		rows = rows,
		columns = columns,
		slot = HudLayout.SLOT,
		gap = HudLayout.GAP,
		width = w,
		height = h,
		centerX = centerX,
	}
end

-- Tamanho do bloco dos 4 anéis no toque (largura, altura).
function HudLayout.ringsSize(): (number, number)
	local ring = math.round(HudLayout.SLOT * HudLayout.RING_SCALE)
	return HudLayout.RING_COUNT * ring + (HudLayout.RING_COUNT - 1) * HudLayout.RING_GAP, ring
end

-- Quanto acima do topo da hotbar os painéis começam (px), no toque.
function HudLayout.panelLift(): number
	local _, ringHeight = HudLayout.ringsSize()
	return HudLayout.RINGS_LIFT + ringHeight + HudLayout.PANEL_GAP
end

-- Placar da partida no canto de cima à esquerda (UI/Leaderboard, no lugar do
-- antigo selo de pontos): a mesma conta do HudColumn.pillBottom. Base, em px.
-- `width` ficou do selo antigo (tinha aspecto fixo); não muda mais nada.
function HudLayout.scorePillBottom(_width: number, height: number): number
	return HudColumn.pillBottom(height)
end

-- Topo da coluna de receitas (UI/CraftColumn): 12% da tela, como sempre, mas
-- nunca antes de 8 px abaixo do selo. No celular o selo de 38 passava dos 12%
-- e a primeira receita encostava nele (17/11/2026).
function HudLayout.craftTop(width: number, height: number): number
	return math.max(0.12 * height, HudLayout.scorePillBottom(width, height) + 8)
end

return HudLayout
