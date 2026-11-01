--!strict
-- Regras puras da construção: posição livre (círculos no chão), giro, dano e alcance.
-- A grade (CELL, cellOf...) fica até o servidor e o cliente migrarem. Rodam no servidor, cliente e testes.
local Types = require("../Defs/Types")

type ItemDef = Types.ItemDef
type StructureDef = Types.StructureDef

-- Sem limite hoje; tipado como number? para o servidor poder ler.
local MAX_PER_PLAYER: number? = nil

local BuildRules = {}
BuildRules.CELL = 4 -- studs
BuildRules.HAND_DAMAGE = 5
BuildRules.SPIKE_INTERVAL = 1 -- s por par espinho/vítima
BuildRules.MAX_PER_PLAYER = MAX_PER_PLAYER
BuildRules.PLAYER_RADIUS = 1.5 -- studs: raio do corpo (folga entre o jogador e a peça)
-- Studs da raiz até o ponto que escolhe a célula-alvo: meia célula + raio do
-- corpo (PLAYER_RADIUS) + meia célula. Olhando ao longo de um eixo, a célula-alvo nunca
-- fica encostada no corpo de quem constrói (sem isso, ~40% das posições eram
-- recusadas pelo próprio jogador).
BuildRules.REACH = BuildRules.CELL / 2 + BuildRules.PLAYER_RADIUS + BuildRules.CELL / 2

-- Construção livre: a peça é um círculo no chão, posto a PLACE_DISTANCE de quem constrói.
BuildRules.PIECE_RADIUS = 2 -- studs: meia largura do bloco provisório (raio padrão)
-- Raio da peça + corpo + raio da peça: em qualquer direção a peça fica encostada no
-- corpo de quem constrói sem tocá-lo.
BuildRules.PLACE_DISTANCE = BuildRules.PIECE_RADIUS + BuildRules.PLAYER_RADIUS + BuildRules.PIECE_RADIUS
BuildRules.ROTATE_STEP = 45 -- graus por aperto
BuildRules.ROTATE_STEPS = 8 -- giros válidos: 0..7

-- Centro da peça: a PLACE_DISTANCE de (x, z) na direção dir (vetor unitário no chão).
function BuildRules.placePoint(x: number, z: number, dirX: number, dirZ: number): (number, number)
	return x + dirX * BuildRules.PLACE_DISTANCE, z + dirZ * BuildRules.PLACE_DISTANCE
end

-- Yaw (graus, em torno de Y) para a frente da peça em (px, pz) olhar para (fromX, fromZ),
-- mais steps * ROTATE_STEP. Convenção do Roblox: o LookVector de um CFrame em yaw 0 é -Z e
-- CFrame.Angles(0, math.rad(yaw), 0) gira no sentido anti-horário visto de cima. A frente
-- no plano XZ vale (-sin(yaw), -cos(yaw)); logo, com steps = 0, o servidor monta
-- CFrame.new(px, 0, pz) * CFrame.Angles(0, math.rad(yaw), 0) e a frente aponta para o construtor.
function BuildRules.facingYaw(px: number, pz: number, fromX: number, fromZ: number, steps: number): number
	local dx, dz = fromX - px, fromZ - pz
	-- Resolve (-sin(yaw), -cos(yaw)) = (dx, dz) normalizado.
	local yaw = math.deg(math.atan2(-dx, -dz))
	return yaw + steps * BuildRules.ROTATE_STEP
end

-- Giro válido: inteiro de 0 a ROTATE_STEPS - 1 (rejeita fracionário, NaN, texto, nil).
function BuildRules.validSteps(steps: any): boolean
	return type(steps) == "number" and steps == math.floor(steps) and steps >= 0 and steps < BuildRules.ROTATE_STEPS
end

function BuildRules.radiusOf(def: StructureDef): number
	return def.radius or BuildRules.PIECE_RADIUS
end

-- Dois círculos se sobrepõem se a distância dos centros é menor que a soma dos raios;
-- encostar exatamente NÃO é sobrepor.
function BuildRules.circlesOverlap(ax: number, az: number, ar: number, bx: number, bz: number, br: number): boolean
	local dx, dz = ax - bx, az - bz
	local r = ar + br
	return dx * dx + dz * dz < r * r
end

-- O ponto está dentro do círculo da peça (centro cx, cz, raio r) expandido por margin.
function BuildRules.touchesCircle(px: number, pz: number, cx: number, cz: number, r: number, margin: number): boolean
	local dx, dz = px - cx, pz - cz
	local reach = r + margin
	return dx * dx + dz * dz <= reach * reach
end

-- Célula inteira que contém o ponto (floor: funciona com coordenadas negativas).
function BuildRules.cellOf(x: number, z: number): (number, number)
	return math.floor(x / BuildRules.CELL), math.floor(z / BuildRules.CELL)
end

function BuildRules.cellCenter(cx: number, cz: number): (number, number)
	return (cx + 0.5) * BuildRules.CELL, (cz + 0.5) * BuildRules.CELL
end

-- A célula à frente: a que contém o ponto a REACH studs na direção dir (vetor
-- unitário no plano do chão).
function BuildRules.targetCell(x: number, z: number, dirX: number, dirZ: number): (number, number)
	return BuildRules.cellOf(x + dirX * BuildRules.REACH, z + dirZ * BuildRules.REACH)
end

function BuildRules.key(cx: number, cz: number): string
	return `{cx},{cz}`
end

-- Chaves ocupadas por uma peça size×size com o canto em (cx, cz).
function BuildRules.cellsOf(cx: number, cz: number, size: number): { string }
	local out = {}
	for dx = 0, size - 1 do
		for dz = 0, size - 1 do
			table.insert(out, BuildRules.key(cx + dx, cz + dz))
		end
	end
	return out
end

function BuildRules.damageOf(item: ItemDef?): number
	if item ~= nil and item.structureDamage ~= nil then
		return item.structureDamage
	end
	return BuildRules.HAND_DAMAGE
end

-- Gancho dos times: hoje só o próprio jogador é aliado (UserIds).
function BuildRules.areAllies(a: number, b: number): boolean
	return a == b
end

function BuildRules.underLimit(count: number): boolean
	local max = BuildRules.MAX_PER_PLAYER
	return max == nil or count < max
end

-- O ponto está dentro do quadrado da peça (size células a partir de cx, cz) expandido por margin.
function BuildRules.touches(px: number, pz: number, cx: number, cz: number, size: number, margin: number): boolean
	local cell = BuildRules.CELL
	local minX = cx * cell - margin
	local minZ = cz * cell - margin
	local maxX = (cx + size) * cell + margin
	local maxZ = (cz + size) * cell + margin
	return px >= minX and px <= maxX and pz >= minZ and pz <= maxZ
end

return table.freeze(BuildRules)
