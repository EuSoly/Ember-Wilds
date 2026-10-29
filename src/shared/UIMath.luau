--!strict
-- Contas da interface (só números: testável no Lune).

local UIMath = {}

-- Quantos segmentos de um anel ficam acesos para `value` de `max`.
-- Valores fora da faixa (ou NaN) nunca quebram o anel: viram 0 ou cheio.
function UIMath.filledCount(value: number, max: number, segments: number): number
	local fraction = value / max
	if fraction ~= fraction then -- NaN
		return 0
	end
	return math.round(math.clamp(fraction, 0, 1) * segments)
end

-- Ângulo (radianos, coordenadas de tela) do centro do segmento `index`.
-- O segmento 1 fica no topo (12 h) e os seguintes vão no sentido horário.
function UIMath.segmentAngle(index: number, segments: number): number
	return -math.pi / 2 + (index - 1) * 2 * math.pi / segments
end

-- Joystick: a partir do deslocamento do dedo (dx, dy) em pixels, devolve a
-- direção unitária (x para a direita, y para baixo) e se está ativo.
-- Dentro da zona morta fica inativo. Como a câmera não gira, essa direção de
-- tela é exatamente o (x, z) do mundo que a ação de mira espera.
function UIMath.stick(dx: number, dy: number, radius: number, deadzone: number): (number, number, boolean)
	local length = math.sqrt(dx * dx + dy * dy)
	if length < deadzone or radius <= 0 then
		return 0, 0, false
	end
	return dx / length, dy / length, true
end

return UIMath
