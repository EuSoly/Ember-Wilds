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
--   start     — "vupt" curto quando começa um giro normal.
--   whoosh    — "vupt" mágico quando começa um giro pago.
--   land      — batida seca quando o carrossel para (antes da revelação).
--   reveal[r] — som quando a janelinha do prêmio abre, um por raridade
--               (1 Comum … 6 Mítico).
--   shine     — brilho por cima da revelação; `shineFor[r]` é o quanto dele
--               cada raridade leva (0 = não toca).
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
	start = sound(9120972321, 0.3), -- ProSoundEffects "Wood Whoosh Slicing Air Quick Swings 4" (0,6 s)
	whoosh = sound(9125647922, 0.5), -- ProSoundEffects "Magic Zoom Up" (1,2 s)
	land = sound(9126267413, 0.55), -- ProSoundEffects "Wood Hit Giant Wood Beam Dull Thuds Knocks 1" (0,63 s)
	shine = sound(9116394545, 0.5), -- ProSoundEffects "Magic Glows Soft Clusters Of Chiming Hits 1" (1,43 s)
	shineFor = table.freeze({ 0, 0, 0, 0.5, 0.8, 1 }),
	-- Revelação (12/11): todos da APM (licenciados pela Roblox, não somem da
	-- loja), crescendo com a raridade. O Elizeu ouviu no Studio e escolheu o
	-- Lendário e o Mítico entre opções.
	reveal = table.freeze({
		sound(1839997929, 0.4), -- Comum: APM "Correct Answer 2", acerto com synth brilhante (4,7 s)
		sound(1839997916, 0.45), -- Incomum: APM "Correct Answer 1", acerto com synth subindo e eco (5 s)
		sound(1839997938, 0.5), -- Raro: APM "Correct Answer 3", acerto com brilho subindo (5,2 s)
		sound(1845399641, 0.55), -- Épico: APM "Ta Dah" (5,3 s)
		sound(9045742092, 0.6), -- Lendário: APM "To the Fray (sting a)", cordas e tambores épicos (7,8 s)
		sound(1845406075, 0.6), -- Mítico: APM "Ethereal Drone", clima etéreo (7 s)
	}),
	revealUncommon = sound(1839997916, 0.45),
	tension = table.freeze({
		table.freeze({ riser = 0, drum = 0 }), -- Comum
		table.freeze({ riser = 0.1, drum = 0 }), -- Incomum
		table.freeze({ riser = 0.25, drum = 0 }), -- Raro
		table.freeze({ riser = 0.5, drum = 0 }), -- Épico
		table.freeze({ riser = 0.8, drum = 0.4 }), -- Lendário
		table.freeze({ riser = 1, drum = 1 }), -- Mítico
	}),
}

return table.freeze(SpinSoundConfig) :: {
	tick: Sound,
	riser: Sound,
	drumroll: Sound,
	start: Sound,
	whoosh: Sound,
	land: Sound,
	shine: Sound,
	shineFor: { number },
	reveal: { Sound },
	revealUncommon: Sound,
	tension: { Tension },
}
