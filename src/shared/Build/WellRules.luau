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

-- Dá para beber agora? Precisa de água no poço e de sede não cheia (o
-- servidor confere de novo; isto só apaga o botão).
function WellRules.canDrink(drinks: number, thirst: number, thirstMax: number): boolean
	return drinks > 0 and thirst < thirstMax
end

-- Dá para encher? Precisa do balde cheio na mão e de espaço no poço.
function WellRules.canFill(held: string?, drinks: number, def: WellDef): boolean
	return held == "water_bucket" and drinks < def.maxDrinks
end

-- Quanto do poço está cheio (0 a 1), para o medidor de água.
function WellRules.fraction(drinks: number, def: WellDef): number
	if def.maxDrinks <= 0 then
		return 0
	end
	return math.clamp(drinks / def.maxDrinks, 0, 1)
end

return WellRules
