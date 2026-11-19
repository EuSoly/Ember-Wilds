--!strict
-- Desvio local dos mobs (puro, sem API do Roblox, para o Lune testar). Quando a
-- reta até o objetivo bate num círculo (recurso, peça, outro mob, jogador), o
-- mob troca a direção pela tangente do obstáculo, pelo lado mais curto até o
-- objetivo, e guarda o lado por MobRules.STEER_HOLD s: sem isso, parado bem
-- atrás do centro da pedra, ele alternaria esquerda/direita a cada passo.
-- Barato por passo (o servidor roda muitos mobs): só olha os círculos que o
-- servidor já juntou em volta do mob, até STEER_LOOKAHEAD studs; nada de grade
-- nem busca de caminho. Círculos colados (árvores lado a lado, parede de peças)
-- viram um obstáculo só porque a varredura de ângulo pula de um para o outro
-- enquanto a folga entre eles não deixa o corpo passar.
local MobRules = require("./MobRules")

export type Circle = { x: number, z: number, radius: number }

-- Lado do desvio: 1 = gira a direção no sentido anti-horário (ângulo de
-- atan2(z, x) crescendo), -1 = horário, 0 = nenhum ainda.
export type Memory = { side: number, untilAt: number }

-- Círculo perto visto do mob: o leque de direções que bateriam nele.
type Arc = {
	bearing: number, -- ângulo do centro, relativo à direção desejada
	half: number, -- meia abertura do leque
	x: number,
	z: number,
	reach: number, -- raio inflado (círculo + corpo do mob + folga)
	dist: number, -- distância do mob ao centro
}

local MARGIN = 0.25 -- studs além do encostar: a tangente passa sem raspar
local NUDGE = 1e-4 -- rad além da borda do leque (não ficar em cima da tangente)
local TIE = 1e-3 -- studs: caminhos mais parecidos que isso empatam
-- Studs: depois do prazo, só troca de lado se o outro for mais curto que isso
-- (o caminho muda pouco a cada passo; sem a folga, o empate volta a oscilar).
local SWITCH_BIAS = 1
local TAU = 2 * math.pi

local MobSteer = {}

function MobSteer.new(): Memory
	return { side = 0, untilAt = -math.huge }
end

-- Ângulo em [-pi, pi).
local function wrap(angle: number): number
	return (angle + math.pi) % TAU - math.pi
end

local function rotate(x: number, z: number, angle: number): (number, number)
	local c, s = math.cos(angle), math.sin(angle)
	return x * c - z * s, x * s + z * c
end

-- A direção `turn` (relativa à desejada) cai dentro de algum leque.
local function hits(arcs: { Arc }, turn: number): boolean
	for _, arc in arcs do
		if math.abs(wrap(arc.bearing - turn)) < arc.half then
			return true
		end
	end
	return false
end

-- Gira a direção para `side` até sair de todos os leques. Devolve o giro e o
-- círculo da borda (o último que empurrou), ou nil se passou de `maxTurn`
-- (cercado desse lado). Leques que se tocam são atravessados em sequência:
-- é assim que dois círculos colados viram um obstáculo só.
local function sweep(arcs: { Arc }, side: number, maxTurn: number): (number?, Arc?)
	local turn = 0
	local edge: Arc? = nil
	for _ = 1, #arcs + 1 do
		local moved = false
		for _, arc in arcs do
			local off = wrap(arc.bearing - turn)
			if math.abs(off) < arc.half then
				turn += off + side * (arc.half + NUDGE)
				edge = arc
				moved = true
			end
		end
		if math.abs(turn) > maxTurn then
			return nil, nil
		end
		if not moved then
			return turn, edge
		end
	end
	return nil, nil
end

-- Comprimento do caminho de (mx, mz) até (gx, gz) contornando o círculo da
-- borda pelo lado `side`: tangente até ele, arco pela beirada, tangente até o
-- objetivo (o caminho mais curto em volta de um disco). Girar a direção para
-- +1 faz o mob dar a volta no centro no sentido horário (ângulo diminuindo).
local function pathLength(mx: number, mz: number, gx: number, gz: number, arc: Arc, side: number): number
	local r = arc.reach
	local dM = arc.dist
	local dG = math.sqrt((gx - arc.x) ^ 2 + (gz - arc.z) ^ 2)
	local gammaM = if dM > r then math.acos(r / dM) else 0
	local gammaG = if dG > r then math.acos(r / dG) else 0
	local tM = math.sqrt(math.max(dM * dM - r * r, 0))
	local tG = math.sqrt(math.max(dG * dG - r * r, 0))
	local psiM = math.atan2(mz - arc.z, mx - arc.x)
	local psiG = math.atan2(gz - arc.z, gx - arc.x)
	local around = (side * ((psiM - side * gammaM) - (psiG + side * gammaG))) % TAU
	-- Os dois lados somam no máximo isso; passou = "arco negativo": as
	-- tangentes se cruzam e a reta já não encosta nesse círculo.
	local most = TAU - 2 * (gammaM + gammaG)
	if around > math.max(most, 0) + 1e-6 then
		return math.sqrt((gx - mx) ^ 2 + (gz - mz) ^ 2)
	end
	return tM + r * around + tG
end

-- Leques dos círculos perto de (x, z) que podem atrapalhar o caminho.
local function arcsAround(
	x: number,
	z: number,
	radius: number,
	heading: number,
	gx: number,
	gz: number,
	look: number,
	circles: { Circle }
): { Arc }
	local arcs: { Arc } = {}
	for _, c in circles do
		-- Círculo com o objetivo dentro (o próprio alvo, ou ponto de passeio
		-- dentro de uma árvore): não dá para contornar; ir reto é o melhor.
		if (gx - c.x) ^ 2 + (gz - c.z) ^ 2 < c.radius * c.radius then
			continue
		end
		local dx, dz = c.x - x, c.z - z
		local dist = math.sqrt(dx * dx + dz * dz)
		local r = c.radius + radius + MARGIN
		if dist < 1e-6 or dist - r >= look then
			continue
		end
		-- Encostado (o MobMove deixa o mob a raio + epsilon, dentro da folga):
		-- qualquer direção que se aproxima do centro bate.
		local half = if dist > r then math.asin(r / dist) else math.pi / 2
		table.insert(arcs, {
			bearing = wrap(math.atan2(dz, dx) - heading),
			half = half,
			x = c.x,
			z = c.z,
			reach = r,
			dist = dist,
		})
	end
	return arcs
end

-- Qual lado contornar (1 ou -1), com pelo menos um dos dois possível.
-- `turns`/`costs` por lado; `kept` = lado guardado; `holding` = ainda no prazo.
local function chooseSide(
	kept: number,
	holding: boolean,
	turns: { [number]: number },
	costs: { [number]: number }
): number
	local left, right = costs[1], costs[-1]
	local canKeep = kept ~= 0 and turns[kept] ~= nil
	-- Histerese: dentro do prazo, mantém o lado sem nem comparar.
	if canKeep and holding then
		return kept
	end
	if right == nil or left == nil then
		return if right == nil then 1 else -1
	end
	-- Prazo vencido: troca só se o outro lado ficou claramente mais curto.
	if canKeep and costs[-kept] > costs[kept] - SWITCH_BIAS then
		return kept
	end
	if math.abs(left - right) > TIE then
		return if left < right then 1 else -1
	end
	-- Empate no caminho: o que gira menos (empate total: anti-horário).
	return if math.abs(turns[-1]) < math.abs(turns[1]) - 1e-6 then -1 else 1
end

-- Direção para andar de (x, z), corpo `radius`, querendo ir na direção
-- (dirX, dirZ) até um objetivo a `reach` studs (perseguir: o alvo; fugir: um
-- ponto à frente). Caminho livre: devolve a direção pedida, sem mexer.
-- Bloqueado: a tangente do lado mais curto (ou o lado guardado em `memory`,
-- dentro do prazo). `maxTurn` limita o giro (fugindo, não volta para o
-- jogador); `blocked(x, z)` (água, borda do bioma) recusa o lado cujo
-- primeiro passo cairia lá. Sem lado possível, devolve a direção pedida (o
-- MobMove escorrega como antes).
function MobSteer.steer(
	memory: Memory,
	now: number,
	x: number,
	z: number,
	radius: number,
	dirX: number,
	dirZ: number,
	reach: number,
	maxTurn: number,
	circles: { Circle },
	blocked: ((number, number) -> boolean)?
): (number, number)
	local len = math.sqrt(dirX * dirX + dirZ * dirZ)
	if len < 1e-6 or reach <= 0 or #circles == 0 then
		return dirX, dirZ
	end
	local ux, uz = dirX / len, dirZ / len
	local gx, gz = x + ux * reach, z + uz * reach
	local look = math.min(reach, MobRules.STEER_LOOKAHEAD)
	local arcs = arcsAround(x, z, radius, math.atan2(uz, ux), gx, gz, look, circles)
	if not hits(arcs, 0) then
		-- Livre: esquece o lado depois do prazo (o próximo obstáculo é outro).
		if now >= memory.untilAt then
			memory.side = 0
		end
		return dirX, dirZ
	end

	local turns: { [number]: number } = {}
	local costs: { [number]: number } = {}
	for _, side in { 1, -1 } do
		local turn, edge = sweep(arcs, side, maxTurn)
		if turn == nil or edge == nil then
			continue
		end
		local sx, sz = rotate(ux, uz, turn)
		if blocked and blocked(x + sx * radius, z + sz * radius) then
			continue
		end
		turns[side] = turn
		costs[side] = pathLength(x, z, gx, gz, edge, side)
	end
	local left, right = costs[1], costs[-1]
	if left == nil and right == nil then
		return dirX, dirZ
	end

	local kept = memory.side
	local side = chooseSide(kept, now < memory.untilAt, turns, costs)
	if side ~= kept or now >= memory.untilAt then
		memory.side = side
		memory.untilAt = now + MobRules.STEER_HOLD
	end
	return rotate(ux, uz, turns[side])
end

return table.freeze(MobSteer)
