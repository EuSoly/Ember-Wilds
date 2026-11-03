--!strict
-- Regras puras das máquinas a madeira (G8): o extrator (madeira → pedra/ouro,
-- com estoque para pegar) e a fornalha (queima madeira e esquenta enquanto tem).
-- O servidor (MachineService) roda os passos num loop; os testes também.
--
-- Os passos não mudam o estado recebido: devolvem um novo. `timer` = segundos
-- já acumulados no ciclo atual; parada (sem madeira, cheia, apagada) não
-- acumula, então o ciclo recomeça do zero quando volta a trabalhar.
local Types = require("../Defs/Types")

export type ExtractorDef = Types.ExtractorDef
export type FurnaceDef = Types.FurnaceDef

export type ExtractorState = { wood: number, stock: number, timer: number }
export type FurnaceState = { wood: number, timer: number }

local MachineRules = {}

-- O item que as máquinas gastam (a ação put_wood).
MachineRules.FUEL = "wood"
-- Madeiras por ação put_wood, no máximo.
MachineRules.WOOD_PER_PUT = 10

-- Passo de tempo que conta: positivo e finito (0, negativo, NaN, inf: nada).
local function validDt(dt: number): boolean
	return dt > 0 and dt < math.huge
end

-- O extrator trabalha agora? Precisa de madeira para um ciclo e estoque não cheio.
function MachineRules.isWorking(state: ExtractorState, def: ExtractorDef): boolean
	return state.wood >= def.woodPerCycle and state.stock < def.maxStock
end

-- Avança o extrator `dt` segundos: a cada `cycleSeconds` trabalhando,
-- `wood -= woodPerCycle` e `stock += yield` (até `maxStock`).
function MachineRules.extractorStep(state: ExtractorState, def: ExtractorDef, dt: number): ExtractorState
	local s = { wood = state.wood, stock = state.stock, timer = state.timer }
	if not validDt(dt) then
		return s
	end
	if not MachineRules.isWorking(s, def) then
		s.timer = 0
		return s
	end
	s.timer += dt
	-- Cada volta gasta madeira ou enche o estoque: o laço sempre termina.
	while s.timer >= def.cycleSeconds and MachineRules.isWorking(s, def) do
		s.timer -= def.cycleSeconds
		s.wood -= def.woodPerCycle
		s.stock = math.min(s.stock + def.yield, def.maxStock)
	end
	if not MachineRules.isWorking(s, def) then
		s.timer = 0
	end
	return s
end

-- A fornalha está acesa (esquenta e é estação "fire")? Só com madeira dentro.
function MachineRules.isLit(state: FurnaceState): boolean
	return state.wood > 0
end

-- Avança a fornalha `dt` segundos: queima 1 madeira a cada `burnEvery` enquanto
-- tem; apaga em 0.
function MachineRules.furnaceStep(state: FurnaceState, def: FurnaceDef, dt: number): FurnaceState
	local s = { wood = state.wood, timer = state.timer }
	if not validDt(dt) then
		return s
	end
	if not MachineRules.isLit(s) then
		s.timer = 0
		return s
	end
	s.timer += dt
	while s.timer >= def.burnEvery and MachineRules.isLit(s) do
		s.timer -= def.burnEvery
		s.wood = math.max(s.wood - 1, 0)
	end
	if not MachineRules.isLit(s) then
		s.timer = 0
	end
	return s
end

-- Quantas madeiras entram numa ação put_wood: até WOOD_PER_PUT, até o que o
-- jogador tem (`have`) e até caber (`max - wood`). Nunca negativo; inteiro.
function MachineRules.putWood(wood: number, have: number, max: number): number
	local room = max - wood
	-- NaN em qualquer ponta: math.min não é confiável com NaN, então recusa antes.
	if not (have > 0 and room > 0) then
		return 0
	end
	return math.floor(math.min(MachineRules.WOOD_PER_PUT, have, room))
end

return table.freeze(MachineRules)
