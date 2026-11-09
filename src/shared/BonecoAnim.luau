--!strict
-- Matemática das animações do boneco: parado (respira), andar (quique e
-- balanço das mãos), golpe com ferramenta (arco de lado, ou estocada para a
-- frente nas lanças, attackAnim "thrust"), soco alternado de mão vazia e a
-- mordida (mão com a comida até a boca).
-- Pura (sem APIs do Roblox): o renderer do cliente transforma a Pose em
-- CFrames, e os testes do Lune verificam as curvas.
local C = require("./BonecoConfig")

-- Deslocamento (studs) da mão em relação à posição de repouso; yaw em
-- radianos em torno do pivô do golpe (centro do corpo).
export type HandPose = { x: number, y: number, z: number, yaw: number }
export type Pose = { bodyY: number, left: HandPose, right: HandPose }
-- speed = studs/s no plano. thrust = o item na mão golpeia com estocada.
-- eat = progresso da mordida (0 a 1, EatRules.progress) ou nil sem comer;
-- comendo, a mão direita leva a comida à boca e o golpe não acontece.
export type Input = { speed: number, using: boolean, hasTool: boolean, thrust: boolean?, eat: number? }

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

-- Curva da mordida: `reach` 0→1 levando a mão à boca, 1 enquanto morde e
-- 1→0 voltando; `chew` 0→1→0 a cada mordida (o empurrão da comida na boca).
function BonecoAnim.eatCurve(p: number): (number, number)
	p = math.clamp(p, 0, 1)
	local bring, back = C.EAT_BRING_FRACTION, C.EAT_RETURN_FRACTION
	if p < bring then
		local t = p / bring
		return 1 - (1 - t) * (1 - t), 0
	end
	if p > 1 - back then
		local t = (p - (1 - back)) / back
		return 0.5 + 0.5 * math.cos(math.pi * t), 0
	end
	local t = (p - bring) / (1 - bring - back)
	return 1, math.abs(math.sin(math.pi * C.EAT_BITES * t))
end

-- Progresso (0 a 1) do fundo de cada mordida, quando caem os farelos.
function BonecoAnim.eatBites(): { number }
	local bring, back = C.EAT_BRING_FRACTION, C.EAT_RETURN_FRACTION
	local span = 1 - bring - back
	local list = {}
	for k = 1, C.EAT_BITES do
		table.insert(list, bring + span * (k - 0.5) / C.EAT_BITES)
	end
	return list
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
	local eating = input.eat ~= nil
	advanceSwing(state, dt, input.using and not eating)

	local walk = state.speedFraction
	local bodyY = C.BOB_HEIGHT * math.abs(math.sin(state.phase)) * walk
	local sway = C.HAND_SWAY * math.sin(state.phase) * walk
	local breathe = C.BREATHE_HEIGHT * math.sin(TWO_PI * state.time / C.BREATHE_PERIOD) * (1 - walk)

	-- Com arma de estocada (lança), as duas mãos ficam do lado do corpo.
	local hold = if input.hasTool and input.thrust then C.THRUST_HOLD_BACK else 0
	local left: HandPose = { x = 0, y = breathe, z = hold + sway, yaw = 0 }
	local right: HandPose = { x = 0, y = breathe, z = hold - sway, yaw = 0 }

	if state.swingActive then
		local c = BonecoAnim.swingCurve(state.swingTime / C.SWING_PERIOD)
		if input.hasTool and input.thrust then
			right.z -= C.THRUST_DISTANCE * c
			left.z += C.OTHER_HAND_RECOIL * c
		elseif input.hasTool then
			right.yaw = math.rad(C.SWING_ARC) * c
			left.z = C.OTHER_HAND_RECOIL * c
		elseif state.swingCount % 2 == 1 then
			right.z = -C.PUNCH_DISTANCE * c
		else
			left.z = -C.PUNCH_DISTANCE * c
		end
	end

	if eating then
		local reach, chew = BonecoAnim.eatCurve(input.eat :: number)
		right.x += (C.EAT_HAND_X - C.HAND_X) * reach
		right.y += C.EAT_HAND_Y * reach - 0.4 * C.EAT_CHEW * chew
		right.z += (C.EAT_HAND_Z - C.HAND_Z) * reach + C.EAT_CHEW * chew
		right.yaw = 0
	end

	return { bodyY = bodyY, left = left, right = right }
end

return BonecoAnim
