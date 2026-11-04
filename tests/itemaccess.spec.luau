--!strict
local ItemAccess = require("../src/shared/ItemAccess")

local items: any = {
	wood = { id = "wood", nameKey = "item.wood", category = "resource", maxStack = 255 },
	secret = { id = "secret", nameKey = "item.secret", category = "resource", maxStack = 1, testOnly = true },
}

local function recipe(result: string, ingredient: string): any
	return {
		id = "r",
		result = result,
		count = 1,
		ingredients = { { id = ingredient, count = 1 } },
		time = 1,
		order = 1,
	}
end

return {
	["normal item is available everywhere"] = function()
		assert(ItemAccess.isAvailable("wood", true, items), "falhou: ItemAccess.isAvailable('wood', true, items)")
		assert(ItemAccess.isAvailable("wood", false, items), "falhou: ItemAccess.isAvailable('wood', false, items)")
	end,

	["testOnly item exists only in Studio"] = function()
		assert(ItemAccess.isAvailable("secret", true, items), "falhou: ItemAccess.isAvailable('secret', true, items)")
		assert(not ItemAccess.isAvailable("secret", false, items), "testOnly não pode existir fora do Studio")
	end,

	["unknown item is unavailable"] = function()
		assert(
			not ItemAccess.isAvailable("nope", true, items),
			"falhou: not ItemAccess.isAvailable('nope', true, items)"
		)
		assert(
			not ItemAccess.isAvailable("nope", false, items),
			"falhou: not ItemAccess.isAvailable('nope', false, items)"
		)
	end,

	["recipe with testOnly result is unavailable outside Studio"] = function()
		assert(
			not ItemAccess.recipeAvailable(recipe("secret", "wood"), false, items),
			"falhou: not ItemAccess.recipeAvailable(recipe('secret', 'wood'), false, items)"
		)
		assert(
			ItemAccess.recipeAvailable(recipe("secret", "wood"), true, items),
			"falhou: ItemAccess.recipeAvailable(recipe('secret', 'wood'), true, items)"
		)
	end,

	["recipe with testOnly ingredient is unavailable outside Studio"] = function()
		assert(
			not ItemAccess.recipeAvailable(recipe("wood", "secret"), false, items),
			"falhou: not ItemAccess.recipeAvailable(recipe('wood', 'secret'), false, items)"
		)
		assert(
			ItemAccess.recipeAvailable(recipe("wood", "secret"), true, items),
			"falhou: ItemAccess.recipeAvailable(recipe('wood', 'secret'), true, items)"
		)
	end,

	["normal recipe is available outside Studio"] = function()
		assert(
			ItemAccess.recipeAvailable(recipe("wood", "wood"), false, items),
			"falhou: ItemAccess.recipeAvailable(recipe('wood', 'wood'), false, items)"
		)
	end,

	["real defs: no item is testOnly yet, so wood is available"] = function()
		assert(ItemAccess.isAvailable("wood", false), "falhou: ItemAccess.isAvailable('wood', false)")
	end,
}
