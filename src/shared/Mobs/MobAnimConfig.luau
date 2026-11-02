--!strict
-- Somente apresentação. scale é provisório: tamanho final cabe ao Elizeu.
export type Group = {
	motion: string,
	idle: number,
	walk: number,
	attack: number,
	phase: number,
	x: number,
	z: number,
	travel: number,
	close: number,
}
export type Mob = { scale: number, groups: { [string]: Group } }

local function group(motion: string, idle: number, walk: number, attack: number?, phase: number?): Group
	return {
		motion = motion,
		idle = math.rad(idle),
		walk = math.rad(walk),
		attack = math.rad(attack or 0),
		phase = phase or 0,
		x = 0,
		z = 0,
		travel = 0,
		close = 0,
	}
end

local function ears(): { [string]: Group }
	return { Ear_L = group("sway", 4, 9), Ear_R = group("sway", 4, 9, 0, math.pi) }
end

local function bird(): { [string]: Group }
	return {
		Head = group("sway", 1, 5, 8),
		Wing_L = group("flap", 2, 24, -8),
		Wing_R = group("flap", 2, 24, 8, math.pi),
		Tail = group("sway", 2, 8),
	}
end

local function dragon(wings: boolean): { [string]: Group }
	local groups = { Head = group("sway", 1, 5, 9), Tail = group("sway", 1, 3) }
	if wings then
		groups.Wing_L = group("flap", 1, 18, -6)
		groups.Wing_R = group("flap", 1, 18, 6, math.pi)
	end
	return groups
end

local function legs(count: number): { [string]: Group }
	local groups = {}
	-- Os lados são espelhados: o mesmo giro leva a pata da esquerda para a
	-- frente e a da direita para trás. Por isso o par usa a mesma fase, e a
	-- pata vizinha do mesmo lado vai ao contrário.
	for i = 1, count do
		groups["Leg_L" .. i] = group("stride", 0, 19, 0, (i - 1) * math.pi)
		groups["Leg_R" .. i] = group("stride", 0, 19, 0, (i - 1) * math.pi)
	end
	return groups
end

local function crab(): { [string]: Group }
	local groups = legs(3)
	groups.Claw_L = group("sway", 1, 6, -12)
	groups.Claw_R = group("sway", 1, 6, 12, math.pi)
	return groups
end

local function mammoth(): { [string]: Group }
	local groups = ears()
	groups.Trunk = group("sway", 3, 12, 15)
	return groups
end

local function mouth(): Group
	local def = group("mouth", 0, 0)
	def.close = 0.16
	return def
end

local spider = legs(4)
spider.Head = group("sway", 1, 3, 8)
-- No ataque as duas patas da frente fecham para a frente, como um bote.
spider.Leg_L1 = group("stride", 0, 19, -25)
spider.Leg_R1 = group("stride", 0, 19, 25)
local boar = ears()
boar.Head = group("sway", 1, 5, 8)
local kraken = { Mouth = mouth() }
for i = 1, 8 do
	kraken["Arm_" .. i] = group("wave", 2, 14, 7, (i - 1) * math.pi / 4)
end
local sandworm = {}
for i = 1, 4 do
	local def = group("radial", 1, 6, -8, (i - 1) * math.pi / 2)
	def.x, def.z = math.sin(def.phase), -math.cos(def.phase)
	def.travel = 0.35 -- studs antes da escala do mob; abre para fora.
	sandworm["Jaw_" .. i] = def
end

local function mob(groups: { [string]: Group }): Mob
	for _, def in groups do
		table.freeze(def)
	end
	return table.freeze({ scale = 0.4, groups = table.freeze(groups) })
end

return table.freeze({
	MAX_DT = 1 / 15,
	ANIM_RANGE = 160,
	IDLE_PERIOD = 3,
	WALK_PERIOD = 0.65,
	WALK_SPEED_REF = 8, -- referência visual, não altera deslocamento no servidor.
	SPEED_SMOOTHING = 12,
	REST_EPSILON = 0.0001,
	BREATHE_SCALE = 0.015,
	BODY_SWAY = math.rad(3),
	BODY_SHIFT = 0.08,
	BOB_HEIGHT = 0.08,
	ATTACK_DURATION = 0.45,
	ATTACK_DISTANCE = 1.6, -- studs antes da escala do mob
	ATTACK_PUFF = 0.08, -- o corpo cresce 8% no bote
	HURT_DURATION = 0.35,
	HURT_DISTANCE = 0.9, -- recuo (studs antes da escala)
	HURT_SQUASH = 0.1, -- o corpo encolhe 10% com o golpe
	HURT_SHAKE = 0.3, -- tremida de lado (studs antes da escala)
	HURT_SHAKES = 3, -- vai e volta 3 vezes durante o dano
	DEATH_DURATION = 0.5,
	-- Piscar: cada mob pisca a cada BLINK_PERIOD s (com atraso próprio, para
	-- não piscarem todos juntos); no dano e na morte os olhos ficam fechados.
	-- O olho fechado encolhe BLINK_SQUASH na frente-trás (visto de cima, achata).
	BLINK_PERIOD = 3.5,
	BLINK_DURATION = 0.16,
	BLINK_SQUASH = 0.85,
	EYE_PATTERN = "eye", -- peças com isto no nome são olhos
	SPARKLE_PATTERN = "sparkle", -- brilho do olho: some com o olho fechado
	-- Borda: a cor do modelo quando calmo; esta quando MobHostile (quer atacar).
	OUTLINE_HOSTILE = { 0xb6 / 255, 0x3b / 255, 0x58 / 255 },
	OUTLINE_FADE = 0.25, -- segundos para a borda trocar de cor
	SIZE_STEP = 0.002, -- o cliente só troca o Size das peças quando a escala anda isso

	FLASH_COLOR = { 1, 0.35, 0.3 },
	Mobs = table.freeze({
		rabbit = mob(ears()),
		wolf = mob({}),
		spider = mob(spider),
		boar = mob(boar),
		hawk = mob(bird()),
		penguin = mob({ Wing_L = group("flap", 1, 16), Wing_R = group("flap", 1, 16, 0, math.pi) }),
		arctic_fox = mob({}),
		polar_bear = mob(ears()),
		baby_mammoth = mob(mammoth()),
		mammoth = mob(mammoth()),
		baby_dragon = mob(dragon(false)),
		dragon = mob(dragon(true)),
		crab = mob(crab()),
		king_crab = mob(crab()),
		gmo_piranha = mob({
			Fin_L = group("flap", 1, 16),
			Fin_R = group("flap", 1, 16, 0, math.pi),
			DorsalFin = group("sway", 1, 5),
			Tail = group("sway", 2, 16),
			Jaw = mouth(),
		}),
		kraken = mob(kraken),
		lava_monster = mob({}),
		baby_lava_dragon = mob(dragon(false)),
		lava_dragon = mob(dragon(true)),
		vulture = mob(bird()),
		sandworm = mob(sandworm),
		golden_hen = mob(bird()),
		golden_chick = mob(bird()),
	}),
})
