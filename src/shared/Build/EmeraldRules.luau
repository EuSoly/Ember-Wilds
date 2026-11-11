--!strict
-- Máquina de esmeralda (puro, testado no Lune). Config oficial do Starve:
-- `forest_emerald_machine` = 750 pontos por minuto ao dono (os outros biomas
-- ainda não existem; os bônus de craft/coleta/abate/domar são 1 = sem bônus).
-- Só uma colocada por jogador; destruída (vida zerada), o dono morre.
local EmeraldRules = {}

EmeraldRules.POINTS_PER_MINUTE = 750

-- Pontos de `dt` segundos de máquina ligada.
function EmeraldRules.pointsFor(dt: number): number
	return EmeraldRules.POINTS_PER_MINUTE * dt / 60
end

-- Pode colocar outra? `owned` = quantas o jogador já tem no mundo.
function EmeraldRules.canPlace(owned: number): boolean
	return owned < 1
end

-- A máquina saiu do mundo com `health` de vida: só a destruída (0) mata o dono.
-- Removida com vida (o dono morreu ou saiu do jogo) não mata ninguém.
function EmeraldRules.killsOwner(health: number): boolean
	return health <= 0
end

-- Pontos inteiros a dar agora e o resto que fica para o próximo passo.
function EmeraldRules.split(points: number): (number, number)
	local whole = math.floor(points)
	return whole, points - whole
end

return EmeraldRules
