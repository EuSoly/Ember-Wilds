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

-- Palavras pequenas que não entram nas iniciais ("Picareta de Madeira" → "PM").
local CONNECTORS = { de = true, da = true, ["do"] = true, das = true, dos = true, e = true }

-- Primeiros `count` caracteres de `word` (respeitando acentos em UTF-8).
local function firstChars(word: string, count: number): string
	local stop = utf8.offset(word, count + 1)
	return if stop then string.sub(word, 1, stop - 1) else word
end

-- Iniciais para o ícone provisório de um item (até os ícones desenhados chegarem).
-- Várias palavras: a primeira letra das duas primeiras palavras que contam.
-- Uma palavra só: as duas primeiras letras ("Frutinha" → "Fr").
function UIMath.initials(name: string): string
	local words = {}
	for word in string.gmatch(name, "%S+") do
		if not CONNECTORS[word] then
			table.insert(words, word)
		end
	end
	if #words == 0 then
		return ""
	end
	if #words == 1 then
		return string.upper(firstChars(words[1], 1)) .. firstChars(words[1], 2):sub(#firstChars(words[1], 1) + 1)
	end
	return string.upper(firstChars(words[1], 1)) .. string.upper(firstChars(words[2], 1))
end

-- Um toque/clique segurado vira "arrasto" quando o dedo anda mais que
-- `threshold` pixels; antes disso ainda é um toque simples.
function UIMath.isDrag(dx: number, dy: number, threshold: number): boolean
	return dx * dx + dy * dy > threshold * threshold
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
