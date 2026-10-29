--!strict
-- Matemática das animações do boneco: parado (respira), andar (quique e
-- balanço das mãos), golpe com ferramenta e soco alternado de mão vazia.
-- Pura (sem APIs do Roblox): o renderer do cliente transforma a Pose em
-- CFrames, e os testes do Lune verificam as curvas.
local C = require("./BonecoConfig")

-- Deslocamento (studs) da mão em relação à posição de repouso; yaw em
-- radianos em torno do pivô do golpe (centro do corpo).
export type HandPose = { x: number, y: number, z: number, yaw: number }
export type Pose = { bodyY: number, left: HandPose, right: HandPose }
-- speed = studs/s no plano.
export type Input = { speed: number, using: boolean, hasTool: boolean }

-- Estado interno de um boneco. Quem usa só passa adiante (não mexa nos campos).
export type State = {
	time: number, -- tempo total (respiração)
	phase: number, -- fase dos passos (rad)
	speedFraction: number, -- 0 = parado, 1 = andando a toda (suavizado)
	swingActive: boolean,
	swingTime: number, -- tempo dentro do ciclo atual
	swingCount: number, -- quantos ciclos já começaram (o soco alterna por ele)
}

local TWO_PI = 2 * math.pi
-- Folga para o fim do ciclo: somar dt muitas vezes deixa o tempo um fio abaixo
-- do período, e o ciclo não pode durar um quadro a mais por isso.
local EPSILON = 1e-9

local BonecoAnim = {}

function BonecoAnim.newState(): State
	return {
		time = 0,
		phase = 0,
		speedFraction = 0,
		swingActive = false,
		swingTime = 0,
		swingCount = 0,
	}
end

-- Curva do golpe: 0 em p=0, 1 no fim da ida, 0 em p=1. Ida com ease-out
-- (sai rápido, freia no fim), volta com ease-in-out (mais lenta e suave).
function BonecoAnim.swingCurve(p: number): number
	local A = C.SWING_ATTACK_FRACTION
	p = math.clamp(p, 0, 1)
	if p <= A then
		local t = p / A
		return 1 - (1 - t) * (1 - t)
	end
	local t = (p - A) / (1 - A)
	return 0.5 + 0.5 * math.cos(math.pi * t)
end

-- Avança o golpe. Um ciclo começado sempre termina (mesmo soltando o clique);
-- segurando, o próximo começa na hora, carregando a sobra do tempo.
local function advanceSwing(state: State, dt: number, using: boolean)
	if not state.swingActive then
		if not using then
			return
		end
		state.swingActive = true
		state.swingTime = 0
		state.swingCount += 1
	end
	state.swingTime += dt
	if state.swingTime >= C.SWING_PERIOD - EPSILON then
		if using then
			state.swingTime = math.max(state.swingTime - C.SWING_PERIOD, 0)
			state.swingCount += 1
		else
			state.swingActive = false
			state.swingTime = 0
		end
	end
end

function BonecoAnim.step(state: State, dt: number, input: Input): Pose
	dt = math.clamp(dt, 0, C.MAX_DT)
	local speed = math.max(input.speed, 0)

	state.time = (state.time + dt) % C.BREATHE_PERIOD
	-- Suavização exponencial: independe da taxa de quadros.
	local target = math.clamp(speed / C.WALK_SPEED_REF, 0, 1)
	state.speedFraction += (target - state.speedFraction) * (1 - math.exp(-C.SPEED_SMOOTHING * dt))
	-- A fase fica em [0, 2π) para não perder precisão com o tempo.
	state.phase = (state.phase + speed * dt * C.STEP_RATE) % TWO_PI
	advanceSwing(state, dt, input.using)

	local walk = state.speedFraction
	local bodyY = C.BOB_HEIGHT * math.abs(math.sin(state.phase)) * walk
	local sway = C.HAND_SWAY * math.sin(state.phase) * walk
	local breathe = C.BREATHE_HEIGHT * math.sin(TWO_PI * state.time / C.BREATHE_PERIOD) * (1 - walk)

	local left: HandPose = { x = 0, y = breathe, z = sway, yaw = 0 }
	local right: HandPose = { x = 0, y = breathe, z = -sway, yaw = 0 }

	if state.swingActive then
		local c = BonecoAnim.swingCurve(state.swingTime / C.SWING_PERIOD)
		if input.hasTool then
			right.yaw = math.rad(C.SWING_ARC) * c
			left.z = C.OTHER_HAND_RECOIL * c
		elseif state.swingCount % 2 == 1 then
			right.z = -C.PUNCH_DISTANCE * c
		else
			left.z = -C.PUNCH_DISTANCE * c
		end
	end

	return { bodyY = bodyY, left = left, right = right }
end

return BonecoAnim
