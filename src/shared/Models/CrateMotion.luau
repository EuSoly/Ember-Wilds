--!strict
-- Como as peças animadas das caixas se mexem (puro, testado no Lune). O papel
-- vem do SkinManifest (exportado do Blender, assets/skins/caixa_animacao.py):
--   anim_rotor, anim_espiral: giram no eixo vertical do meio da caixa;
--   anim_anel: gira mais devagar, ao contrário;
--   anim_pena_NN, anim_nuvem_NN, anim_cristal_NN: flutuam para cima e para
--   baixo, cada uma fora de compasso das outras.
-- Quem desenha (client/World/CrateAnimator) aplica o `pose` em cima da
-- posição de descanso da peça.
local CrateMotion = {}

local SPIN_SPEED = 1.2 -- radianos por segundo (~1 volta a cada 5 s)
local RING_SPEED = -0.5
local BOB_AMPLITUDE = 0.1 -- studs
local BOB_PERIOD = 2.4 -- segundos
local PHASE_STEP = 2.1 -- radianos entre uma peça e a próxima do mesmo tipo

export type Motion =
	{ kind: "spin", speed: number }
	| {
		kind: "bob",
		amplitude: number,
		period: number,
		phase: number,
	}

local SPIN: { [string]: number } = {
	anim_rotor = SPIN_SPEED,
	anim_espiral = SPIN_SPEED,
	anim_anel = RING_SPEED,
}
local BOB_GROUPS = { pena = 0, nuvem = 0.7, cristal = 1.4 } :: { [string]: number }

-- Movimento da peça com este papel; nil = fica parada.
function CrateMotion.of(papel: string): Motion?
	local speed = SPIN[papel]
	if speed then
		return { kind = "spin", speed = speed }
	end
	local group, index = string.match(papel, "^anim_(%a+)_(%d+)$")
	local base = group and BOB_GROUPS[group]
	if base == nil then
		return nil
	end
	return {
		kind = "bob",
		amplitude = BOB_AMPLITUDE,
		period = BOB_PERIOD,
		phase = base + (tonumber(index) :: number) * PHASE_STEP,
	}
end

-- Pose no tempo `t` (segundos): giro em volta do eixo vertical (radianos) e
-- subida (studs), somados à posição de descanso.
function CrateMotion.pose(motion: Motion, t: number): (number, number)
	if motion.kind == "spin" then
		return motion.speed * t, 0
	end
	local bob = motion :: any
	return 0, bob.amplitude * math.sin(2 * math.pi * t / bob.period + bob.phase)
end

return CrateMotion
