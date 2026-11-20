--!strict
-- Escada de itens dos bots (puro; spec 2026-11-20-bots-design): o que craftar
-- a seguir, até no máximo pedra (decisão: a caixa do bot não vira loot farto e
-- o revide não mata novato de um golpe). Fogueira e bancada não estão aqui: a
-- fogueira sai do frio/noite e a bancada da receita que pede bancada
-- (BotBrain). Números das receitas: Defs.Recipes.
local Defs = require("../Defs")

local BotLadder = {}

BotLadder.STEPS = table.freeze({
	"wood_pickaxe",
	"wood_sword",
	"stone_pickaxe",
	"stone_sword",
	"wood_helmet",
	"stone_helmet",
})

-- Item que substitui o degrau (a receita de cima gasta o de baixo).
local UPGRADE: { [string]: string } = {
	wood_pickaxe = "stone_pickaxe",
	wood_sword = "stone_sword",
	wood_helmet = "stone_helmet",
}

local function has(owned: { [string]: number }, id: string): boolean
	if (owned[id] or 0) > 0 then
		return true
	end
	local up = UPGRADE[id]
	return up ~= nil and has(owned, up)
end

-- Próximo degrau que o bot ainda não tem (nil = escada completa).
function BotLadder.next(owned: { [string]: number }): string?
	for _, id in BotLadder.STEPS do
		if not has(owned, id) then
			return id
		end
	end
	return nil
end

-- Quanto falta de cada ingrediente da receita `recipeId` (só os que faltam).
function BotLadder.missing(recipeId: string, counts: { [string]: number }): { [string]: number }
	local out: { [string]: number } = {}
	local recipe = Defs.Recipes[recipeId]
	if recipe == nil then
		return out
	end
	for _, ingredient in recipe.ingredients do
		local short = ingredient.count - (counts[ingredient.id] or 0)
		if short > 0 then
			out[ingredient.id] = short
		end
	end
	return out
end

return BotLadder
