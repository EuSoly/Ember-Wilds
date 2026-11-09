--!strict
-- Como as peças animadas das skins de corpo e de livro se mexem (puro, testado
-- no Lune). As peças vêm do Blender (assets/skins/skin_animacao.py) com papel
-- anim_<grupo> e um pivô (a junta) no SkinManifest; quem aplica é o
-- client/Boneco/SkinAnimator, girando cada junta em volta do pivô dela.
--
-- Cada peça tem canais. Um canal é uma onda (seno) num eixo:
--   "x", "y", "z": giro (radianos) em volta desse eixo do pivô;
--   "px", "py", "pz": deslocamento (studs) ao longo desse eixo.
-- Eixos do Roblox no espaço do corpo/livro: X = direita, Y = para cima (no
-- livro, para fora da capa), Z = para trás (a frente é -Z).
-- Parado, a onda corre no tempo (`idle` de amplitude, `idlePeriod` segundos).
-- Andando, ela segue os passos do boneco (fase do BonecoAnim): `walk` de
-- amplitude e `walkRate` ciclos por passo. A troca é suave, pela fração de
-- velocidade (0 = parado, 1 = andando a toda). Canal sem `walk` (livros) faz
-- só o movimento parado, ande ou não. `spin` gira sem parar em volta de Y.
local SkinMotion = {}

local TWO_PI = 2 * math.pi

export type Axis = "x" | "y" | "z" | "px" | "py" | "pz"

export type Channel = {
	axis: Axis,
	idle: number,
	idlePeriod: number,
	walk: number?,
	walkRate: number?,
	phase: number,
}

export type Motion = {
	channels: { Channel },
	spin: number?, -- radianos por segundo em volta de Y
}

export type Pose = { x: number, y: number, z: number, px: number, py: number, pz: number }

local function channel(
	axis: Axis,
	idle: number,
	idlePeriod: number,
	walk: number?,
	walkRate: number?,
	phase: number?
): Channel
	return { axis = axis, idle = idle, idlePeriod = idlePeriod, walk = walk, walkRate = walkRate, phase = phase or 0 }
end

-- Espelha um movimento para o outro lado (asa esquerda = direita espelhada em
-- X): giros em Y e Z e o deslocamento em X trocam de sinal.
local function mirrored(motion: Motion): Motion
	local channels = {}
	for _, c in motion.channels do
		local flip = c.axis == "y" or c.axis == "z" or c.axis == "px"
		local sign = if flip then -1 else 1
		table.insert(
			channels,
			channel(c.axis, sign * c.idle, c.idlePeriod, c.walk and sign * c.walk, c.walkRate, c.phase)
		)
	end
	return { channels = channels, spin = motion.spin and -motion.spin }
end

-- ------------------------------------------------------------ corpo

-- Dragão (pacote Gelo): parado, as asas abrem e fecham devagar no ritmo da
-- respiração e o rabo balança; andando, as asas batem a cada passo e o rabo
-- serpenteia de um lado para o outro.
local WING: Motion = {
	channels = {
		channel("z", 0.12, 2.4, 0.45, 1, 0), -- bater (a ponta sobe e desce)
		channel("y", 0.05, 2.4, 0.14, 1, math.pi / 2), -- e varre para a frente e para trás
	},
}
local DRAGON: { [string]: Motion } = {
	anim_asa_dir = WING,
	anim_asa_esq = mirrored(WING),
	anim_rabo = { channels = { channel("y", 0.12, 3, 0.35, 0.5, 0) } },
}

-- Polvo (pacote Abissal): os tentáculos ondulam um depois do outro (a onda dá
-- a volta no corpo); andando, remam mais forte a cada passo.
local OCTOPUS: { [string]: Motion } = {}
for i = 1, 7 do
	local phase = (i - 1) * 0.9
	OCTOPUS[string.format("anim_tentaculo_%02d", i)] = {
		channels = {
			channel("y", 0.14, 2.8, 0.32, 1, phase),
			channel("x", 0.04, 2.8, 0.1, 1, phase + math.pi / 2), -- a ponta sobe um pouco
		},
	}
end

-- Toco da Floresta (pacote Floresta): parado, só os brotos balançam com a
-- brisa e as raízes mal se mexem; andando, as raízes pisam como pernas (pares
-- em diagonal se alternam) e os brotos chacoalham.
local STUMP: { [string]: Motion } = {}
-- raiz → (lado: 1 direita, -1 esquerda; par: 0 ou π)
local ROOTS: { [string]: { number } } = {
	anim_raiz_01 = { 1, 0 },
	anim_raiz_02 = { 1, math.pi },
	anim_raiz_03 = { -1, math.pi },
	anim_raiz_04 = { -1, 0 },
	anim_raiz_05 = { -1, 0 },
	anim_raiz_06 = { 1, math.pi },
}
for papel, root in ROOTS do
	local side, pair = root[1], root[2]
	STUMP[papel] = {
		channels = {
			channel("y", 0.03 * side, 3.2, 0.24 * side, 1, pair),
			channel("py", 0, 1, 0.07, 1, pair + math.pi / 2), -- levanta um tico ao pisar
		},
	}
end
STUMP.anim_broto_esq = { channels = { channel("y", 0.16, 2.6, 0.3, 1, 0), channel("z", 0.05, 2.6, 0.1, 1, 1) } }
STUMP.anim_broto_dir = { channels = { channel("y", -0.16, 2.9, -0.3, 1, 1.3), channel("z", -0.05, 2.9, -0.1, 1, 2.3) } }

-- ------------------------------------------------------------ livros (equipado)

-- Tomo de Gelo: o floco gira devagar e os cristais dos cantos pulsam para
-- fora e torcem, cada um no seu tempo.
local ICE_TOME: { [string]: Motion } = {
	anim_floco = { channels = {}, spin = 0.6 },
}
-- canto → direção para fora (X, Z do livro)
local CORNERS: { [string]: { number } } = {
	anim_cristal_01 = { 1, -1 },
	anim_cristal_02 = { 1, 1 },
	anim_cristal_03 = { -1, -1 },
	anim_cristal_04 = { -1, 1 },
}
for papel, dir in CORNERS do
	local phase = (tonumber(string.sub(papel, -2)) :: number) * 1.6
	ICE_TOME[papel] = {
		channels = {
			channel("px", 0.07 * dir[1], 1.8, nil, nil, phase),
			channel("pz", 0.07 * dir[2], 1.8, nil, nil, phase),
			channel("y", 0.2, 3, nil, nil, phase),
		},
	}
end

-- Tomo Abissal: o redemoinho gira como um vórtice e a ponta do tentáculo
-- se enrola e desenrola.
local ABYSS_TOME: { [string]: Motion } = {
	anim_espiral = { channels = {}, spin = -1.4 },
	anim_ponta = { channels = { channel("y", 0.26, 2.2, nil, nil, 0), channel("x", 0.05, 2.2, nil, nil, 1) } },
}

-- Tomo Trepadeira: cada folha tremula no seu tempo e as flores balançam.
local VINE_TOME: { [string]: Motion } = {
	anim_flor_01 = { channels = { channel("y", 0.35, 3.1, nil, nil, 0) } },
	anim_flor_02 = { channels = { channel("y", -0.35, 3.4, nil, nil, 1.5) } },
}
for i = 1, 12 do
	VINE_TOME[string.format("anim_folha_%02d", i)] = {
		channels = {
			channel("y", 0.3, 1.8 + (i % 3) * 0.35, nil, nil, i * 1.1),
			channel("x", 0.08, 1.8 + (i % 3) * 0.35, nil, nil, i * 1.1 + 1),
		},
	}
end

local BY_SKIN: { [string]: { [string]: Motion } } = {
	body_dragao = DRAGON,
	body_polvo = OCTOPUS,
	body_toco = STUMP,
	book_gelo = ICE_TOME,
	book_tentaculo = ABYSS_TOME,
	book_trepadeira = VINE_TOME,
}

-- Movimento da peça `papel` da skin `skinId`; nil = fica parada.
function SkinMotion.of(skinId: string, papel: string): Motion?
	local skin = BY_SKIN[skinId]
	return skin and skin[papel]
end

-- Skins que têm peças animadas.
function SkinMotion.skins(): { string }
	local list = {}
	for skinId in BY_SKIN do
		table.insert(list, skinId)
	end
	table.sort(list)
	return list
end

-- Pose no tempo `t` (s), com a fase dos passos `stepPhase` (rad, do
-- BonecoAnim) e a fração de velocidade `walk` (0 a 1).
function SkinMotion.pose(motion: Motion, t: number, stepPhase: number, walk: number): Pose
	walk = math.clamp(walk, 0, 1)
	local pose: Pose = { x = 0, y = 0, z = 0, px = 0, py = 0, pz = 0 }
	for _, c in motion.channels do
		local still = c.idle * math.sin(TWO_PI * t / c.idlePeriod + c.phase)
		local value = still
		if c.walk ~= nil then
			local moving = c.walk * math.sin(stepPhase * (c.walkRate or 1) + c.phase)
			value = still * (1 - walk) + moving * walk
		end
		pose[c.axis] += value
	end
	if motion.spin then
		pose.y += (motion.spin * t) % TWO_PI
	end
	return pose
end

return SkinMotion
