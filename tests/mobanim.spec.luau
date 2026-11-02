--!strict
local A = require("../src/shared/Mobs/MobAnim")
local C = require("../src/shared/Mobs/MobAnimConfig")
local Defs = require("../src/shared/Defs")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local function near(a: number, b: number)
	assert(math.abs(a - b) < 1e-6, `{a} ~= {b}`)
end

local function input(id: string): A.Input
	return { config = C.Mobs[id], speed = 0, attack = 0, hurt = 0, dead = false, hostile = false }
end

-- O piscar fica de fora: tem ciclo próprio e é testado à parte.
local function equal(a: A.Pose, b: A.Pose)
	near(a.flash, b.flash)
	near(a.outline, b.outline)
	for name, group in a.groups do
		local other = b.groups[name]
		for _, field in { "x", "y", "z", "yaw", "scale" } do
			near((group :: any)[field], (other :: any)[field])
		end
	end
end

local function advance(state: A.State, seconds: number, inp: A.Input): A.Pose
	local count = math.ceil(seconds / (1 / 120))
	local pose = A.step(state, 0, inp)
	for _ = 1, count do
		pose = A.step(state, seconds / count, inp)
	end
	return pose
end

return {
	["config covers the 23 approved models and exactly their groups"] = function()
		local plan = serde.decode("json", fs.readFile("scripts/studio/mob-joints-plan.json"))
		local count = 0
		for id, config in C.Mobs do
			count += 1
			assert(config.scale > 0 and config.scale == 0.4, "escala inicial deve ser 0,4")
			local groups = { Body = true }
			for name, def in config.groups do
				assert(A.MOTIONS[def.motion], `movimento desconhecido: {def.motion}`)
				groups[name] = true
			end
			assert(plan[id], id)
			for _, group in plan[id] do
				assert(groups[group.name], `grupo sem config: {id}/{group.name}`)
				groups[group.name] = nil
			end
			assert(next(groups) == nil, `config tem grupo inexistente: {id}`)
		end
		assert(count == 23, "devem existir 23 entradas")
	end,

	["idle is small periodic and deterministic for every mob"] = function()
		for id in C.Mobs do
			local inp = input(id)
			local state = A.newState()
			local start = advance(state, 0.37, inp)
			for _ = 1, 360 do
				local p = A.step(state, C.IDLE_PERIOD / 360, inp)
				assert(math.abs(p.groups.Body.scale - 1) <= C.BREATHE_SCALE + 1e-6, "respiração fora do limite")
				for name, g in p.groups do
					assert(math.abs(g.yaw) <= math.rad(6), `idle exagerado: {id}/{name}`)
					assert(math.abs(g.x) < 0.1 and math.abs(g.z) < 0.1, "deslocamento parado exagerado")
				end
			end
			equal(start, A.step(state, 0, inp))
			equal(start, advance(A.newState(), 0.37, inp))
		end
	end,

	["paired legs alternate and stopping returns to idle"] = function()
		for _, id in { "spider", "crab", "king_crab" } do
			local state, inp = A.newState(), input(id)
			inp.speed = C.WALK_SPEED_REF
			local moved = false
			for _ = 1, 150 do
				local p = A.step(state, 1 / 60, inp)
				local count = if id == "spider" then 4 else 3
				for i = 1, count do
					local l, r = p.groups["Leg_L" .. i], p.groups["Leg_R" .. i]
					-- Lados espelhados: o mesmo giro põe a esquerda à frente e a
					-- direita atrás. A ponta da pata em ±X anda em Z = ∓sin(yaw).
					near(l.yaw, r.yaw)
					if i < count then
						near(l.yaw, -p.groups["Leg_L" .. (i + 1)].yaw)
					end
					moved = moved or math.abs(l.yaw) > 0.1
				end
			end
			assert(moved, "as pernas devem alternar")
			inp.speed = 0
			local stopped = advance(state, 3, inp)
			local idle = advance(A.newState(), 5.5, inp)
			equal(stopped, idle)
		end
	end,

	["counter edges trigger attack and hurt then return at configured durations"] = function()
		for id in C.Mobs do
			for _, event in { "attack", "hurt" } do
				local inp, state, baseline = input(id), A.newState(), A.newState()
				local counters: any = inp
				local duration = if event == "attack" then C.ATTACK_DURATION else C.HURT_DURATION
				counters[event] = 1
				local peak = advance(state, duration / 2, inp)
				local rest = advance(baseline, duration / 2, input(id))
				if event == "attack" then
					assert(peak.groups.Body.z < rest.groups.Body.z, "ataque deve investir para frente")
				else
					assert(peak.groups.Body.z > rest.groups.Body.z and peak.flash > 0, "dano deve recuar e piscar")
				end
				equal(advance(state, duration / 2, inp), advance(baseline, duration / 2, input(id)))
				-- Contador constante não reinicia o evento.
				equal(advance(state, duration, inp), advance(baseline, duration, input(id)))
				counters[event] = 4
				peak = advance(state, duration / 2, inp)
				assert(
					if event == "attack" then peak.groups.Body.z < 0 else peak.flash > 0,
					"novo contador deve reiniciar"
				)
				-- Diminuir contador não dispara.
				counters[event] = 0
				advance(state, duration, inp)
				local quiet = advance(state, duration / 2, inp)
				near(quiet.groups.Body.z, 0)
			end
		end
	end,

	["death shrinks monotonically and cannot revive on the same root"] = function()
		local state, inp = A.newState(), input("kraken")
		advance(state, 0.4, inp)
		inp.dead = true
		local last = math.huge
		for _ = 1, 180 do
			local p = A.step(state, 1 / 120, inp)
			assert(p.groups.Body.scale <= last, "morte não pode crescer")
			last = p.groups.Body.scale
			inp.dead = false
		end
		near(last, 0)
		equal(A.step(state, 0, inp), advance(state, 2, inp))
	end,

	["zero and huge dt are finite and advance at most MAX_DT"] = function()
		for id in C.Mobs do
			local inp = input(id)
			inp.speed, inp.attack, inp.hurt = 100, 1, 1
			local a, b = A.newState(), A.newState()
			equal(A.step(a, 10000, inp), A.step(b, C.MAX_DT, inp))
			local before = A.step(a, 0, inp)
			equal(before, A.step(a, 0, inp))
			for _, dt in { -1, 0 / 0, math.huge } do
				local p = A.step(a, dt, inp)
				for _, g in p.groups do
					for _, value in g do
						assert(value == value and math.abs(value) < 1e6, "pose deve ser finita")
					end
				end
			end
		end
	end,

	["sandworm jaws move in sequence and dragon tails stay subtle"] = function()
		local inp = input("sandworm")
		inp.speed = C.WALK_SPEED_REF
		local p = advance(A.newState(), 0.7, inp)
		local distances = {}
		for i = 1, 4 do
			local g = p.groups["Jaw_" .. i]
			table.insert(distances, math.sqrt(g.x * g.x + g.z * g.z))
		end
		assert(math.abs(distances[1] - distances[2]) > 0.01, "mandíbulas devem ter fases diferentes")
		for _, id in { "baby_dragon", "dragon", "baby_lava_dragon", "lava_dragon" } do
			inp = input(id)
			inp.speed, inp.attack = C.WALK_SPEED_REF, 1
			local state = A.newState()
			for _ = 1, 180 do
				assert(
					math.abs(A.step(state, 1 / 60, inp).groups.Tail.yaw) <= math.rad(5),
					"cauda do dragão exagerada"
				)
			end
		end
	end,

	["every mob in Defs has an animation and vice versa"] = function()
		for id in Defs.Mobs do
			assert(C.Mobs[id], `{id} sem animação`)
		end
		for id in C.Mobs do
			assert(Defs.Mobs[id], `{id} sem entrada em Defs.Mobs`)
		end
	end,

	["eyes blink once per period and the seed spreads the mobs"] = function()
		local inp = input("wolf")
		local state = A.newState()
		local closed, open = 0, 0
		local steps = 700
		for _ = 1, steps do
			local p = A.step(state, C.BLINK_PERIOD / steps, inp)
			if p.blink > 0.9 then
				closed += 1
			elseif p.blink == 0 then
				open += 1
			end
		end
		assert(closed > 0, "deve piscar")
		assert(open > steps * 0.8, "fica de olho aberto quase sempre")
		-- Mesmo instante, atrasos diferentes: um pisca e o outro não.
		local a = advance(A.newState(0, 0, 0), C.BLINK_DURATION / 2, inp)
		local b = advance(A.newState(0, 0, 0.5), C.BLINK_DURATION / 2, inp)
		assert(a.blink > 0.9 and b.blink == 0, "o atraso deve espalhar o piscar")
	end,

	["hurt closes the eyes, squashes and shakes the body"] = function()
		local inp = input("rabbit")
		local state = A.newState(0, 0, 0.5)
		inp.hurt = 1
		local squashed, shook = false, false
		local count = 40
		for _ = 1, count - 1 do
			local p = A.step(state, C.HURT_DURATION / count, inp)
			assert(p.blink == 1, "olhos fechados no dano")
			squashed = squashed or p.groups.Body.scale < 1 - C.HURT_SQUASH / 2
			shook = shook or math.abs(p.groups.Body.x) > C.HURT_SHAKE / 4
		end
		assert(squashed and shook, "o dano deve encolher e tremer o corpo")
		local after = advance(state, C.HURT_DURATION, inp)
		assert(after.blink < 1 and after.flash == 0, "depois do dano volta ao normal")
	end,

	["dead mobs keep the eyes closed"] = function()
		local inp = input("wolf")
		local state = A.newState()
		inp.dead = true
		assert(A.step(state, 1 / 60, inp).blink == 1, "morto de olho fechado")
	end,

	["outline fades to red while hostile and back when calm"] = function()
		local inp = input("boar")
		local state = A.newState()
		inp.hostile = true
		local half = advance(state, C.OUTLINE_FADE / 2, inp)
		assert(half.outline > 0.3 and half.outline < 0.7, "a borda troca aos poucos")
		near(advance(state, C.OUTLINE_FADE, inp).outline, 1)
		inp.hostile = false
		near(advance(state, C.OUTLINE_FADE * 2, inp).outline, 0)
		-- Mob que já nasce agressivo começa vermelho, sem transição.
		inp.hostile = true
		near(A.step(A.newState(0, 0, 0, true), 0, inp).outline, 1)
	end,

	["attack makes an angry face for ANGRY_DURATION and hurt wins"] = function()
		local inp = input("wolf")
		local state = A.newState()
		assert(A.step(state, 1 / 60, inp).angry == 0, "calmo não fica bravo")
		inp.attack = 1
		assert(advance(state, C.ATTACK_DURATION, inp).angry == 1, "bravo durante o ataque")
		assert(advance(state, C.ANGRY_DURATION - C.ATTACK_DURATION - 0.05, inp).angry == 1, "segue bravo um pouco")
		assert(advance(state, 0.1, inp).angry == 0, "passa depois de ANGRY_DURATION")
		-- Ataque e dano juntos: o dano manda (olhos fechados, sem cara de brava).
		inp.attack, inp.hurt = 2, 1
		local p = advance(state, C.HURT_DURATION / 2, inp)
		assert(p.angry == 0 and p.blink == 1, "o dano tem prioridade")
	end,

	["spider attack closes the two front legs"] = function()
		local inp = input("spider")
		inp.attack = 1
		local p = advance(A.newState(), C.ATTACK_DURATION / 2, inp)
		-- Lados espelhados: para fechar para a frente a esquerda gira negativo.
		assert(p.groups.Leg_L1.yaw < math.rad(-20) and p.groups.Leg_R1.yaw > math.rad(20), "patas da frente fecham")
		near(p.groups.Leg_L2.yaw, 0)
		near(p.groups.Leg_R4.yaw, 0)
	end,
}
