--!strict
-- Textos dos números do Perfil (puro, testado no Lune): separador de milhar
-- ("18.300") e tempo de jogo ("12h 30min"; abaixo de uma hora, "45min").
local ProfileFormat = {}

local function valid(value: number): number
	if type(value) ~= "number" or value ~= value or value == math.huge or value < 0 then
		return 0
	end
	return math.floor(value)
end

function ProfileFormat.thousands(value: number): string
	local text = tostring(valid(value))
	-- Ponto a cada três casas, da direita para a esquerda.
	local out = string.reverse((string.gsub(string.reverse(text), "(%d%d%d)", "%1.")))
	return (string.gsub(out, "^%.", ""))
end

function ProfileFormat.playtime(seconds: number): string
	local minutesTotal = math.floor(valid(seconds) / 60)
	local hours = math.floor(minutesTotal / 60)
	local minutes = minutesTotal % 60
	if hours == 0 then
		return `{minutes}min`
	end
	return `{hours}h {minutes}min`
end

return ProfileFormat
