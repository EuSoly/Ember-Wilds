--!strict
-- Animação da tela de morte (pura, testada no Lune): os pontos da vida descem
-- até 0 enquanto a Golden Ember sobe de 0 até o ganho, na mesma duração.

local CountUp = {}

-- (pontos mostrados, moeda mostrada) em t segundos. Linear e presa às pontas
-- fora de [0, duration]. Pontos arredondam para cima e moeda para baixo, para
-- só mostrar 0 pontos / moeda cheia no fim de verdade.
function CountUp.at(t: number, duration: number, points: number, currency: number): (number, number)
	local progress = if duration > 0 then math.clamp(t / duration, 0, 1) else 1
	local shownPoints = math.ceil(points * (1 - progress))
	local shownCurrency = math.floor(currency * progress)
	return shownPoints, shownCurrency
end

return CountUp
