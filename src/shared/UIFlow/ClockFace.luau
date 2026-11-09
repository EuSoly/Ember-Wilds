--!strict
-- Relógio do HUD (aprovado no rascunho de 09/11), puro e testado no Lune: o
-- texto da hora (24 h; AM/PM para quem joga com o Roblox em inglês), as cores
-- da janelinha de céu em cada hora (amanhecer, dia, entardecer, noite), onde
-- está o sol ou a lua e quanto aparecem as estrelas. A hora vem de
-- DayCycle.at(...).hours (06:00 = amanhecer, 18:00 = anoitecer).
local ClockFace = {}

local MINUTE_STEP = 10 -- o relógio anda de 10 em 10 minutos (1 s real = 3 min de jogo)

-- Pontos-chave do céu: hora, cor de cima, cor de baixo. Entre eles a cor
-- passa suave; o primeiro e o último são iguais (meia-noite sem salto).
local SKY: { { at: number, top: string, bottom: string } } = {
	{ at = 0, top = "#0B1440", bottom = "#1D2A6B" },
	{ at = 4.5, top = "#0B1440", bottom = "#1D2A6B" },
	{ at = 5.5, top = "#5A3C86", bottom = "#F08A7A" }, -- amanhecer: roxo e rosa
	{ at = 6.5, top = "#F2A65E", bottom = "#FFD08A" }, -- nascer do sol: laranja
	{ at = 7.5, top = "#7CC4F2", bottom = "#CDEEFF" }, -- dia
	{ at = 16.5, top = "#7CC4F2", bottom = "#CDEEFF" },
	{ at = 17.5, top = "#F2A65E", bottom = "#FF8A4A" }, -- entardecer: laranja
	{ at = 18.5, top = "#5A3C86", bottom = "#D0607A" }, -- pôr do sol: roxo
	{ at = 19.5, top = "#0B1440", bottom = "#1D2A6B" }, -- noite
	{ at = 24, top = "#0B1440", bottom = "#1D2A6B" },
}

function ClockFace.isEnglish(localeId: string): boolean
	return string.lower(string.sub(localeId, 1, 2)) == "en"
end

-- "14:30" (24 h) ou "2:30 PM" (12 h), de 10 em 10 minutos.
function ClockFace.timeText(hours: number, twelveHour: boolean): string
	local h = math.floor(hours) % 24
	local minutes = math.floor((hours % 1) * 60 / MINUTE_STEP) * MINUTE_STEP
	if twelveHour then
		local suffix = if h < 12 then "AM" else "PM"
		local h12 = (h + 11) % 12 + 1
		return string.format("%d:%02d %s", h12, minutes, suffix)
	end
	return string.format("%02d:%02d", h, minutes)
end

local function channel(hex: string, i: number): number
	return tonumber(string.sub(hex, i, i + 1), 16) :: number
end

local function mix(a: string, b: string, t: number): string
	local out = "#"
	for _, i in { 2, 4, 6 } do
		local va, vb = channel(a, i), channel(b, i)
		out ..= string.format("%02X", math.floor(va + (vb - va) * t + 0.5))
	end
	return out
end

-- Cores do céu (cima, baixo) em "#RRGGBB".
function ClockFace.sky(hours: number): (string, string)
	local h = hours % 24
	for i = 1, #SKY - 1 do
		local a, b = SKY[i], SKY[i + 1]
		if h >= a.at and h <= b.at then
			local t = if b.at > a.at then (h - a.at) / (b.at - a.at) else 0
			return mix(a.top, b.top, t), mix(a.bottom, b.bottom, t)
		end
	end
	return SKY[1].top, SKY[1].bottom
end

-- Sol (de dia) ou lua (de noite) e quanto do caminho já andou (0 = entrou
-- pela esquerda, 1 = saiu pela direita). Cada um atravessa em 12 horas.
function ClockFace.body(hours: number): (boolean, number)
	local h = hours % 24
	if h >= 6 and h < 18 then
		return true, (h - 6) / 12
	end
	return false, ((h - 18) % 24) / 12
end

-- Estrelas: 0 de dia, 1 de noite; acendem das 18:30 às 19:30 e apagam das
-- 04:30 às 05:30.
function ClockFace.stars(hours: number): number
	local h = hours % 24
	if h >= 19.5 or h < 4.5 then
		return 1
	elseif h >= 18.5 and h < 19.5 then
		return h - 18.5
	elseif h >= 4.5 and h < 5.5 then
		return 5.5 - h
	end
	return 0
end

return ClockFace
