--!strict
-- Quanto cada sofrimento aparece na borda da tela (puro, testado no Lune).
-- A tela (UI/StatusVignette) só pinta: 0 = nada, 1 = cheio (pulsando).
--   - barra baixa (fome, frio, sede, fôlego): começa abaixo da linha de alerta
--     dos anéis (WarningFraction), cresce até LOW_PEAK perto do zero e vai a 1
--     quando zera (é quando a barra começa a machucar);
--   - calor: o espelho (calor alto é o perigo). Com calor, o frio não aparece
--     (como no anel de temperatura);
--   - golpe: a vida caiu → clarão vermelho que some em FLASH_TIME.
local StatNames = require("../StatNames")

local ScreenFx = {}

ScreenFx.LOW_PEAK = 0.6 -- força logo antes de zerar
ScreenFx.FLASH_TIME = 0.6 -- segundos do clarão vermelho do golpe

export type Stats = { hunger: number, cold: number, heat: number, thirst: number, oxygen: number }
export type Levels = { hunger: number, cold: number, heat: number, thirst: number, oxygen: number }

-- Força do efeito de uma barra que faz mal quando BAIXA (0 a 1).
function ScreenFx.low(value: number, max: number): number
	if value <= 0 then
		return 1
	end
	local line = StatNames.WarningFraction * max
	if value >= line then
		return 0
	end
	return (1 - value / line) * ScreenFx.LOW_PEAK
end

function ScreenFx.levels(stats: Stats): Levels
	local max = StatNames.StatusMax
	local hot = stats.heat > 0
	return {
		hunger = ScreenFx.low(stats.hunger, max),
		cold = if hot then 0 else ScreenFx.low(stats.cold, max),
		heat = if hot then ScreenFx.low(max - stats.heat, max) else 0,
		thirst = ScreenFx.low(stats.thirst, max),
		oxygen = ScreenFx.low(stats.oxygen, max),
	}
end

-- Clarão do golpe, `since` segundos depois dele (1 → 0).
function ScreenFx.flash(since: number): number
	return math.clamp(1 - since / ScreenFx.FLASH_TIME, 0, 1)
end

-- A vida caiu desde a última leitura? (subir é comer ou curar.)
function ScreenFx.hit(previous: number?, current: number): boolean
	return previous ~= nil and current < previous
end

return ScreenFx
