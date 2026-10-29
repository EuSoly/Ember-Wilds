--!strict
-- Contas da interface (só números: testável no Lune).

local UIMath = {}

-- Fração 0..1 de `value` em `max`. Valores fora da faixa (ou NaN) nunca
-- quebram a interface: viram 0 ou 1.
function UIMath.fraction(value: number, max: number): number
	local f = value / max
	if f ~= f then -- NaN
		return 0
	end
	return math.clamp(f, 0, 1)
end

-- Anel contínuo feito de duas metades (direita e esquerda), cada uma com um
-- UIGradient de corte seco no meio. Devolve a Rotation (graus) do gradiente de
-- cada metade para mostrar o arco de `fraction`, começando no topo (12 h) e
-- seguindo no sentido horário. A metade direita cobre 0..50% e a esquerda 50..100%.
function UIMath.ringRotations(fraction: number): (number, number)
	local degrees = 360 * math.clamp(fraction, 0, 1)
	local right = math.min(degrees, 180)
	local left = math.max(degrees - 180, 0) + 180
	return right, left
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
