--!strict
local SoundRules = require("../src/shared/Audio/SoundRules")

local spec = {}

local function has(keys: { string }): (string) -> boolean
	return function(key: string): boolean
		return table.find(keys, key) ~= nil
	end
end

function spec.golpe_escolhe_o_som_do_material()
	local known = has({ "hit_wood", "hit_stone", "hit_gold" })
	assert(SoundRules.hitKey("wood", known) == "hit_wood", "madeira tem som próprio")
	assert(SoundRules.hitKey("gold", known) == "hit_gold", "ouro tem som próprio")
	-- Material novo sem som cadastrado cai na pedra (nunca fica mudo).
	assert(SoundRules.hitKey("amethyst", known) == "hit_stone", "material sem som usa o da pedra")
end

function spec.mob_usa_o_som_proprio_ou_o_generico()
	local known = has({ "mob_wolf_attack", "mob_attack", "mob_death", "mob_hurt" })
	assert(SoundRules.mobKey("wolf", "attack", known) == "mob_wolf_attack", "lobo tem ataque próprio")
	assert(SoundRules.mobKey("wolf", "death", known) == "mob_death", "sem morte própria usa a genérica")
	assert(SoundRules.mobKey("crab", "attack", known) == "mob_attack", "bicho sem som usa o genérico")
	assert(SoundRules.mobKey("crab", "hurt", known) == "mob_hurt", "apanhar usa o genérico")
end

function spec.botao_escolhe_o_clique_pelo_nome()
	assert(SoundRules.uiKey("Slot3") == "ui_slot", "slot do inventário")
	assert(SoundRules.uiKey("Chip_tools") == "ui_tab", "aba do livro")
	assert(SoundRules.uiKey("Tab_tools") == "ui_tab", "aba")
	assert(SoundRules.uiKey("Nav_shop") == "ui_tab", "página do menu")
	assert(SoundRules.uiKey("Cell") == "ui_slot", "célula do livro")
	assert(SoundRules.uiKey("Play") == "ui_click", "botão comum")
	assert(SoundRules.uiKey("Slotted") == "ui_click", "só Slot + número é slot")
end

function spec.cooldown_segura_o_som_repetido()
	local limiter = SoundRules.newLimiter()
	local rule = { cooldown = 0.2, max = 3, length = 1 }
	assert(SoundRules.allow(limiter, "pickup", 10, rule, 12), "o primeiro toca")
	assert(not SoundRules.allow(limiter, "pickup", 10.1, rule, 12), "antes do cooldown não toca")
	assert(SoundRules.allow(limiter, "pickup", 10.2, rule, 12), "passado o cooldown toca")
	-- Outra chave não é afetada.
	assert(SoundRules.allow(limiter, "ui_click", 10.2, rule, 12), "cooldown é por chave")
end

function spec.limite_de_vozes_por_som_e_no_total()
	local limiter = SoundRules.newLimiter()
	local rule = { cooldown = 0, max = 2, length = 1 }
	assert(SoundRules.allow(limiter, "a", 0, rule, 3), "1ª voz de a")
	assert(SoundRules.allow(limiter, "a", 0.1, rule, 3), "2ª voz de a")
	assert(not SoundRules.allow(limiter, "a", 0.2, rule, 3), "3ª voz de a passa do limite do som")
	assert(SoundRules.allow(limiter, "b", 0.2, rule, 3), "3ª voz no total")
	assert(not SoundRules.allow(limiter, "c", 0.3, rule, 3), "4ª voz passa do limite total")
	-- As vozes acabam (length) e abrem lugar.
	assert(SoundRules.allow(limiter, "c", 1.05, rule, 3), "a 1ª voz acabou: cabe mais uma")
	assert(SoundRules.voices(limiter, 5) == 0, "depois de tudo acabar não sobra voz")
end

function spec.musica_segue_a_tela_e_a_hora()
	assert(SoundRules.musicMode("loading", false) == nil, "carregando: sem música")
	assert(SoundRules.musicMode("menu", true) == "menu", "menu tem a sua, de dia ou de noite")
	assert(SoundRules.musicMode("playing", false) == "day", "jogando de dia")
	assert(SoundRules.musicMode("playing", true) == "night", "jogando de noite")
	assert(SoundRules.musicMode("dead", true) == "death", "tela de morte")
	-- Sem saber a hora ainda (CycleStart não chegou), conta como dia.
	assert(SoundRules.musicMode("playing", nil) == "day", "sem hora = dia")
end

function spec.proxima_faixa_nunca_repete_a_ultima()
	for last = 1, 3 do
		for step = 0, 9 do
			local nextIndex = SoundRules.nextTrack(3, last, step / 10)
			assert(nextIndex >= 1 and nextIndex <= 3, "índice dentro da lista")
			assert(nextIndex ~= last, `não repete a faixa {last}`)
		end
	end
	-- Todas as outras faixas podem sair.
	assert(SoundRules.nextTrack(3, 2, 0) == 1 and SoundRules.nextTrack(3, 2, 0.99) == 3, "sorteia entre as outras")
	-- Primeira vez (sem última): qualquer uma.
	assert(
		SoundRules.nextTrack(3, nil, 0) == 1 and SoundRules.nextTrack(3, nil, 0.99) == 3,
		"sem última sorteia todas"
	)
	-- Uma faixa só: é ela mesma. Lista vazia: nada.
	assert(SoundRules.nextTrack(1, 1, 0.5) == 1, "uma faixa só repete")
	assert(SoundRules.nextTrack(0, nil, 0.5) == nil, "sem faixas não há o que tocar")
end

function spec.fade_anda_ate_o_alvo_sem_passar()
	-- 2 s para ir de 0 a 1: meio caminho em 1 s.
	assert(math.abs(SoundRules.approach(0, 1, 1, 2) - 0.5) < 1e-6, "sobe na velocidade do fade")
	assert(SoundRules.approach(0.9, 1, 1, 2) == 1, "não passa do alvo subindo")
	assert(math.abs(SoundRules.approach(1, 0, 0.5, 2) - 0.75) < 1e-6, "desce na mesma velocidade")
	assert(SoundRules.approach(0.1, 0, 1, 2) == 0, "não passa do alvo descendo")
	assert(SoundRules.approach(0.3, 1, 1, 0) == 1, "fade de 0 s pula para o alvo")
end

function spec.crossfade_soma_sempre_um()
	for i = 0, 10 do
		local out, into = SoundRules.crossfade(i / 10)
		assert(math.abs(out + into - 1) < 1e-6, "as duas faixas somam o volume cheio")
	end
	local out0, in0 = SoundRules.crossfade(0)
	assert(out0 == 1 and in0 == 0, "começo: só a faixa antiga")
	local out1, in1 = SoundRules.crossfade(1.5)
	assert(out1 == 0 and in1 == 1, "fim (e depois dele): só a nova")
end

function spec.hora_de_emendar_a_proxima_faixa()
	assert(not SoundRules.shouldAdvance(10, 120, 3), "no meio da faixa não troca")
	assert(SoundRules.shouldAdvance(117.5, 120, 3), "nos últimos segundos começa a próxima")
	assert(not SoundRules.shouldAdvance(0, 0, 3), "faixa que ainda não carregou não troca")
	-- Faixa mais curta que duas emendas: só troca no finzinho (não fica em fade eterno).
	assert(not SoundRules.shouldAdvance(1, 4, 3), "faixa curta não troca cedo")
	assert(SoundRules.shouldAdvance(3.9, 4, 3), "faixa curta troca no fim")
end

function spec.ganho_de_itens_no_inventario()
	local before = { [1] = { id = "wood", count = 5 }, [2] = { id = "stone", count = 2 } }
	local gained = { [1] = { id = "wood", count = 8 }, [2] = { id = "stone", count = 2 } }
	assert(SoundRules.gained(before, gained) == 3, "3 madeiras a mais")
	-- Mover de slot não é ganho.
	local moved = { [4] = { id = "wood", count = 5 }, [2] = { id = "stone", count = 2 } }
	assert(SoundRules.gained(before, moved) == 0, "mover não conta")
	-- Craft: gasta madeira e ganha machado: conta só o que entrou.
	local crafted =
		{ [1] = { id = "wood", count = 1 }, [2] = { id = "stone", count = 2 }, [3] = { id = "axe", count = 1 } }
	assert(SoundRules.gained(before, crafted) == 1, "item novo conta")
	assert(SoundRules.gained(before, {}) == 0, "perder tudo não é ganho")
end

function spec.contador_de_evento_do_mob()
	assert(not SoundRules.bumped(nil, 3), "primeira leitura não toca (o bicho acabou de aparecer)")
	assert(SoundRules.bumped(3, 4), "contador subiu: aconteceu")
	assert(not SoundRules.bumped(4, 4), "igual: nada")
	assert(not SoundRules.bumped(4, 0), "contador zerado (bicho reaproveitado) não toca")
end

function spec.volume_da_agua_pela_distancia()
	assert(SoundRules.waterVolume(0, 40) == 1, "dentro ou na beira: cheio")
	assert(SoundRules.waterVolume(40, 40) == 0, "no limite: mudo")
	assert(SoundRules.waterVolume(90, 40) == 0, "longe: mudo")
	local mid = SoundRules.waterVolume(20, 40)
	assert(mid > 0 and mid < 1, "no meio: parcial")
	assert(SoundRules.waterVolume(10, 40) > mid, "mais perto, mais alto")
end

function spec.fogos_mais_proximos_ganham_o_som()
	local distances = { 50, 10, 200, 30, 5, 70 }
	local picked = SoundRules.nearest(distances, 3, 80)
	assert(#picked == 3, "no máximo 3")
	assert(picked[1] == 5 and picked[2] == 2 and picked[3] == 4, "os 3 mais perto, em ordem")
	local few = SoundRules.nearest({ 100, 20 }, 3, 80)
	assert(#few == 1 and few[1] == 2, "fora do alcance não entra")
end

function spec.vida_baixa_liga_o_batimento()
	assert(SoundRules.heartbeat(40, 200, 0.25), "abaixo de 25% bate")
	assert(not SoundRules.heartbeat(60, 200, 0.25), "acima não")
	assert(not SoundRules.heartbeat(0, 200, 0.25), "morto não bate")
end

return spec
