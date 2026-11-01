--!strict
-- Regras puras do crafting: podem rodar no servidor, cliente e testes.
local Inventory = require("../Inventory")
local Types = require("../Defs/Types")

type RecipeDef = Types.RecipeDef
type ItemDef = Types.ItemDef
type Counts = { [string]: number }

local CraftRules = {}
CraftRules.STATION_RADIUS = 10

function CraftRules.hasIngredients(recipe: RecipeDef, counts: Counts): boolean
	for _, part in recipe.ingredients do
		if (counts[part.id] or 0) < part.count then
			return false
		end
	end
	return true
end

function CraftRules.canCraft(recipe: RecipeDef, counts: Counts, near: { [string]: boolean }): boolean
	return CraftRules.hasIngredients(recipe, counts) and (recipe.station == nil or near[recipe.station] == true)
end

function CraftRules.duration(recipe: RecipeDef, held: ItemDef?): number
	local speed = if held ~= nil then held.craftSpeed or 1 else 1
	return recipe.time / speed
end

function CraftRules.craftable(
	recipes: { [string]: RecipeDef },
	counts: Counts,
	near: { [string]: boolean }
): { RecipeDef }
	local out = {}
	for _, recipe in recipes do
		if CraftRules.canCraft(recipe, counts, near) then
			table.insert(out, recipe)
		end
	end
	table.sort(out, function(a, b)
		if a.order == b.order then
			return a.id < b.id
		end
		return a.order < b.order
	end)
	return out
end

function CraftRules.fits(inv: Inventory.Inventory, recipe: RecipeDef, maxStackOf: (string) -> number): boolean
	local copy: Inventory.Inventory = { capacity = inv.capacity, slots = {} }
	for index, slot in inv.slots do
		copy.slots[index] = { id = slot.id, count = slot.count }
	end
	for _, part in recipe.ingredients do
		if not Inventory.remove(copy, part.id, part.count) then
			return false
		end
	end
	local remaining = Inventory.add(copy, recipe.result, recipe.count, maxStackOf(recipe.result))
	return remaining == 0
end

function CraftRules.progress(startTime: number, endTime: number, now: number): number
	if endTime <= startTime then
		return 1
	end
	return math.clamp((now - startTime) / (endTime - startTime), 0, 1)
end

return table.freeze(CraftRules)
