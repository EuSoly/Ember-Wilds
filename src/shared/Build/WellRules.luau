--!strict
-- Regras puras do poço (G8): quantos goles ele guarda. O servidor (WellService)
-- aplica; os testes também.
local Types = require("../Defs/Types")

export type WellDef = Types.WellDef

local WellRules = {}

-- Esvazia um balde no poço: `drinks` + drinksPerBucket, até maxDrinks.
-- nil se o poço já está cheio (nada muda e o balde fica com o jogador).
function WellRules.fill(drinks: number, def: WellDef): number?
	if drinks >= def.maxDrinks then
		return nil
	end
	return math.min(drinks + def.drinksPerBucket, def.maxDrinks)
end

-- Um gole: `drinks` - 1. nil se o poço está vazio.
function WellRules.drink(drinks: number): number?
	if drinks <= 0 then
		return nil
	end
	return drinks - 1
end

return WellRules
