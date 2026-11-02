--!strict
-- Cérebro do mob, puro (sem API do Roblox, para o Lune testar): decide o que o
-- mob quer fazer a cada passo (passear, perseguir, fugir, morder, voar). O
-- servidor chama `think` a cada tick e aplica a intenção; nada aqui move o mob.
-- Chamar `think` duas vezes no mesmo instante com as mesmas entradas não muda o
-- cérebro: toda troca de estado depende de um prazo que ela mesma empurra.
local BuildRules = require("../Build/BuildRules")
local MobRules = require("./MobRules")
local Rng = require("../World/Rng")
local Types = require("../Defs/Types")

type MobDef = Types.MobDef
type MobStats = Types.MobStats
type Rng = Rng.Rng

export type Mode = "wander" | "chase" | "flee"

-- Jogador vivo, no chão, no bioma.
export type Seen = { who: any, x: number, z: number }

export type Brain = {
	mode: Mode,
	target: any?,
	homeX: number,
	homeZ: number,
	lastHitAt: number, -- último golpe do alvo (o início da perseguição conta)
	calmUntil: number, -- depois de desistir, não persegue sozinho até aqui
	nextBiteAt: number,
	lastWebAt: number,
	fleeUntil: number, -- passivo: fuga depois de apanhar
	fleeFromX: number, -- onde estava quem bateu
	fleeFromZ: number,
	wanderX: number?, -- ponto do passeio (nil = em pausa)
	wanderZ: number?,
	pauseUntil: number,
	flying: boolean,
	switchAt: number, -- voador: quando acaba o voo (ou o tempo no chão)
}

export type Intent = {
	dirX: number, -- direção (unitária ou 0,0 = parado)
	dirZ: number,
	speed: number, -- studs/s
	bite: any?, -- quem morder agora (o servidor aplica o dano)
	web: boolean, -- essa mordida prende na teia
	flying: boolean,
	hostile: boolean, -- vai para MobHostile
	wantsLand: boolean, -- voando e querendo pousar (o servidor diz se pode com canLand)
}

local WANDER_PAUSE = { 1, 4 } -- segundos parado ao chegar no ponto do passeio
local ARRIVE = 1 -- studs: perto disso o ponto do passeio conta como alcançado

local MobBrain = {}

local function draw(rng: Rng, range: { number }): number
	return range[1] + rng:nextNumber() * (range[2] - range[1])
end

local function unit(dx: number, dz: number): (number, number)
	local length = math.sqrt(dx * dx + dz * dz)
	if length < 1e-6 then
		return 0, 0
	end
	return dx / length, dz / length
end

local function distance(x: number, z: number, otherX: number, otherZ: number): number
	return math.sqrt((otherX - x) ^ 2 + (otherZ - z) ^ 2)
end

-- Recomeça o passeio: o próximo `think` sorteia um ponto novo.
local function restartWander(brain: Brain, now: number)
	brain.wanderX, brain.wanderZ = nil, nil
	brain.pauseUntil = now
end

local function startChase(brain: Brain, who: any, now: number)
	brain.mode = "chase"
	brain.target = who
	brain.lastHitAt = now
end

local function giveUp(brain: Brain, now: number)
	brain.mode = "wander"
	brain.target = nil
	brain.calmUntil = now + MobRules.CALM_TIME
	restartWander(brain, now)
end

local function land(brain: Brain, now: number, rng: Rng)
	brain.flying = false
	brain.switchAt = now + draw(rng, MobRules.GROUND_TIME)
end

function MobBrain.new(def: MobDef, homeX: number, homeZ: number, now: number, rng: Rng): Brain
	local stats = def.stats
	local flies = stats ~= nil and stats.flies == true
	return {
		mode = "wander",
		target = nil,
		homeX = homeX,
		homeZ = homeZ,
		lastHitAt = -math.huge,
		calmUntil = -math.huge,
		nextBiteAt = -math.huge,
		lastWebAt = -math.huge,
		fleeUntil = -math.huge,
		fleeFromX = homeX,
		fleeFromZ = homeZ,
		wanderX = nil,
		wanderZ = nil,
		pauseUntil = now,
		flying = false, -- nasce no chão (o ponto de nascer é chão livre)
		switchAt = if flies then now + draw(rng, MobRules.GROUND_TIME) else math.huge,
	}
end

-- Golpe de um jogador. Passivo: foge por FLEE_AFTER_HIT. Os outros: o próprio
-- alvo reinicia o tempo de desistir; sem perseguir, quem bateu vira o alvo
-- (mesmo na calma). Golpe de outro jogador durante a perseguição não muda nada.
function MobBrain.onHit(brain: Brain, def: MobDef, attacker: any, attackerX: number, attackerZ: number, now: number)
	if def.behavior == "passive" then
		brain.fleeUntil = math.max(brain.fleeUntil, now + MobRules.FLEE_AFTER_HIT)
		brain.fleeFromX, brain.fleeFromZ = attackerX, attackerZ
	elseif brain.mode ~= "chase" then
		startChase(brain, attacker, now)
	elseif attacker == brain.target then
		brain.lastHitAt = math.max(brain.lastHitAt, now)
	end
end

-- Passivo: foge de quem está perto, ou, por um tempo depois de apanhar, de onde
-- estava quem bateu.
local function thinkPassive(
	brain: Brain,
	stats: MobStats,
	now: number,
	x: number,
	z: number,
	nearest: Seen?,
	intent: Intent
)
	local fromX, fromZ
	if nearest ~= nil and distance(x, z, nearest.x, nearest.z) <= MobRules.FLEE_RADIUS then
		fromX, fromZ = nearest.x, nearest.z
	elseif now < brain.fleeUntil then
		fromX, fromZ = brain.fleeFromX, brain.fleeFromZ
	end

	if fromX == nil or fromZ == nil then
		if brain.mode == "flee" then
			brain.mode = "wander"
			restartWander(brain, now)
		end
		return
	end

	brain.mode = "flee"
	local dirX, dirZ = unit(x - fromX, z - fromZ)
	if dirX == 0 and dirZ == 0 then
		-- Jogador bem em cima: foge para longe de casa (ou para um lado qualquer).
		dirX, dirZ = unit(x - brain.homeX, z - brain.homeZ)
		if dirX == 0 and dirZ == 0 then
			dirX = 1
		end
	end
	intent.dirX, intent.dirZ = dirX, dirZ
	intent.speed = stats.speed
end

-- Perseguindo: vai atrás do alvo; voando, pousa perto dele; no chão, morde.
local function chase(
	brain: Brain,
	stats: MobStats,
	now: number,
	x: number,
	z: number,
	seen: Seen,
	canLand: boolean,
	rng: Rng,
	intent: Intent
)
	local gap = distance(x, z, seen.x, seen.z)
	if brain.flying and gap <= MobRules.LAND_RANGE then
		if canLand then
			land(brain, now, rng)
		else
			intent.wantsLand = true
		end
	end

	intent.dirX, intent.dirZ = unit(seen.x - x, seen.z - z)
	intent.speed = stats.speed

	local reach = stats.radius + MobRules.BITE_REACH + BuildRules.PLAYER_RADIUS
	if not brain.flying and stats.bite ~= nil and gap <= reach and now >= brain.nextBiteAt then
		intent.bite = brain.target
		brain.nextBiteAt = now + MobRules.BITE_INTERVAL
		local web = stats.web
		if web ~= nil and now - brain.lastWebAt >= web.cooldown then
			intent.web = true
			brain.lastWebAt = now
		end
	end
end

-- Agressivo e neutro: começa, segue ou desiste da perseguição.
local function thinkHunter(
	brain: Brain,
	def: MobDef,
	stats: MobStats,
	now: number,
	x: number,
	z: number,
	nearest: Seen?,
	target: Seen?,
	canLand: boolean,
	rng: Rng,
	intent: Intent
)
	if
		brain.mode ~= "chase"
		and def.behavior == "aggressive"
		and now >= brain.calmUntil
		and nearest ~= nil
		and distance(x, z, nearest.x, nearest.z) <= MobRules.SENSE_RADIUS
	then
		startChase(brain, nearest.who, now)
	end
	if brain.mode ~= "chase" then
		return
	end

	-- O alvo também pode chegar como o mais perto (ex. no passo em que foi visto).
	local seen = target
	if seen == nil and nearest ~= nil and nearest.who == brain.target then
		seen = nearest
	end
	if seen == nil or now - brain.lastHitAt >= MobRules.GIVE_UP then
		giveUp(brain, now)
		return
	end
	chase(brain, stats, now, x, z, seen, canLand, rng, intent)
end

-- Passeio: ponto ao acaso perto de casa, devagar, com pausas ao chegar.
local function wander(brain: Brain, stats: MobStats, now: number, x: number, z: number, rng: Rng, intent: Intent)
	if brain.wanderX == nil and now >= brain.pauseUntil then
		local angle = rng:nextNumber() * 2 * math.pi
		local radius = math.sqrt(rng:nextNumber()) * MobRules.WANDER_RADIUS
		brain.wanderX = brain.homeX + math.cos(angle) * radius
		brain.wanderZ = brain.homeZ + math.sin(angle) * radius
	end
	local wanderX, wanderZ = brain.wanderX, brain.wanderZ
	if wanderX == nil or wanderZ == nil then
		return
	end
	if distance(x, z, wanderX, wanderZ) <= ARRIVE then
		brain.wanderX, brain.wanderZ = nil, nil
		brain.pauseUntil = now + draw(rng, WANDER_PAUSE)
		return
	end
	intent.dirX, intent.dirZ = unit(wanderX - x, wanderZ - z)
	intent.speed = stats.speed * MobRules.WANDER_SPEED
end

-- Voador fora da perseguição: alterna voo e chão nos tempos sorteados. Acabou o
-- voo: só pousa com chão livre; até lá continua voando e querendo pousar.
local function alternateFlight(brain: Brain, now: number, canLand: boolean, rng: Rng, intent: Intent)
	if now < brain.switchAt then
		return
	end
	if not brain.flying then
		brain.flying = true
		brain.switchAt = now + draw(rng, MobRules.FLY_TIME)
	elseif canLand then
		land(brain, now, rng)
	else
		intent.wantsLand = true
	end
end

-- `nearest` = jogador mais perto; `target` = posição atual do alvo (nil se sumiu).
-- Perseguindo no chão, o voador não decola (para poder morder); volta a
-- alternar quando desiste. Só faz sentido para mobs com `stats`.
function MobBrain.think(
	brain: Brain,
	def: MobDef,
	now: number,
	x: number,
	z: number,
	nearest: Seen?,
	target: Seen?,
	canLand: boolean,
	rng: Rng
): Intent
	local stats = def.stats :: MobStats
	local intent: Intent = {
		dirX = 0,
		dirZ = 0,
		speed = 0,
		bite = nil,
		web = false,
		flying = false,
		hostile = false,
		wantsLand = false,
	}

	if def.behavior == "passive" then
		thinkPassive(brain, stats, now, x, z, nearest, intent)
	else
		thinkHunter(brain, def, stats, now, x, z, nearest, target, canLand, rng, intent)
	end
	if stats.flies and brain.mode ~= "chase" then
		alternateFlight(brain, now, canLand, rng, intent)
	end
	if brain.mode == "wander" then
		wander(brain, stats, now, x, z, rng, intent)
	end

	intent.flying = brain.flying
	intent.hostile = def.behavior == "aggressive" or (def.behavior == "neutral" and brain.mode == "chase")
	return intent
end

return table.freeze(MobBrain)
