--!strict
-- Boost de XP (puro, testado no Lune). O fator vai de 1 a 2: 1 + a fração da
-- vida que aconteceu dentro da janela do boost (tudo em segundos unix).
local XpBoost = {}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function XpBoost.factor(lifeStart: number, lifeEnd: number, boostStart: number, boostUntil: number): number
	if not (isFinite(lifeStart) and isFinite(lifeEnd) and isFinite(boostStart) and isFinite(boostUntil)) then
		return 1
	end
	local duration = lifeEnd - lifeStart
	if duration <= 0 or boostUntil <= boostStart then
		return 1
	end
	local overlap = math.min(lifeEnd, boostUntil) - math.max(lifeStart, boostStart)
	if overlap <= 0 then
		return 1
	end
	return 1 + math.min(overlap / duration, 1)
end

return XpBoost
