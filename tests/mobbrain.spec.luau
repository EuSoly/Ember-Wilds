--!strict
local Defs = require("../src/shared/Defs")
local MobBrain = require("../src/shared/Mobs/MobBrain")
local MobRules = require("../src/shared/Mobs/MobRules")
local Rng = require("../src/shared/World/Rng")

local wolf = Defs.Mobs.wolf -- agressivo, raio 2
local WOLF_SPEED = (wolf.stats :: any).speed
local spider = Defs.Mobs.spider -- agressivo com teia (2 s, recarga 6 s)
local boar = Defs.Mobs.boar -- neutro
local hawk = Defs.Mobs.hawk -- neutro, voador
local rabbit = Defs.Mobs.rabbit -- passivo
local RABBIT_SPEED = (rabbit.stats :: any).speed

local P1 = { name = "p1" }
local P2 = { name = "p2" }

local function seen(who: any, x: number, z: number): MobBrain.Seen
	return { who = who, x = x, z = z }
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

-- Cópia rasa do cérebro, para comparar antes/depois.
local function snapshot(brain: MobBrain.Brain): { [string]: any }
	return table.clone(brain :: any)
end

local function sameSnapshot(a: { [string]: any }, b: { [string]: any }): boolean
	for key, value in a do
		if b[key] ~= value then
			return false
		end
	end
	for key, value in b do
		if a[key] ~= value then
			return false
		end
	end
	return true
end

-- Mob perseguindo P1 desde `now` (agressivo vendo P1 a 10 studs, fora da mordida).
local function chasing(def: any, now: number): (MobBrain.Brain, any)
	local rng = Rng.new(7)
	local brain = MobBrain.new(def, 0, 0, now, rng)
	if def.behavior == "aggressive" then
		MobBrain.think(brain, def, now, 0, 0, seen(P1, 10, 0), nil, true, rng)
	else
		MobBrain.onHit(brain, def, P1, 10, 0, now)
	end
	assert(brain.mode == "chase" and brain.target == P1, "deveria estar perseguindo P1")
	return brain, rng
end

return {
	["agressivo vê a 18 e não a 19"] = function()
		local rng = Rng.new(1)
		local far = MobBrain.new(wolf, 0, 0, 0, rng)
		MobBrain.think(far, wolf, 0, 0, 0, seen(P1, 19, 0), nil, true, rng)
		assert(far.mode == "wander" and far.target == nil, "a 19 não deveria ver")

		local close = MobBrain.new(wolf, 0, 0, 0, rng)
		local intent = MobBrain.think(close, wolf, 0, 0, 0, seen(P1, 18, 0), nil, true, rng)
		assert(close.mode == "chase" and close.target == P1, "a 18 deveria perseguir")
		assert(near(intent.dirX, 1) and near(intent.dirZ, 0), "deveria ir na direção do jogador")
		assert(intent.speed == WOLF_SPEED, "perseguindo vai na velocidade cheia")
	end,

	["persegue sem desistir por distância"] = function()
		local brain, rng = chasing(wolf, 0)
		local intent = MobBrain.think(brain, wolf, 5, 0, 0, nil, seen(P1, 500, 0), true, rng)
		assert(brain.mode == "chase" and brain.target == P1, "alvo a 500 studs continua")
		assert(near(intent.dirX, 1) and intent.speed == WOLF_SPEED, "continua indo atrás")
	end,

	["desiste aos 10 s sem golpe; golpe aos 9 s empurra"] = function()
		local brain, rng = chasing(wolf, 0)
		MobBrain.think(brain, wolf, 9.9, 0, 0, nil, seen(P1, 30, 0), true, rng)
		assert(brain.mode == "chase", "aos 9,9 s ainda persegue")
		MobBrain.think(brain, wolf, 10, 0, 0, nil, seen(P1, 30, 0), true, rng)
		assert(brain.mode == "wander" and brain.target == nil, "aos 10 s desiste")

		local pushed, rng2 = chasing(boar, 0)
		MobBrain.onHit(pushed, boar, P1, 5, 0, 9)
		MobBrain.think(pushed, boar, 18.9, 0, 0, nil, seen(P1, 30, 0), true, rng2)
		assert(pushed.mode == "chase", "golpe aos 9 s empurra para 19 s")
		MobBrain.think(pushed, boar, 19, 0, 0, nil, seen(P1, 30, 0), true, rng2)
		assert(pushed.mode == "wander" and pushed.target == nil, "aos 19 s desiste")
	end,

	["golpe de outro jogador durante a perseguição não troca o alvo nem empurra"] = function()
		local brain, rng = chasing(wolf, 0)
		MobBrain.onHit(brain, wolf, P2, 3, 0, 9)
		assert(brain.target == P1, "continua no alvo")
		MobBrain.think(brain, wolf, 10, 0, 0, nil, seen(P1, 30, 0), true, rng)
		assert(brain.mode == "wander", "golpe de outro não empurra")
	end,

	["depois de desistir não persegue por 5 s"] = function()
		local brain, rng = chasing(wolf, 0)
		MobBrain.think(brain, wolf, 10, 0, 0, seen(P1, 5, 0), seen(P1, 5, 0), true, rng)
		assert(brain.mode == "wander", "desistiu")
		MobBrain.think(brain, wolf, 14.9, 0, 0, seen(P1, 5, 0), nil, true, rng)
		assert(brain.mode == "wander", "na calma não persegue")
		MobBrain.think(brain, wolf, 15, 0, 0, seen(P2, 5, 0), nil, true, rng)
		assert(brain.mode == "chase" and brain.target == P2, "passada a calma persegue")
	end,

	["golpe na calma faz perseguir"] = function()
		local brain, rng = chasing(wolf, 0)
		MobBrain.think(brain, wolf, 10, 0, 0, nil, nil, true, rng)
		MobBrain.onHit(brain, wolf, P2, 4, 0, 11)
		assert(brain.mode == "chase" and brain.target == P2, "quem bate vira o alvo")
	end,

	["alvo nil faz desistir"] = function()
		local brain, rng = chasing(wolf, 0)
		local intent = MobBrain.think(brain, wolf, 1, 0, 0, seen(P2, 30, 0), nil, true, rng)
		assert(brain.mode == "wander" and brain.target == nil, "alvo sumiu: desiste")
		assert(intent.bite == nil, "sem alvo não morde")
		MobBrain.think(brain, wolf, 2, 0, 0, seen(P2, 5, 0), nil, true, rng)
		assert(brain.mode == "wander", "e fica calmo depois de desistir")
	end,

	["neutro ignora jogador perto até apanhar"] = function()
		local rng = Rng.new(3)
		local brain = MobBrain.new(boar, 0, 0, 0, rng)
		local intent = MobBrain.think(brain, boar, 0, 0, 0, seen(P1, 2, 0), nil, true, rng)
		assert(brain.mode == "wander" and not intent.hostile, "neutro não liga para quem está perto")
		MobBrain.onHit(brain, boar, P1, 2, 0, 1)
		intent = MobBrain.think(brain, boar, 1, 0, 0, seen(P1, 2, 0), seen(P1, 2, 0), true, rng)
		assert(brain.mode == "chase" and brain.target == P1, "apanhou: persegue quem bateu")
		assert(intent.hostile, "bravo fica hostil")
	end,

	["mordida respeita alcance e intervalo"] = function()
		local reach = (wolf.stats :: any).radius + MobRules.BITE_REACH + 1.5
		local brain, rng = chasing(wolf, 0)
		local intent = MobBrain.think(brain, wolf, 0.1, 0, 0, nil, seen(P1, reach + 0.1, 0), true, rng)
		assert(intent.bite == nil, "fora do alcance não morde")
		intent = MobBrain.think(brain, wolf, 0.2, 0, 0, nil, seen(P1, reach, 0), true, rng)
		assert(intent.bite == P1, "no alcance morde o alvo")
		assert(intent.web == false, "lobo não tem teia")
		intent = MobBrain.think(brain, wolf, 0.7, 0, 0, nil, seen(P1, reach, 0), true, rng)
		assert(intent.bite == nil, "antes de 1 s não morde de novo")
		intent = MobBrain.think(brain, wolf, 1.3, 0, 0, nil, seen(P1, reach, 0), true, rng)
		assert(intent.bite == P1, "depois de 1 s morde de novo")
	end,

	["teia só com def de teia e respeita a recarga"] = function()
		local brain, rng = chasing(spider, 0)
		local intent = MobBrain.think(brain, spider, 0, 0, 0, nil, seen(P1, 3, 0), true, rng)
		assert(intent.bite == P1 and intent.web == true, "primeira mordida prende")
		intent = MobBrain.think(brain, spider, 1, 0, 0, nil, seen(P1, 3, 0), true, rng)
		assert(intent.bite == P1 and intent.web == false, "na recarga morde sem teia")
		intent = MobBrain.think(brain, spider, 5.9, 0, 0, nil, seen(P1, 3, 0), true, rng)
		assert(intent.bite == P1 and intent.web == false, "aos 5,9 s ainda na recarga")
		MobBrain.onHit(brain, spider, P1, 3, 0, 6)
		intent = MobBrain.think(brain, spider, 7, 0, 0, nil, seen(P1, 3, 0), true, rng)
		assert(intent.bite == P1 and intent.web == true, "passada a recarga prende de novo")
	end,

	["passivo foge perto e por 3 s depois do golpe"] = function()
		local rng = Rng.new(5)
		local brain = MobBrain.new(rabbit, 0, 0, 0, rng)
		local intent = MobBrain.think(brain, rabbit, 0, 0, 0, seen(P1, 10, 0), nil, true, rng)
		assert(brain.mode == "flee", "a 10 studs foge")
		assert(near(intent.dirX, -1) and near(intent.dirZ, 0), "foge para o lado oposto")
		assert(intent.speed == RABBIT_SPEED, "foge na velocidade cheia")
		assert(intent.bite == nil and not intent.hostile, "passivo não morde nem fica hostil")

		MobBrain.think(brain, rabbit, 1, 0, 0, seen(P1, 15, 0), nil, true, rng)
		assert(brain.mode == "wander", "a 15 studs já não foge")

		MobBrain.onHit(brain, rabbit, P1, 0, 2, 2)
		intent = MobBrain.think(brain, rabbit, 4.9, 0, 0, nil, nil, true, rng)
		assert(brain.mode == "flee", "foge por 3 s depois do golpe")
		assert(near(intent.dirX, 0) and near(intent.dirZ, -1), "foge de quem bateu")
		MobBrain.think(brain, rabbit, 5, 0, 0, nil, nil, true, rng)
		assert(brain.mode == "wander", "aos 3 s para de fugir")
	end,

	["passeio perto de casa, devagar, com pausas"] = function()
		local rng = Rng.new(11)
		local brain = MobBrain.new(wolf, 100, 50, 0, rng)
		local intent = MobBrain.think(brain, wolf, 0, 100, 50, nil, nil, true, rng)
		assert(brain.mode == "wander", "sem ninguém passeia")
		local wx, wz = brain.wanderX :: number, brain.wanderZ :: number
		assert(math.sqrt((wx - 100) ^ 2 + (wz - 50) ^ 2) <= MobRules.WANDER_RADIUS, "ponto perto de casa")
		assert(near(intent.speed, WOLF_SPEED * MobRules.WANDER_SPEED), "anda devagar")
		assert(near(intent.dirX ^ 2 + intent.dirZ ^ 2, 1), "direção unitária")

		intent = MobBrain.think(brain, wolf, 1, wx, wz, nil, nil, true, rng)
		assert(intent.dirX == 0 and intent.dirZ == 0, "chegou: pausa")
		assert(brain.wanderX == nil, "sem ponto durante a pausa")
		intent = MobBrain.think(brain, wolf, 100, wx, wz, nil, nil, true, rng)
		assert(brain.wanderX ~= nil, "depois da pausa sorteia outro ponto")
	end,

	["ponto inalcançável: passado o prazo, pausa e sorteia outro"] = function()
		local rng = Rng.new(11)
		local brain = MobBrain.new(wolf, 100, 50, 0, rng)
		MobBrain.think(brain, wolf, 0, 100, 50, nil, nil, true, rng)
		local wx, wz = brain.wanderX :: number, brain.wanderZ :: number
		local travel = math.sqrt((wx - 100) ^ 2 + (wz - 50) ^ 2) / (WOLF_SPEED * MobRules.WANDER_SPEED)
		-- O mob nunca sai do lugar (preso numa árvore, na água...): antes do prazo continua tentando.
		local beforeDeadline = travel + MobRules.WANDER_SLACK - 0.1
		local intent = MobBrain.think(brain, wolf, beforeDeadline, 100, 50, nil, nil, true, rng)
		assert(brain.wanderX == wx and intent.speed > 0, "antes do prazo segue tentando")
		-- No prazo: age como se tivesse chegado (pausa), e a mesma chamada de novo não muda nada.
		local deadline = travel + MobRules.WANDER_SLACK
		intent = MobBrain.think(brain, wolf, deadline, 100, 50, nil, nil, true, rng)
		assert(brain.wanderX == nil and intent.speed == 0, "estourou o prazo: pausa")
		local before, rngBefore = snapshot(brain), (rng :: any)._state
		MobBrain.think(brain, wolf, deadline, 100, 50, nil, nil, true, rng)
		assert(sameSnapshot(before, snapshot(brain)) and (rng :: any)._state == rngBefore, "idempotente")
		MobBrain.think(brain, wolf, deadline + 5, 100, 50, nil, nil, true, rng)
		assert(brain.wanderX ~= nil, "depois da pausa sorteia outro ponto")
	end,

	["ponto alcançado antes do prazo não é afetado"] = function()
		local rng = Rng.new(11)
		local brain = MobBrain.new(wolf, 100, 50, 0, rng)
		MobBrain.think(brain, wolf, 0, 100, 50, nil, nil, true, rng)
		local wx, wz = brain.wanderX :: number, brain.wanderZ :: number
		local wanderX = brain.wanderX
		local intent = MobBrain.think(brain, wolf, 0.5, 100, 50, nil, nil, true, rng)
		assert(brain.wanderX == wanderX and intent.speed > 0, "ainda andando, ponto mantido")
		intent = MobBrain.think(brain, wolf, 1, wx, wz, nil, nil, true, rng)
		assert(brain.wanderX == nil and intent.speed == 0, "chegou: pausa como antes")
		assert(brain.pauseUntil >= 2 and brain.pauseUntil <= 5, "pausa sorteada de 1 a 4 s")
	end,

	["hostile por comportamento"] = function()
		local rng = Rng.new(2)
		local w = MobBrain.new(wolf, 0, 0, 0, rng)
		assert(MobBrain.think(w, wolf, 0, 0, 0, nil, nil, true, rng).hostile, "agressivo sempre hostil")
		local r = MobBrain.new(rabbit, 0, 0, 0, rng)
		assert(not MobBrain.think(r, rabbit, 0, 0, 0, seen(P1, 3, 0), nil, true, rng).hostile, "passivo nunca")
		local b = MobBrain.new(boar, 0, 0, 0, rng)
		assert(not MobBrain.think(b, boar, 0, 0, 0, nil, nil, true, rng).hostile, "neutro calmo não")
		MobBrain.onHit(b, boar, P1, 3, 0, 0)
		assert(MobBrain.think(b, boar, 0, 0, 0, nil, seen(P1, 3, 0), true, rng).hostile, "neutro bravo sim")
		MobBrain.think(b, boar, 10, 0, 0, nil, seen(P1, 3, 0), true, rng)
		assert(not MobBrain.think(b, boar, 10.1, 0, 0, nil, nil, true, rng).hostile, "desistiu: apaga")
	end,

	["voador alterna voo e chão nos tempos sorteados"] = function()
		local rng = Rng.new(13)
		local brain = MobBrain.new(hawk, 0, 0, 0, rng)
		local last = MobBrain.think(brain, hawk, 0, 0, 0, nil, nil, true, rng).flying
		assert(last == false, "nasce no chão")
		local since = 0
		local switches = 0
		for step = 1, 1200 do
			local now = step * 0.1
			local flying = MobBrain.think(brain, hawk, now, 0, 0, nil, nil, true, rng).flying
			if flying ~= last then
				local lasted = now - since
				local range = if last then MobRules.FLY_TIME else MobRules.GROUND_TIME
				assert(lasted >= range[1] - 1e-6 and lasted <= range[2] + 0.1 + 1e-6, `durou {lasted} s`)
				switches += 1
				since = now
				last = flying
			end
		end
		assert(switches >= 8, `alternou só {switches} vezes em 120 s`)
	end,

	["voador só pousa com canLand"] = function()
		local rng = Rng.new(13)
		local brain = MobBrain.new(hawk, 0, 0, 0, rng)
		local now = 0
		while not MobBrain.think(brain, hawk, now, 0, 0, nil, nil, true, rng).flying do
			now += 0.1
		end
		local intent
		repeat
			now += 0.1
			intent = MobBrain.think(brain, hawk, now, 0, 0, nil, nil, false, rng)
		until intent.wantsLand or now > 100
		assert(intent.wantsLand and intent.flying, "acabou o voo: quer pousar mas continua voando")
		intent = MobBrain.think(brain, hawk, now + 5, 0, 0, nil, nil, false, rng)
		assert(intent.flying and intent.wantsLand, "sem chão livre continua voando")
		intent = MobBrain.think(brain, hawk, now + 5.1, 0, 0, nil, nil, true, rng)
		assert(not intent.flying and not intent.wantsLand, "com chão livre pousa")
	end,

	["voador perseguindo: não morde voando, pousa perto do alvo"] = function()
		local rng = Rng.new(13)
		local brain = MobBrain.new(hawk, 0, 0, 0, rng)
		local now = 0
		while not MobBrain.think(brain, hawk, now, 0, 0, nil, nil, true, rng).flying do
			now += 0.1
		end
		MobBrain.onHit(brain, hawk, P1, 20, 0, now)
		local intent = MobBrain.think(brain, hawk, now, 0, 0, nil, seen(P1, 20, 0), true, rng)
		assert(intent.flying and not intent.wantsLand, "longe do alvo continua voando")
		assert(intent.hostile and near(intent.dirX, 1), "vai atrás do alvo")
		intent = MobBrain.think(brain, hawk, now + 0.1, 0, 0, nil, seen(P1, 3, 0), false, rng)
		assert(intent.flying and intent.wantsLand, "perto do alvo quer pousar")
		assert(intent.bite == nil, "voando nunca morde")
		intent = MobBrain.think(brain, hawk, now + 0.2, 0, 0, nil, seen(P1, 3, 0), true, rng)
		assert(not intent.flying, "pousou")
		assert(intent.bite == P1, "no chão morde")
		for step = 3, 99 do
			intent = MobBrain.think(brain, hawk, now + step * 0.1, 0, 0, nil, seen(P1, 30, 0), true, rng)
			assert(brain.mode == "chase" and not intent.flying, "perseguindo no chão não decola")
		end
	end,

	["mesmo instante repetido não muda nada"] = function()
		local cases: { { def: any, nearest: MobBrain.Seen?, target: MobBrain.Seen?, canLand: boolean } } = {
			{ def = wolf, nearest = nil, target = nil, canLand = true }, -- passeio
			{ def = wolf, nearest = seen(P1, 10, 0), target = nil, canLand = true }, -- começa a perseguir
			{ def = spider, nearest = seen(P1, 3, 0), target = seen(P1, 3, 0), canLand = true }, -- morde
			{ def = rabbit, nearest = seen(P1, 5, 0), target = nil, canLand = true }, -- foge
			{ def = hawk, nearest = nil, target = nil, canLand = false }, -- voa/pousa
		}
		for index, case in cases do
			local rng = Rng.new(17)
			local brain = MobBrain.new(case.def, 0, 0, 0, rng)
			local x, z = 0, 0
			local pauses = 0
			for step = 0, 600 do
				local now = step * 0.1
				local first = MobBrain.think(brain, case.def, now, x, z, case.nearest, case.target, case.canLand, rng)
				local before = snapshot(brain)
				local rngBefore = (rng :: any)._state
				local intent = MobBrain.think(brain, case.def, now, x, z, case.nearest, case.target, case.canLand, rng)
				assert(sameSnapshot(before, snapshot(brain)), `caso {index}: cérebro mudou em {now}`)
				assert((rng :: any)._state == rngBefore, `caso {index}: sorteou de novo em {now}`)
				assert(intent.bite == nil, `caso {index}: mordeu duas vezes em {now}`)
				if brain.mode == "wander" and brain.wanderX == nil then
					pauses += 1
				end
				-- O mob anda pela intenção, para passar por chegadas e pausas.
				x += first.dirX * first.speed * 0.1
				z += first.dirZ * first.speed * 0.1
			end
			assert(index ~= 1 or pauses > 0, "o passeio deveria ter chegado e pausado")
		end
	end,
}
