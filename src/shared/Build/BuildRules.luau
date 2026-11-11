--!strict
-- Regras puras da construção: posição livre (círculos no chão), giro, dano e alcance.
-- Rodam no servidor, cliente e testes.
local Types = require("../Defs/Types")

type ItemDef = Types.ItemDef
type StructureDef = Types.StructureDef

-- Sem limite hoje; tipado como number? para o servidor poder ler.
local MAX_PER_PLAYER: number? = nil

local BuildRules = {}
BuildRules.HAND_DAMAGE = 5
BuildRules.SPIKE_INTERVAL = 1 -- s por par espinho/vítima
BuildRules.MAX_PER_PLAYER = MAX_PER_PLAYER
BuildRules.MOB_SPIKE_SLACK = 0.3 -- studs: folga além do raio do mob para o espinho feri-lo (o MobMove o deixa a raio + EPSILON do círculo)
BuildRules.PLAYER_RADIUS = 1.5 -- studs: raio do corpo (folga entre o jogador e a peça)

-- Construção livre: a peça é um círculo no chão, posto a PLACE_DISTANCE de quem constrói.
BuildRules.PIECE_RADIUS = 2 -- studs: meia largura do bloco provisório (raio padrão)
-- Raio da peça + corpo + raio da peça: em qualquer direção a peça fica encostada no
-- corpo de quem constrói sem tocá-lo.
BuildRules.PLACE_DISTANCE = BuildRules.PIECE_RADIUS + BuildRules.PLAYER_RADIUS + BuildRules.PIECE_RADIUS
BuildRules.ROTATE_STEP = 45 -- graus por aperto
BuildRules.ROTATE_STEPS = 8 -- giros válidos: 0..7
-- Altura (studs) da base do telhado acima do chão: acima da cabeça do boneco. -- provisório (ajustar na bancada)
BuildRules.ROOF_HEIGHT = 3

-- Camada da peça: a ponte fica no chão da água, o telhado no alto e o resto
-- (sólida) no chão, segurando corpos. Peças só disputam lugar na mesma camada.
export type Layer = "solid" | "bridge" | "roof"

-- Círculo no chão (centro x, z e raio r), visto de cima.
export type Circle = { x: number, z: number, r: number }

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

-- Encaixe em grade das peças de chão e teto (`structure.snap`: telhado, ponte,
-- canteiros no futuro). Vizinha = peça já colocada da mesma camada com snap.
export type SnapNeighbor = { x: number, z: number, yaw: number, radius: number }

-- Folga (studs) além do diâmetro da vizinha em que ela ainda puxa a peça.
BuildRules.SNAP_RANGE = 3

-- Onde a peça sai: na casa da grade da vizinha mais perto de (x, z), com o giro
-- dela. A casa tem o lado do diâmetro da vizinha e os eixos dela. Ponto em cima
-- da própria vizinha vai para a casa ao lado na direção (dirX, dirZ) para onde
-- o jogador olha. Vizinha ao alcance = centro a até 2 × raio dela + SNAP_RANGE
-- do ponto livre; aí a peça sempre vai para a casa mais próxima (sem zona morta
-- nos cantos). Sem vizinha ao alcance, devolve (x, z, yaw) sem mudar. Servidor e
-- fantasma usam a mesma conta.
function BuildRules.snapPlacement(
	x: number,
	z: number,
	yaw: number,
	dirX: number,
	dirZ: number,
	neighbors: { SnapNeighbor }
): (number, number, number)
	local best: SnapNeighbor? = nil
	local bestSq = math.huge
	for _, neighbor in neighbors do
		local reach = 2 * neighbor.radius + BuildRules.SNAP_RANGE
		local sq = (neighbor.x - x) ^ 2 + (neighbor.z - z) ^ 2
		if sq <= reach * reach and sq < bestSq then
			best, bestSq = neighbor, sq
		end
	end
	if best == nil then
		return x, z, yaw
	end
	local angle = math.rad(best.yaw)
	local cos, sin = math.cos(angle), math.sin(angle)
	-- Eixos da vizinha no chão (CFrame.Angles(0, yaw, 0)): X local = (cos, −sin), Z local = (sin, cos).
	local function toLocal(wx: number, wz: number): (number, number)
		return wx * cos - wz * sin, wx * sin + wz * cos
	end
	local side = 2 * best.radius
	local lx, lz = toLocal(x - best.x, z - best.z)
	local ix, iz = math.round(lx / side), math.round(lz / side)
	if ix == 0 and iz == 0 then
		local dlx, dlz = toLocal(dirX, dirZ)
		if math.abs(dlx) >= math.abs(dlz) then
			ix = if dlx >= 0 then 1 else -1
		else
			iz = if dlz >= 0 then 1 else -1
		end
	end
	local cellX = best.x + (ix * cos + iz * sin) * side
	local cellZ = best.z + (-ix * sin + iz * cos) * side
	return cellX, cellZ, best.yaw
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

-- O ponto está dentro (ou na borda) de algum dos círculos, cada um expandido
-- por `margin` (padrão 0)? Lista vazia = não.
function BuildRules.insideAny(x: number, z: number, circles: { Circle }, margin: number?): boolean
	local reach = margin or 0
	for _, circle in circles do
		if BuildRules.touchesCircle(x, z, circle.x, circle.z, circle.r, reach) then
			return true
		end
	end
	return false
end

function BuildRules.layerOf(kind: string): Layer
	if kind == "bridge" then
		return "bridge"
	elseif kind == "roof" then
		return "roof"
	end
	return "solid"
end

-- A peça segura corpos no chão (colide)? Ponte e telhado não: anda-se por cima
-- da ponte e por baixo do telhado.
function BuildRules.isSolid(kind: string): boolean
	return BuildRules.layerOf(kind) == "solid"
end

-- Uma peça `kind` sobrepondo outra `otherKind` impede colocar? Só na mesma
-- camada: ponte com ponte, telhado com telhado, sólida com sólida.
function BuildRules.blocksPlacement(kind: string, otherKind: string): boolean
	return BuildRules.layerOf(kind) == BuildRules.layerOf(otherKind)
end

-- O jogador com a raiz em (x, z) está sobre uma das pontes? Conta com a margem
-- do corpo (PLAYER_RADIUS): as pontes não se sobrepõem e o colocar padrão as
-- deixa a PLACE_DISTANCE uma da outra, e sem a margem cada emenda seria água
-- (Ruling 11).
function BuildRules.onBridge(x: number, z: number, bridges: { Circle }): boolean
	return BuildRules.insideAny(x, z, bridges, BuildRules.PLAYER_RADIUS)
end

-- A água bruta no ponto (`water`, sem contar ponte) deixa colocar a peça? A
-- ponte só vai na água; o resto nunca (ponte não torna a água construível).
function BuildRules.waterAllows(kind: string, water: boolean): boolean
	if BuildRules.layerOf(kind) == "bridge" then
		return water
	end
	return not water
end

-- Margem do espinho para um mob de raio `mobRadius`: o corpo mais a folga.
function BuildRules.mobSpikeMargin(mobRadius: number): number
	return mobRadius + BuildRules.MOB_SPIKE_SLACK
end

-- Dano de um golpe numa construção. Martelo contra material acima do dele
-- (ordem dos tiers: `structureTier` > `itemTier`) dá só hammer.minDamage;
-- construção ou martelo sem tier = dano cheio.
function BuildRules.damageOf(item: ItemDef?, structureTier: number?, itemTier: number?): number
	if item == nil or item.structureDamage == nil then
		return BuildRules.HAND_DAMAGE
	end
	local hammer = item.hammer
	if hammer and structureTier and itemTier and structureTier > itemTier then
		return hammer.minDamage
	end
	return item.structureDamage
end

-- Dano em quem BATE numa peça (espinho e porta com espinhos, Starve "hit"):
-- 0 para o dono e os aliados, e para peça sem spikeHitDamage.
function BuildRules.spikeHitDamage(def: StructureDef, allied: boolean): number
	if allied or def.spikeHitDamage == nil then
		return 0
	end
	return def.spikeHitDamage
end

-- Vida que a chave inglesa devolve a uma construção (0 sem chave ou cheia).
function BuildRules.repairAmount(item: ItemDef?, health: number, maxHealth: number): number
	local repair = item and item.repair
	if repair == nil then
		return 0
	end
	return math.clamp(maxHealth - health, 0, repair)
end

-- Gancho dos times: hoje só o próprio jogador é aliado (UserIds).
function BuildRules.areAllies(a: number, b: number): boolean
	return a == b
end

-- Abre e fecha como porta (porta comum e porta com espinhos).
function BuildRules.isDoor(kind: string): boolean
	return kind == "door" or kind == "spike_door"
end

-- Fere quem não é aliado, aberta ou fechada (espinho e porta com espinhos).
function BuildRules.hurts(kind: string): boolean
	return kind == "spike" or kind == "spike_door"
end

function BuildRules.underLimit(count: number): boolean
	local max = BuildRules.MAX_PER_PLAYER
	return max == nil or count < max
end

return table.freeze(BuildRules)
