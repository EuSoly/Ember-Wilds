--!strict
local SoundConfig = require("../src/shared/Audio/SoundConfig")
local SoundRules = require("../src/shared/Audio/SoundRules")

local function validId(soundId: string): boolean
	return string.match(soundId, "^rbxassetid://%d+$") ~= nil
end

-- Sons que o código toca pelo nome: se um sumir da config, o jogo fica mudo
-- naquele ponto sem erro nenhum. Este teste é o aviso.
local REQUIRED = {
	"hit_wood",
	"hit_stone",
	"hit_gold",
	"hit_diamond",
	"hit_leaves",
	"hit_mob",
	"hit_player",
	"hit_structure",
	"swing",
	"pickup",
	"drop",
	"craft_start",
	"craft_done",
	"eat",
	"drink",
	"place",
	"structure_break",
	"door_open",
	"door_close",
	"machine_wood",
	"machine_collect",
	"chest_open",
	"chest_item",
	"hurt",
	"death",
	"resurrect",
	"level_up",
	"heartbeat",
	"ui_click",
	"ui_tab",
	"ui_slot",
	"notify_info",
	"notify_alert",
	"notify_success",
	"water_step",
	"mob_attack",
	"mob_death",
	"night_howl",
	"night_owl",
}

local spec = {}

function spec.todo_efeito_tem_id_volume_e_limites_validos()
	for key, sound in SoundConfig.sounds do
		assert(validId(sound.soundId), `{key}: id inválido`)
		assert(sound.volume > 0 and sound.volume <= 1, `{key}: volume fora de 0..1`)
		assert(sound.group == "Effects" or sound.group == "Ambient", `{key}: grupo`)
		assert(sound.pitch >= 0 and sound.pitch <= 0.3, `{key}: variação de tom exagerada`)
		assert(sound.cooldown >= 0 and sound.max >= 1 and sound.length > 0, `{key}: limites`)
		assert(sound.max <= SoundConfig.MAX_VOICES, `{key}: mais vozes que o total`)
	end
end

function spec.os_sons_que_o_codigo_toca_existem()
	for _, key in REQUIRED do
		assert(SoundConfig.has(key), `falta o som {key}`)
	end
	assert(not SoundConfig.has("nao_existe"), "chave desconhecida não existe")
end

function spec.materiais_e_bichos_principais_tem_som()
	for _, material in { "wood", "stone", "gold", "diamond", "leaves" } do
		assert(SoundRules.hitKey(material, SoundConfig.has) == "hit_" .. material, `{material} sem som próprio`)
	end
	for _, mob in { "wolf", "boar", "spider", "rabbit" } do
		local own = false
		for _, event in { "attack", "hurt", "death" } do
			local key = SoundRules.mobKey(mob, event :: any, SoundConfig.has)
			own = own or key == `mob_{mob}_{event}`
		end
		assert(own, `{mob} sem nenhum som próprio`)
	end
end

function spec.musica_tem_faixas_em_todo_modo_e_fica_abaixo_dos_efeitos()
	for _, mode in { "menu", "day", "night", "death" } do
		local tracks = SoundConfig.music[mode]
		assert(tracks and #tracks >= 1, `sem música em {mode}`)
		for i, track in tracks do
			assert(validId(track.soundId), `{mode} {i}: id inválido`)
			assert(track.volume > 0 and track.volume <= SoundConfig.MUSIC_MAX_VOLUME, `{mode} {i}: música alta demais`)
		end
	end
	-- Dia e noite alternam entre faixas (não um loop só).
	assert(#SoundConfig.music.day >= 2 and #SoundConfig.music.night >= 2, "dia e noite com 2+ faixas")
	assert(SoundConfig.MUSIC_FADE > 0, "crossfade com duração")
end

function spec.ambiente_tem_os_loops()
	for _, key in { "day", "wind", "night", "water", "fire", "furnace" } do
		local loop = SoundConfig.ambient[key]
		assert(loop and validId(loop.soundId), `ambiente {key}`)
		assert(loop.group == "Ambient", `{key} no grupo Ambient`)
		assert(loop.volume > 0 and loop.volume <= 1, `{key}: volume`)
	end
	assert(SoundConfig.FIRE_RANGE <= SoundConfig.ROLLOFF_MAX, "fogo não se ouve mais longe que os efeitos")
	assert(SoundConfig.ROLLOFF_MAX >= 60 and SoundConfig.ROLLOFF_MAX <= 80, "alcance 3D para a câmera de cima")
end

return spec
