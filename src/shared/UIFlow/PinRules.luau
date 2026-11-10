--!strict
-- Receita fixada no HUD (puro, testado no Lune): os ingredientes com quanto o
-- jogador tem e quanto a receita pede. A contagem não tem teto ("15/10"), para
-- o jogador ver que já passou do necessário. O painel é do cliente
-- (UI/PinnedRecipe); qual receita está fixada fica em PinState.
local Defs = require("../Defs")

export type Line = { item: string, have: number, need: number, done: boolean }

local PinRules = {}

function PinRules.lines(recipeId: string, counts: { [string]: number }): { Line }
	local recipe = Defs.Recipes[recipeId]
	local out: { Line } = {}
	if recipe == nil then
		return out
	end
	for _, ingredient in recipe.ingredients do
		local have = counts[ingredient.id] or 0
		table.insert(
			out,
			{ item = ingredient.id, have = have, need = ingredient.count, done = have >= ingredient.count }
		)
	end
	return out
end

-- true se já tem tudo para fazer a receita.
function PinRules.ready(recipeId: string, counts: { [string]: number }): boolean
	local lines = PinRules.lines(recipeId, counts)
	if #lines == 0 then
		return false
	end
	for _, line in lines do
		if not line.done then
			return false
		end
	end
	return true
end

return PinRules
