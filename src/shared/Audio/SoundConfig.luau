--!strict
-- TODOS os sons do jogo num lugar só: efeitos, ambiente e música. (Os sons da
-- roleta da loja continuam em SpinSoundConfig.)
--
-- Para trocar um som: ache outro áudio na loja do Roblox
-- (create.roblox.com/store/audio), copie o número do link e troque o id aqui;
-- o volume vai de 0 a 1. Use só áudios liberados para qualquer jogo: os da
-- própria Roblox, da APM Music (APMOfficial) e da ProSoundEffects. Áudio de
-- outro criador pode não tocar fora da conta dele.
-- O comentário de cada linha diz o nome do áudio na loja, quem publicou e a
-- duração (conferida no Studio em 11/11/2026: todos carregam).
--
-- Cada efeito toca num grupo de volume das configurações do jogador:
-- "Effects" (padrão) ou "Ambient". A música toca no grupo "Music".
-- Quem toca: client/Audio/SoundPlayer (efeitos), Ambience (ambiente) e
-- MusicPlayer (música). Regras (cooldown, limite, faixa): Audio/SoundRules.
-- Guia: docs/guia/sons.md.

export type Group = "Effects" | "Ambient" | "Music"
export type Sound = {
	soundId: string,
	volume: number,
	group: Group,
	pitch: number, -- variação de tom: 0.08 = ±8% a cada toque (0 = sempre igual)
	cooldown: number, -- s mínimos entre dois toques deste som
	max: number, -- quantos deste som tocam ao mesmo tempo
	length: number, -- duração (s), para a conta de sons simultâneos
	range: number?, -- alcance 3D (studs); nil = ROLLOFF_MAX
}
export type Track = { soundId: string, volume: number }
type Options = {
	group: Group?,
	pitch: number?,
	cooldown: number?,
	max: number?,
	range: number?,
}

-- Efeito: id, volume, duração (s) e, se precisar, ajustes. Padrão: grupo
-- Effects, tom ±6%, cooldown de 0,08 s e 3 ao mesmo tempo.
local function fx(id: number, volume: number, length: number, options: Options?): Sound
	local o: Options = options or {}
	return table.freeze({
		soundId = `rbxassetid://{id}`,
		volume = volume,
		group = o.group or "Effects" :: Group,
		pitch = o.pitch or 0.06,
		cooldown = o.cooldown or 0.08,
		max = o.max or 3,
		length = length,
		range = o.range,
	})
end

local function track(id: number, volume: number): Track
	return table.freeze({ soundId = `rbxassetid://{id}`, volume = volume })
end

-- Interface: sem variação de tom forte e sem empilhar.
local UI: Options = { pitch = 0.02, cooldown = 0.05, max = 2 }
-- Sons únicos (morte, nível): sempre iguais, um por vez.
local ONCE: Options = { pitch = 0, cooldown = 0.5, max = 1 }

local SoundConfig = {}

-- Limites para o celular -------------------------------------------------
SoundConfig.MAX_VOICES = 12 -- efeitos tocando ao mesmo tempo (o resto é descartado)
SoundConfig.ROLLOFF_MIN = 12 -- studs: até aqui o som 3D toca cheio
SoundConfig.ROLLOFF_MAX = 70 -- studs: daqui em diante não se ouve (câmera de cima)

-- Efeitos ------------------------------------------------------------------
-- PSE = ProSoundEffects. Entre parênteses, a duração do áudio.
-- stylua: ignore
local sounds: { [string]: Sound } = {
	-- Golpe em recurso, por material (GatherDef.material). Material sem som usa hit_stone.
	hit_wood = fx(9120809592, 0.5, 0.5, { pitch = 0.1 }), -- PSE, machado na madeira (0,5 s)
	hit_stone = fx(9118622414, 0.6, 0.4, { pitch = 0.1 }), -- PSE "Rock Impacts" (0,4 s)
	hit_gold = fx(9125361455, 0.35, 0.6, { pitch = 0.1 }), -- PSE, batida em metal (0,6 s)
	hit_diamond = fx(9114597147, 0.45, 0.75, { pitch = 0.1 }), -- PSE "Glass Clinks 30" (0,75 s)
	hit_leaves = fx(9114518386, 0.6, 1.3, { pitch = 0.1 }), -- PSE, folhas (1,3 s)
	-- Cavar (pá): o mesmo som abafado das folhas, mais grave na terra.
	hit_ground = fx(9114518386, 0.55, 1.3, { pitch = 0.15 }), -- PSE, folhas (1,3 s)
	hit_sand = fx(9114518386, 0.45, 1.3, { pitch = 0.2 }), -- PSE, folhas (1,3 s)
	-- Regar (FarmService): o respingo dos passos na água, um pouco mais alto.
	hit_water = fx(9117946641, 0.45, 0.39, { pitch = 0.12 }), -- PSE "Puddle Stomps Small Water Splashes 3" (0,39 s)
	-- Golpe em bicho, em outro jogador e em construção ou caixa.
	hit_mob = fx(9114482141, 0.5, 0.76, { pitch = 0.1 }), -- PSE "Flesh Hits 2" (0,76 s)
	hit_player = fx(9113573976, 0.55, 0.58, { pitch = 0.1 }), -- PSE "Boxing Hits 14" (0,58 s)
	hit_structure = fx(9120950231, 0.5, 0.7, { pitch = 0.1 }), -- PSE "Wood Pound Dirt Two Wood Poles 1" (0,7 s)
	-- O braço cortando o ar: todo golpe faz; se acertar, soma o som do alvo.
	swing = fx(9120972321, 0.22, 0.6, { pitch = 0.12, cooldown = 0.15, max = 2, range = 45 }), -- PSE "Wood Whoosh Slicing Air Quick Swings 4" (0,6 s)

	-- Itens.
	pickup = fx(9119669065, 0.4, 0.29, { pitch = 0.1, cooldown = 0.1, max = 2 }), -- PSE "Suction Pop 4" (0,29 s)
	drop = fx(9114121520, 0.45, 0.38), -- PSE "Dog Food Bag 4" (0,38 s)
	craft_start = fx(9125574374, 0.45, 1.12, { cooldown = 0.3, max = 1 }), -- PSE "Gavel Hit Wood Mallet Hit Wood Triple Impact" (1,12 s)
	craft_done = fx(9126073001, 0.45, 1.16, { pitch = 0, cooldown = 0.2, max = 1 }), -- PSE "Synth Sparkle Tone High Pitch Bell Tone Ding" (1,16 s)
	eat = fx(9113723854, 0.5, 0.89, { cooldown = 0.5, max = 2, range = 40 }), -- PSE "Carrot Break In Half 1" (0,89 s)
	drink = fx(9114171855, 0.5, 0.9, { cooldown = 0.5, max = 2, range = 40 }), -- PSE "Drinking Cu Gulping 2" (0,9 s)

	-- Construções e máquinas (3D na peça).
	place = fx(9126267413, 0.55, 0.63, { cooldown = 0.12 }), -- PSE "Wood Hit Giant Wood Beam Dull Thuds Knocks 1" (0,63 s)
	structure_break = fx(9120957463, 0.5, 2.7, { cooldown = 0.2, max = 2 }), -- PSE "Wood Roof Crash 1" (2,7 s)
	door_open = fx(9120839359, 0.45, 1.14, { cooldown = 0.15, max = 2 }), -- PSE "Wood Door Creak Squeak 7" (1,14 s)
	door_close = fx(9113656909, 0.5, 0.81, { cooldown = 0.15, max = 2 }), -- PSE "Cabinet Doors 6" (0,81 s)
	machine_wood = fx(9120857129, 0.5, 0.68), -- PSE "Wood Drop Boards Falling To Floor 46" (0,68 s)
	machine_collect = fx(9117268548, 0.55, 0.71), -- PSE "Pebbles Movement 4" (0,71 s)
	chest_open = fx(9120881979, 0.4, 0.82, { cooldown = 0.4, max = 1 }), -- PSE "Wood Groan Creak Opening Wood Chest Coffin 9" (0,82 s)
	chest_item = fx(9116251623, 0.5, 0.27), -- PSE "Leather Bible 11" (0,27 s)

	-- O próprio jogador (2D).
	hurt = fx(9113487745, 0.6, 0.5, { cooldown = 0.15, max = 2 }), -- PSE "Body Hit 11" (0,5 s)
	death = fx(9114036511, 0.7, 1.3, ONCE), -- PSE "Deep Impacts 7" (1,3 s)
	resurrect = fx(9116394545, 0.6, 1.43, ONCE), -- PSE "Magic Glows Soft Clusters Of Chiming Hits 1" (1,43 s)
	level_up = fx(9116422213, 0.6, 1.61, ONCE), -- PSE "Magic Transformation 17" (1,61 s)
	heartbeat = fx(9119882039, 0.5, 0.94, ONCE), -- PSE "Synth Whomps 38" (0,94 s), em loop com a vida baixa

	-- Interface (2D).
	ui_click = fx(15675059323, 0.4, 0.37, UI), -- Roblox "Roblox_UI_Bright_Click" (0,37 s)
	ui_tab = fx(15675037413, 0.45, 0.62, UI), -- Roblox "Roblox_UI_Paper_Swipe" (0,62 s)
	ui_slot = fx(15675032796, 0.5, 0.13, UI), -- Roblox "Roblox_UI_Small_Click" (0,13 s)
	notify_info = fx(9125530803, 0.3, 0.56, UI), -- PSE "Electronic Blips Sharp Crystalline Beeps Gat" (0,56 s)
	notify_alert = fx(17208353912, 0.45, 0.38, UI), -- Roblox "Roblox GUI - Negative" (0,38 s)
	notify_success = fx(9113397314, 0.35, 0.48, UI), -- PSE "Beeps Light Shimmering 5" (0,48 s)

	-- Mundo.
	water_step = fx(9117946641, 0.3, 0.39, { pitch = 0.12, cooldown = 0.2, max = 3, range = 45 }), -- PSE "Puddle Stomps Small Water Splashes 3" (0,39 s)

	-- Bichos: mob_<id>_<attack|hurt|death>. Sem som próprio, o bicho usa os
	-- genéricos mob_attack e mob_death (mob_hurt genérico não existe: só o golpe).
	mob_attack = fx(9125467298, 0.5, 0.48, { pitch = 0.1 }), -- PSE "Creature Bite Pterodactyl Crunch Flying Bug" (0,48 s)
	mob_death = fx(9113480917, 0.55, 0.38, { pitch = 0.1 }), -- PSE "Body Fall Thud 1" (0,38 s)
	mob_wolf_attack = fx(9120792018, 0.55, 0.8, { pitch = 0.1 }), -- PSE "Wolf Snorts 6" (0,8 s)
	mob_wolf_death = fx(9113955748, 0.5, 0.42, { pitch = 0.1 }), -- PSE "Coyotes Gruff Barking 12" (0,42 s)
	mob_boar_attack = fx(9117356889, 0.55, 0.69, { pitch = 0.1 }), -- PSE "Pig Grunts 18" (0,69 s)
	mob_boar_death = fx(9117370218, 0.5, 0.9, { pitch = 0.1 }), -- PSE "Pig Squeals 5" (0,9 s)
	mob_spider_attack = fx(9113990344, 0.55, 0.56, { pitch = 0.1 }), -- PSE "Creature Vocal Spider Hiss Exhale 2" (0,56 s)
	mob_spider_death = fx(9120647258, 0.55, 0.38, { pitch = 0.1 }), -- PSE "Wet Newspaper Slap Hit With Shovel 3" (0,38 s)
	mob_rabbit_hurt = fx(9117006438, 0.4, 0.52, { pitch = 0.1 }), -- PSE "Mouse Vocal 3" (0,52 s)
	mob_rabbit_death = fx(9117011106, 0.45, 0.3, { pitch = 0.1 }), -- PSE "Mouse Vocal 8" (0,3 s)

	-- De noite, ao longe (2D, no volume de ambiente).
	night_howl = fx(9120790553, 0.18, 5.2, { group = "Ambient", pitch = 0.05, cooldown = 10, max = 1 }), -- PSE "Wolf Howl Two Versions 2" (5,2 s)
	night_owl = fx(9117181540, 0.2, 5.5, { group = "Ambient", pitch = 0.05, cooldown = 10, max = 1 }), -- PSE "Owl Hooting Reverberant Several 1" (5,5 s)
}
SoundConfig.sounds = table.freeze(sounds)

-- Música -------------------------------------------------------------------
-- Todas da APM Music (APMOfficial). Cada modo alterna entre as suas faixas,
-- sem repetir a última; para ter mais variedade, acrescente linhas.
SoundConfig.MUSIC_FADE = 3 -- s do crossfade (troca de modo e de faixa)
-- Teto do volume de uma faixa: a música fica sempre abaixo dos efeitos.
SoundConfig.MUSIC_MAX_VOLUME = 0.4

-- stylua: ignore
local music: { [string]: { Track } } = {
	menu = {
		track(1840007392, 0.3), -- "Maypole Summer (d)": folk alegre, violão (159,8 s)
		track(1842361802, 0.3), -- "Free Ride": dois violões, leve (107,5 s)
	},
	day = {
		track(1842361805, 0.25), -- "Twilight Blue": violão solo (107,3 s)
		track(9039509587, 0.25), -- "Acoustic Pop Guitar": violão, campo (124,7 s)
		track(1840356918, 0.25), -- "Ethnic Journeys #8": flautas suaves (85,3 s)
		track(1844433775, 0.25), -- "Strange Cloud": violão solo (70,7 s)
	},
	night = {
		track(1847342791, 0.25), -- "Mysterious Night Scene": cordas graves, tensão (74,1 s)
		track(9038849903, 0.22), -- "Agony Of Uncertainty": synth frio, mistério lento (138,1 s)
		track(1841355818, 0.25), -- "Eerie Night a": noite sinistra (109,5 s)
	},
	death = {
		track(1838635121, 0.3), -- "Sad End (Solo Piano)": piano triste (152,5 s)
	},
}
SoundConfig.music = table.freeze(music)

-- Ambiente -----------------------------------------------------------------
SoundConfig.AMBIENT_FADE = 4 -- s para um loop do ambiente entrar ou sair
SoundConfig.WATER_RANGE = 40 -- studs da beira em que a água começa a se ouvir
SoundConfig.FIRE_RANGE = 45 -- studs: alcance do som de uma fogueira/fornalha
SoundConfig.MAX_FIRES = 3 -- fogos com som ao mesmo tempo (os mais perto)
-- Uivo/coruja de noite: um a cada MIN + (0 a SPREAD) segundos.
SoundConfig.NIGHT_CALL_MIN = 35
SoundConfig.NIGHT_CALL_SPREAD = 50

-- Loops (todos da ProSoundEffects). day/wind/night/water são 2D; fire e
-- furnace são 3D na peça do fogo.
local LOOP: Options = { group = "Ambient", pitch = 0, cooldown = 0, max = 1 }
-- stylua: ignore
local ambient: { [string]: Sound } = {
	day = fx(9116970949, 0.3, 75.2, LOOP), -- "Morning Forest Birds 6": pássaros e brisa (75,2 s)
	wind = fx(9116258282, 0.12, 87.4, LOOP), -- "Leaves Rustle Wind Blowing Through Trees 2": vento nas folhas (87,4 s)
	night = fx(9112764891, 0.25, 63.5, LOOP), -- "Crickets Night 3": grilos (63,5 s)
	water = fx(9116203162, 0.4, 45.7, LOOP), -- "Lake Lap Water Movement 2": marolas do lago (45,7 s)
	fire = fx(9112780462, 0.5, 42.8, LOOP), -- "Fireplace Constant Burning Flame 4": fogo crepitando (42,8 s)
	furnace = fx(9112825609, 0.4, 53.2, LOOP), -- "Macho Destructo Fire 2": fogo forte (53,2 s)
}
SoundConfig.ambient = table.freeze(ambient)

-- A chave existe nos efeitos? (Para as regras escolherem som próprio ou genérico.)
function SoundConfig.has(key: string): boolean
	return SoundConfig.sounds[key] ~= nil
end

return SoundConfig
