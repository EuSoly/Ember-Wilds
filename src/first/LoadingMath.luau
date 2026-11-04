--!strict
-- Contas da barra de carregamento (puras, testadas no Lune). Fica em
-- ReplicatedFirst, junto do script do carregamento, porque ele roda antes de
-- o resto do jogo (ReplicatedStorage) chegar ao cliente.
--
-- Não sabemos o progresso real: enquanto espera, a barra anda sozinha e vai
-- freando perto de 90%; quando tudo fica pronto, corre até o fim. Na metade o
-- sol vira lua (é dia → noite), por isso a espera chega à metade em ~2 s:
-- dá tempo de ver o sol andar.
local LoadingMath = {}

LoadingMath.WAITING_TARGET = 0.9 -- até onde a barra vai sozinha
LoadingMath.WAIT_RATE = 0.4 -- por segundo; 0,9·(1−e^(−0,4·2)) ≈ 0,5 em 2 s
LoadingMath.FINISH_RATE = 1.5 -- fração da barra por segundo depois de pronto
LoadingMath.NIGHT_AT = 0.5 -- daqui em diante é noite (lua)

-- Próximo valor da barra depois de `dt` segundos.
function LoadingMath.step(progress: number, dt: number, ready: boolean): number
	if ready then
		return math.min(progress + dt * LoadingMath.FINISH_RATE, 1)
	end
	local target = LoadingMath.WAITING_TARGET
	if progress >= target then
		return progress -- nunca volta nem passa do alvo enquanto espera
	end
	return progress + (target - progress) * math.min(dt * LoadingMath.WAIT_RATE, 1)
end

function LoadingMath.isNight(progress: number): boolean
	return progress >= LoadingMath.NIGHT_AT
end

-- Texto embaixo da barra. Fixo aqui (e não no Strings) porque o Strings ainda
-- não chegou ao cliente nessa hora.
function LoadingMath.status(progress: number): string
	if progress >= 1 then
		return "Pronto!"
	elseif LoadingMath.isNight(progress) then
		return "Acendendo as fogueiras…"
	end
	return "Carregando o mundo…"
end

return LoadingMath
