--!strict
-- Reset pelo menu do Roblox ("Reset Character"; pedido do Elizeu, 18/11/2026):
-- o jogador precisa ficar parado SECONDS segundos; andar mais que
-- MOVE_TOLERANCE studs no chão (X e Z) cancela. Pular no lugar não conta.
-- O DeathService conta o tempo e confere a posição; aqui só a regra.
local ResetRules = {}

ResetRules.SECONDS = 10
ResetRules.MOVE_TOLERANCE = 1.5 -- studs: balanço e empurrão pequeno não cancelam

-- Saiu do lugar (de x0,z0 para x1,z1)?
function ResetRules.moved(x0: number, z0: number, x1: number, z1: number): boolean
	local dx, dz = x1 - x0, z1 - z0
	return dx * dx + dz * dz > ResetRules.MOVE_TOLERANCE * ResetRules.MOVE_TOLERANCE
end

-- Já ficou parado o tempo todo?
function ResetRules.done(elapsed: number): boolean
	return elapsed >= ResetRules.SECONDS
end

return ResetRules
