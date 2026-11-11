--!strict
-- Máquina de esmeralda (puro, testado no Lune). Config oficial do Starve:
-- `forest_emerald_machine` = 750 pontos por minuto ao dono (os outros biomas
-- ainda não existem; os bônus de craft/coleta/abate/domar são 1 = sem bônus).
-- Uma por jogador (structure.maxPerPlayer); destruída por outra pessoa, o dono morre.
local EmeraldRules = {}

EmeraldRules.POINTS_PER_MINUTE = 750

-- Pontos de `dt` segundos de máquina ligada.
function EmeraldRules.pointsFor(dt: number): number
	return EmeraldRules.POINTS_PER_MINUTE * dt / 60
end

-- A máquina saiu do mundo com `health` de vida: só a destruída (0) por outra
-- pessoa mata o dono. O dono (ou um aliado) quebrar a própria não mata (pedido
-- do Elizeu, 11/11); removida com vida (o dono morreu ou saiu) também não.
function EmeraldRules.killsOwner(health: number, byAlly: boolean): boolean
	return health <= 0 and not byAlly
end

-- Pontos inteiros a dar agora e o resto que fica para o próximo passo.
function EmeraldRules.split(points: number): (number, number)
	local whole = math.floor(points)
	return whole, points - whole
end

return EmeraldRules
