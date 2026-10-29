--!strict
-- Iluminação de dia e de noite (só números e hex: testável no Lune).
-- O DayNightController faz a transição entre os dois climas no amanhecer e no
-- anoitecer. O sol fica parado (ClockTime fixo): a noite é feita com brilho,
-- luz ambiente e um tom azul na correção de cor. Girar o relógio do Roblox
-- faria o sol "voltar" no amanhecer e mexeria nas sombras de um jeito estranho
-- para uma câmera de cima.
--
-- Regra da identidade visual: a noite é azul e escura, mas ainda dá para ver
-- o chão e um mob chegando no celular; o fogo vira o ponto quente da tela.

export type Mood = {
	Brightness: number,
	Ambient: string,
	OutdoorAmbient: string,
	ExposureCompensation: number,
	TintColor: string, -- ColorCorrectionEffect
	ColorBrightness: number,
	Contrast: number,
	Saturation: number,
	AtmosphereDensity: number,
	AtmosphereColor: string,
}

return table.freeze({
	CLOCK_TIME = 14, -- hora fixa do sol (tarde)
	TRANSITION_SECONDS = 10,

	day = table.freeze({
		Brightness = 2,
		Ambient = "#46464F",
		OutdoorAmbient = "#8A8A8A",
		ExposureCompensation = 0,
		TintColor = "#FFFFFF",
		ColorBrightness = 0,
		Contrast = 0,
		Saturation = 0,
		AtmosphereDensity = 0.3,
		AtmosphereColor = "#C7C7C7",
	} :: Mood),

	night = table.freeze({
		Brightness = 0.6,
		Ambient = "#2A3A66",
		OutdoorAmbient = "#3B4F86",
		ExposureCompensation = -0.4,
		TintColor = "#9FB4FF",
		ColorBrightness = -0.05,
		Contrast = 0.1,
		Saturation = -0.15,
		AtmosphereDensity = 0.35,
		AtmosphereColor = "#3B4F86",
	} :: Mood),
})
