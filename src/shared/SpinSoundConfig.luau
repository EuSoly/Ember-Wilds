--!strict
-- Sons da roleta (tela do giro na loja). Para trocar um som: troque o soundId
-- por outro áudio da loja do Roblox (create.roblox.com/store/audio, copie o
-- número do link) e ajuste o volume (0 a 1). Tocam no grupo "Effects"
-- (volume de efeitos das configurações).
--
--   tick      — um "clique" a cada quadradinho que passa pelo marcador; vai
--               espaçando sozinho conforme o carrossel freia.
--   riser     — chiado que sobe no fim do giro (suspense).
--   drumroll  — rufar de tambores no fim (só Lendário e Mítico).
--   whoosh    — "vupt" quando começa um giro pago.
--   reveal[r] — som quando o carrossel para, um por raridade (1 Comum … 5 Mítico).
--
-- `tension[r]` diz quanto suspense cada raridade tem (0 = nenhum, 1 = máximo):
-- o som acompanha a raridade que VAI sair, então quem gira sente o Mítico
-- chegando. Comum não tem suspense nenhum.
export type Sound = { soundId: string, volume: number }
export type Tension = { riser: number, drum: number }

local function sound(id: number, volume: number): Sound
	return table.freeze({ soundId = `rbxassetid://{id}`, volume = volume })
end

local SpinSoundConfig = {
	tick = sound(87342128651257, 0.35), -- "Click"
	riser = sound(9040281024, 0.55), -- APM "Amplified Expanse" (5,75 s)
	drumroll = sound(1840444182, 0.6), -- APM "Drum Rolls (A)" (8,3 s, em loop)
	whoosh = sound(9125647922, 0.5), -- ProSoundEffects "Magic Zoom Up" (1,2 s)
	reveal = table.freeze({
		sound(89768356509411, 0.5), -- Comum: "snd_ding"
		sound(99980076888596, 0.5), -- Raro: "jingle chime positive"
		sound(110445510039757, 0.6), -- Épico: "achievement"
		sound(4757565956, 0.6), -- Lendário: "TaDa"
		sound(1846901578, 0.6), -- Mítico: APM "Bigger Than Big 9" (orquestra)
	}),
	tension = table.freeze({
		table.freeze({ riser = 0, drum = 0 }), -- Comum
		table.freeze({ riser = 0.2, drum = 0 }), -- Raro
		table.freeze({ riser = 0.5, drum = 0 }), -- Épico
		table.freeze({ riser = 0.8, drum = 0.4 }), -- Lendário
		table.freeze({ riser = 1, drum = 1 }), -- Mítico
	}),
}

return table.freeze(SpinSoundConfig) :: {
	tick: Sound,
	riser: Sound,
	drumroll: Sound,
	whoosh: Sound,
	reveal: { Sound },
	tension: { Tension },
}
