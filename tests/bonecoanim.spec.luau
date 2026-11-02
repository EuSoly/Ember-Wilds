--!strict
local BonecoAnim = require("../src/shared/BonecoAnim")
local C = require("../src/shared/BonecoConfig")

local DT = 1 / 60
-- Passo que cabe certinho no golpe: o pico (SWING_ATTACK_FRACTION = 0,35)
-- cai no passo 14 e o ciclo inteiro dura 40 passos.
local SWING_DT = C.SWING_PERIOD / 40
local PEAK_STEPS = math.round(C.SWING_ATTACK_FRACTION * 40)

local function near(a: number, b: number, tolerance: number?): boolean
	return math.abs(a - b) <= (tolerance or 1e-6)
end

local function input(speed: number, using: boolean, hasTool: boolean): BonecoAnim.Input
	return { speed = speed, using = using, hasTool = hasTool }
end

-- Roda `count` passos e devolve a última pose; `each` vê cada pose.
local function run(
	state: BonecoAnim.State,
	count: number,
	dt: number,
	inp: BonecoAnim.Input,
	each: ((BonecoAnim.Pose) -> ())?
): BonecoAnim.Pose
	local pose = BonecoAnim.step(state, dt, inp)
	if each then
		each(pose)
	end
	for _ = 2, count do
		pose = BonecoAnim.step(state, dt, inp)
		if each then
			each(pose)
		end
	end
	return pose
end

local function isFinite(x: number): boolean
	return x == x and math.abs(x) < 1e6
end

return {
	["swing curve hits the key points"] = function()
		assert(near(BonecoAnim.swingCurve(0), 0), "curva em 0")
		assert(near(BonecoAnim.swingCurve(C.SWING_ATTACK_FRACTION), 1), "curva no pico")
		assert(near(BonecoAnim.swingCurve(1), 0), "curva em 1")
		for i = 0, 100 do
			local value = BonecoAnim.swingCurve(i / 100)
			assert(value >= 0 and value <= 1, `curva fora de [0,1] em {i / 100}: {value}`)
		end
	end,

	["idle keeps body still and hands breathing"] = function()
		local state = BonecoAnim.newState()
		local breathed = false
		run(state, 120, DT, input(0, false, false), function(pose)
			assert(pose.bodyY == 0, `corpo parado deveria ficar em 0: {pose.bodyY}`)
			assert(pose.left.z == 0, `mão parada não balança: {pose.left.z}`)
			assert(math.abs(pose.left.y) <= C.BREATHE_HEIGHT + 1e-9, `respiração alta demais: {pose.left.y}`)
			if math.abs(pose.left.y) > 0.5 * C.BREATHE_HEIGHT then
				breathed = true
			end
		end)
		assert(breathed, "as mãos deveriam respirar")
	end,

	["walking bobs and swings hands opposite"] = function()
		local state = BonecoAnim.newState()
		local bobbed, swayed = false, false
		run(state, 120, DT, input(16, false, false), function(pose)
			assert(pose.bodyY >= 0 and pose.bodyY <= C.BOB_HEIGHT + 1e-9, `quique fora do limite: {pose.bodyY}`)
			assert(pose.left.z == -pose.right.z, "mãos deveriam balançar opostas")
			if pose.bodyY > 0.5 * C.BOB_HEIGHT then
				bobbed = true
			end
			if math.abs(pose.left.z) > 0.5 * C.HAND_SWAY then
				swayed = true
			end
		end)
		assert(bobbed, "o corpo deveria quicar")
		assert(swayed, "as mãos deveriam balançar")
	end,

	["tool swing peaks then returns"] = function()
		local state = BonecoAnim.newState()
		local pose = run(state, PEAK_STEPS, SWING_DT, input(0, true, true))
		assert(near(pose.right.yaw, math.rad(C.SWING_ARC), 1e-3), `yaw no pico: {pose.right.yaw}`)
		assert(near(pose.left.z, C.OTHER_HAND_RECOIL, 1e-3), `recuo da outra mão: {pose.left.z}`)
	end,

	["thrust stabs forward without turning"] = function()
		local state = BonecoAnim.newState()
		local thrust = { speed = 0, using = true, hasTool = true, thrust = true }
		local pose = run(state, PEAK_STEPS, SWING_DT, thrust)
		assert(near(pose.right.z, -C.THRUST_DISTANCE, 1e-3), `mão avança no pico: {pose.right.z}`)
		assert(pose.right.yaw == 0, `estocada não gira: {pose.right.yaw}`)
		assert(near(pose.left.z, C.OTHER_HAND_RECOIL, 1e-3), `recuo da outra mão: {pose.left.z}`)
		local back = run(state, 40 - PEAK_STEPS, SWING_DT, { speed = 0, using = false, hasTool = true, thrust = true })
		assert(near(back.right.z, 0, 1e-3), `mão volta no fim: {back.right.z}`)
	end,

	["releasing mid-swing finishes the cycle and stops"] = function()
		local state = BonecoAnim.newState()
		local pressed = math.round(0.1 / DT)
		local total = math.round(C.SWING_PERIOD / DT)
		run(state, pressed, DT, input(0, true, true))
		local pose = run(state, total - pressed, DT, input(0, false, true))
		assert(near(pose.right.yaw, 0, 1e-3), `yaw no fim do ciclo: {pose.right.yaw}`)
		run(state, 60, DT, input(0, false, true), function(p)
			assert(p.right.yaw == 0, `depois do ciclo o yaw deveria ser 0: {p.right.yaw}`)
		end)
	end,

	["a one-frame click still swings once"] = function()
		local state = BonecoAnim.newState()
		BonecoAnim.step(state, DT, input(0, true, true))
		local swung = false
		local pose = run(state, 60, DT, input(0, false, true), function(p)
			if p.right.yaw > 0 then
				swung = true
			end
		end)
		assert(swung, "um clique de um quadro deveria golpear")
		assert(pose.right.yaw == 0, `depois de 1 s a mão volta: {pose.right.yaw}`)
	end,

	["punches alternate right then left"] = function()
		local state = BonecoAnim.newState()
		local punch = input(0, true, false)
		local first = run(state, PEAK_STEPS, SWING_DT, punch)
		assert(near(first.right.z, -C.PUNCH_DISTANCE, 1e-3), `1º soco (direita): {first.right.z}`)
		assert(near(first.left.z, 0, 1e-3), `a esquerda não soca no 1º: {first.left.z}`)
		local second = run(state, 40, SWING_DT, punch)
		assert(near(second.left.z, -C.PUNCH_DISTANCE, 1e-3), `2º soco (esquerda): {second.left.z}`)
		assert(near(second.right.z, 0, 1e-3), `a direita não soca no 2º: {second.right.z}`)
	end,

	["huge dt stays finite"] = function()
		local state = BonecoAnim.newState()
		local pose = BonecoAnim.step(state, 5, input(16, true, true))
		assert(isFinite(pose.bodyY), `bodyY: {pose.bodyY}`)
		for _, hand in { pose.left, pose.right } do
			for _, field in { "x", "y", "z", "yaw" } do
				local value = (hand :: any)[field]
				assert(isFinite(value), `{field}: {value}`)
			end
		end
	end,
}
