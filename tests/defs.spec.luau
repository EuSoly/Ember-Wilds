--!strict
local Defs = require("../src/shared/Defs")
local Validate = require("../src/shared/Defs/Validate")

local function validTier(id: string, order: number): any
	return { id = id, order = order, color = "#8B5A2B", rarityKey = "rarity.common", nameKey = "tier." .. id }
end

local function validItem(id: string): any
	return { id = id, nameKey = "item." .. id, category = "resource", maxStack = 255 }
end

local function alwaysHas(_key: string): boolean
	return true
end

local function containsError(errors: { string }, fragment: string): boolean
	for _, message in errors do
		if string.find(message, fragment, 1, true) then
			return true
		end
	end
	return false
end

return {
	["real defs load and validate"] = function()
		assert(Defs.Tiers.gold.order == 3, `ordem do ouro: {Defs.Tiers.gold.order}`)
		assert(Defs.Tiers.gold.color == "#F2B632", `cor do ouro: {Defs.Tiers.gold.color}`)
		assert(Defs.Tiers.reidite.rarityKey == "rarity.legendary", "reidite deveria ser lendário")
		assert(Defs.Items.gold_pickaxe.tier == "gold", "picareta de ouro sem tier gold")
		assert(Defs.Items.wood.tier == nil, "madeira (recurso) não tem tier")
	end,

	["valid fake defs give no errors"] = function()
		local errors = Validate.all({
			Tiers = { wood = validTier("wood", 1) },
			Items = { wood = validItem("wood") },
		}, alwaysHas)
		assert(#errors == 0, `erros inesperados: {table.concat(errors, "; ")}`)
	end,

	["unknown tier is an error"] = function()
		local item = validItem("cup")
		item.tier = "plastic"
		local errors = Validate.all({ Tiers = { wood = validTier("wood", 1) }, Items = { cup = item } }, alwaysHas)
		assert(containsError(errors, "plastic"), `faltou erro do tier: {table.concat(errors, "; ")}`)
	end,

	["id must equal key"] = function()
		local errors = Validate.all({ Tiers = {}, Items = { wood = validItem("Wood") } }, alwaysHas)
		assert(containsError(errors, "Wood"), `faltou erro de id: {table.concat(errors, "; ")}`)
	end,

	["id must be snake case"] = function()
		local errors = Validate.all({ Tiers = {}, Items = { ["Wood"] = validItem("Wood") } }, alwaysHas)
		assert(#errors > 0, "id com maiúscula deveria falhar")
	end,

	["maxStack must be at least 1"] = function()
		local item = validItem("wood")
		item.maxStack = 0
		local errors = Validate.all({ Tiers = {}, Items = { wood = item } }, alwaysHas)
		assert(containsError(errors, "maxStack"), `faltou erro de maxStack: {table.concat(errors, "; ")}`)
	end,

	["real bag has bag slots"] = function()
		local bag = Defs.Items.leather_bag
		assert(bag ~= nil and bag.category == "bag", "mochila de couro deveria existir")
		assert(bag.bagSlots == 6, `mochila de couro deveria dar 6 slots, deu {bag.bagSlots}`)
	end,

	["bag without bag slots is an error"] = function()
		local item = validItem("sack")
		item.category = "bag"
		item.maxStack = 1
		local errors = Validate.all({ Tiers = {}, Items = { sack = item } }, alwaysHas)
		assert(containsError(errors, "bagSlots"), `faltou erro de bagSlots: {table.concat(errors, "; ")}`)
	end,

	["bag slots only on bags"] = function()
		local item = validItem("wood")
		item.bagSlots = 4
		local errors = Validate.all({ Tiers = {}, Items = { wood = item } }, alwaysHas)
		assert(
			containsError(errors, "bagSlots"),
			`faltou erro de bagSlots fora de mochila: {table.concat(errors, "; ")}`
		)
	end,

	["bag slots cannot pass the slot limit"] = function()
		local item = validItem("huge_bag")
		item.category = "bag"
		item.maxStack = 1
		item.bagSlots = 99
		local errors = Validate.all({ Tiers = {}, Items = { huge_bag = item } }, alwaysHas)
		assert(containsError(errors, "bagSlots"), `faltou erro de limite: {table.concat(errors, "; ")}`)
	end,

	["missing string is an error"] = function()
		local errors = Validate.all({ Tiers = {}, Items = { wood = validItem("wood") } }, function(key)
			return key ~= "item.wood"
		end)
		assert(containsError(errors, "item.wood"), `faltou erro de texto: {table.concat(errors, "; ")}`)
	end,
}
