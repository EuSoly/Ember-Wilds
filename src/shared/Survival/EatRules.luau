--!strict
-- Regras puras do comer com tempo (testadas no Lune): a mordida dura
-- SurvivalConfig.EAT_DURATION e termina no instante gravado no atributo
-- EatUntil do personagem (relógio do servidor, GetServerTimeNow).
local EatRules = {}

-- Está no meio de uma mordida? `eatUntil` é o valor cru do atributo.
function EatRules.isEating(eatUntil: any, now: number): boolean
	return type(eatUntil) == "number" and eatUntil == eatUntil and now < eatUntil
end

-- Quanto da mordida já passou (0 no começo, 1 no fim), ou nil fora dela.
-- Um EatUntil mais longe que uma mordida inteira (relógios fora de sincronia)
-- conta como começo.
function EatRules.progress(eatUntil: any, now: number, duration: number): number?
	if not EatRules.isEating(eatUntil, now) or duration <= 0 then
		return nil
	end
	local p = 1 - (eatUntil - now) / duration
	return math.clamp(p, 0, 1)
end

return EatRules
