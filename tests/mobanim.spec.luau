--!strict
local A = require("../src/shared/Mobs/MobAnim")
local C = require("../src/shared/Mobs/MobAnimConfig")
local fs = require("@lune/fs")
local serde = require("@lune/serde")

local function near(a: number, b: number)
	assert(math.abs(a - b) < 1e-6, `{a} ~= {b}`)
end

local function input(id: string): A.Input
	return { config = C.Mobs[id], speed = 0, attack = 0, hurt = 0, dead = false }
end

local function equal(a: A.Pose, b: A.Pose)
	near(a.flash, b.flash)
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
				for i = 1, if id == "spider" then 4 else 3 do
					local l, r = p.groups["Leg_L" .. i], p.groups["Leg_R" .. i]
					near(l.yaw, -r.yaw)
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
}
