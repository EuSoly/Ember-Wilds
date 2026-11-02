--!strict
-- Matemática pura: nenhum Instance/CFrame, nem regra de gameplay.
local C = require("./MobAnimConfig")
export type GroupPose = { x: number, y: number, z: number, yaw: number, scale: number }
export type Pose = { groups: { [string]: GroupPose }, flash: number }
export type Input = { config: C.Mob, speed: number, attack: number, hurt: number, dead: boolean }
export type State = {
	time: number,
	phase: number,
	walk: number,
	attack: number,
	hurt: number,
	attackTime: number,
	hurtTime: number,
	dead: boolean,
	deathTime: number,
	deathScale: number,
}

local A = {}
A.MOTIONS = table.freeze({ sway = true, stride = true, flap = true, wave = true, radial = true, mouth = true })
local TWO_PI = 2 * math.pi
local EPS = 1e-9

function A.newState(attack: number?, hurt: number?): State
	return {
		time = 0,
		phase = 0,
		walk = 0,
		attack = attack or 0,
		hurt = hurt or 0,
		attackTime = C.ATTACK_DURATION,
		hurtTime = C.HURT_DURATION,
		dead = false,
		deathTime = 0,
		deathScale = 1,
	}
end

local function groupPose(): GroupPose
	return { x = 0, y = 0, z = 0, yaw = 0, scale = 1 }
end

function A.restPose(config: C.Mob): Pose
	local groups = { Body = groupPose() }
	for name in config.groups do
		groups[name] = groupPose()
	end
	return { groups = groups, flash = 0 }
end

local function pulse(time: number, duration: number): number
	if time >= duration - EPS then
		return 0
	end
	return math.sin(math.pi * time / duration)
end

function A.step(state: State, dt: number, input: Input): Pose
	dt = if dt ~= dt then 0 else math.clamp(dt, 0, C.MAX_DT)
	local pose = A.restPose(input.config)
	local body = pose.groups.Body
	if input.dead and not state.dead then
		state.dead = true
		state.deathScale = 1 + C.BREATHE_SCALE * math.sin(TWO_PI * state.time / C.IDLE_PERIOD) * (1 - state.walk)
	end
	if state.dead then
		state.deathTime = math.min(state.deathTime + dt, C.DEATH_DURATION)
		body.scale = state.deathScale * math.max(0, 1 - state.deathTime / C.DEATH_DURATION)
		if state.deathTime >= C.DEATH_DURATION - EPS then
			body.scale = 0
		end
		return pose
	end
	state.time = (state.time + dt) % C.IDLE_PERIOD
	local speed = if input.speed == input.speed then math.clamp(input.speed, 0, C.WALK_SPEED_REF) else 0
	local target = speed / C.WALK_SPEED_REF
	state.walk += (target - state.walk) * (1 - math.exp(-C.SPEED_SMOOTHING * dt))
	if target == 0 and state.walk < C.REST_EPSILON then
		state.walk = 0
	end
	state.phase = (state.phase + TWO_PI * target * dt / C.WALK_PERIOD) % TWO_PI
	if input.attack > state.attack then
		state.attackTime = 0
	end
	if input.hurt > state.hurt then
		state.hurtTime = 0
	end
	state.attack, state.hurt = input.attack, input.hurt
	state.attackTime = math.min(state.attackTime + dt, C.ATTACK_DURATION)
	state.hurtTime = math.min(state.hurtTime + dt, C.HURT_DURATION)
	local attack = pulse(state.attackTime, C.ATTACK_DURATION)
	local hurt = pulse(state.hurtTime, C.HURT_DURATION)
	local idlePhase = TWO_PI * state.time / C.IDLE_PERIOD
	local walk = state.walk
	body.scale = 1 + C.BREATHE_SCALE * math.sin(idlePhase) * (1 - walk)
	body.x = C.BODY_SHIFT * math.sin(state.phase) * walk
	body.y = C.BOB_HEIGHT * math.abs(math.sin(state.phase)) * walk
	body.yaw = C.BODY_SWAY * math.sin(state.phase) * walk
	body.z = -C.ATTACK_DISTANCE * attack + C.HURT_DISTANCE * hurt
	pose.flash = hurt
	for name, def in input.config.groups do
		assert(A.MOTIONS[def.motion], "Movimento desconhecido: " .. def.motion)
		local g = pose.groups[name]
		local wave = math.sin(state.phase + def.phase)
		g.yaw = def.idle * math.sin(idlePhase + def.phase) * (1 - walk) + def.walk * wave * walk + def.attack * attack
		if def.motion == "radial" then
			local open = (0.5 + 0.5 * wave) * walk * (1 - attack)
			local travel = def.travel * (open - attack)
			g.x, g.z = def.x * travel, def.z * travel
		elseif def.motion == "mouth" then
			g.scale = 1 - def.close * attack
		end
	end
	return pose
end

return A
