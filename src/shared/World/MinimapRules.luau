--!strict
-- Regras puras do minimapa (11/11): ele mostra só o bioma onde o jogador está
-- (na cruz do oceano, o bioma mais perto), com uma seta na direção em que o
-- boneco olha. Na tela: cima = −Z e direita = +X (como a câmera do jogo).
-- Também o tamanho no canto: maior no PC, com o livro e a engrenagem alinhados
-- nas bordas de baixo do mapa.
local WorldConfig = require("../WorldConfig")

local MinimapRules = {}

export type Layout = {
	margin: number, -- px da borda direita da tela
	top: number, -- px do topo da tela
	mapSize: number, -- px do lado do mapa
	gap: number, -- px entre o mapa e os botões (e entre os botões)
	buttonSize: number, -- px do lado de cada botão
	buttonTop: number, -- px do topo da tela até os botões
	rowWidth: number, -- px da fileira de botões (livro na esquerda, engrenagem na direita)
}

local BUTTON_MIN = 44 -- mínimo de toque (Theme.touchMinSize)
local BUTTON_MAX = 68

-- Distância de (x, z) até o retângulo (0 dentro).
local function distanceTo(x: number, z: number, r: WorldConfig.Rect): number
	local dx = math.max(r.minX - x, 0, x - r.maxX)
	local dz = math.max(r.minZ - z, 0, z - r.maxZ)
	return math.sqrt(dx * dx + dz * dz)
end

-- Nome do bioma que o minimapa mostra para quem está em (x, z): o que o contém
-- ou, no oceano, o mais perto.
function MinimapRules.biomeAt(x: number, z: number): string
	local best, bestDistance = "forest", math.huge
	for name, area in WorldConfig.BIOMES :: { [string]: WorldConfig.Rect } do
		local distance = distanceTo(x, z, area)
		if distance < bestDistance or (distance == bestDistance and name < best) then
			best, bestDistance = name, distance
		end
	end
	return best
end

-- Posição (x, z) como fração (0 a 1) do retângulo mostrado; fora fica na borda.
function MinimapRules.toView(x: number, z: number, area: WorldConfig.Rect): (number, number)
	local fx = (x - area.minX) / (area.maxX - area.minX)
	local fz = (z - area.minZ) / (area.maxZ - area.minZ)
	return math.clamp(fx, 0, 1), math.clamp(fz, 0, 1)
end

-- Rotação (graus, horária, 0 = para cima) da seta para quem olha na direção
-- (lookX, lookZ) do mundo.
function MinimapRules.heading(lookX: number, lookZ: number): number
	return math.deg(math.atan2(lookX, -lookZ))
end

-- Medidas do canto para uma tela de `width` × `height` px; `short` = tela
-- baixa (celular deitado), onde o mapa fica menor.
function MinimapRules.layout(width: number, height: number, short: boolean): Layout
	local margin = math.round(width * 0.02)
	local top = math.round(height * 0.02)
	local mapSize = if short
		then math.clamp(math.round(height * 0.22), 72, 120)
		else math.clamp(math.round(height * 0.25), 150, 210)
	local gap = 8
	local buttonSize = math.clamp(math.round(mapSize * 0.34), BUTTON_MIN, BUTTON_MAX)
	return {
		margin = margin,
		top = top,
		mapSize = mapSize,
		gap = gap,
		buttonSize = buttonSize,
		buttonTop = top + mapSize + gap,
		rowWidth = math.max(mapSize, 2 * buttonSize + gap),
	}
end

return table.freeze(MinimapRules)
