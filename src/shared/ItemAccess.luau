--!strict
-- Quem pode ter um item. Item com `testOnly = true` só existe no Studio: fora
-- dele é como se não existisse (não entra no inventário, não se crafta, não
-- se coloca). Puro: `inStudio` vem de quem chama (RunService:IsStudio()).
local Defs = require("./Defs")
local Types = require("./Defs/Types")

local ItemAccess = {}

-- `items` é só para teste; o padrão é Defs.Items.
function ItemAccess.isAvailable(itemId: string, inStudio: boolean, items: { [string]: Types.ItemDef }?): boolean
	local item = (items or Defs.Items)[itemId]
	if item == nil then
		return false
	end
	return inStudio or item.testOnly ~= true
end

-- O resultado e todos os ingredientes precisam estar disponíveis.
function ItemAccess.recipeAvailable(
	recipe: Types.RecipeDef,
	inStudio: boolean,
	items: { [string]: Types.ItemDef }?
): boolean
	if not ItemAccess.isAvailable(recipe.result, inStudio, items) then
		return false
	end
	for _, ingredient in recipe.ingredients do
		if not ItemAccess.isAvailable(ingredient.id, inStudio, items) then
			return false
		end
	end
	return true
end

return ItemAccess
