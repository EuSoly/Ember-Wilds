--!strict
local SpinRoll = require("../src/shared/Shop/SpinRoll")
local CosmeticCatalog = require("../src/shared/UIFlow/CosmeticCatalog")
local Defs = require("../src/shared/Defs")

local function never(_id: string): boolean
	return false
end

local function always(_id: string): boolean
	return true
end

return {
	["roulette without skins cannot spin"] = function()
		assert(SpinRoll.roll("accessory", "normal", never, 0.5, 0.5) == nil, "acessório não tem skins")
	end,

	["unknown roulette cannot spin"] = function()
		assert(SpinRoll.roll("nada", "paid", never, 0.5, 0.5) == nil, "tipo inventado")
	end,

	["new skin is given without refund"] = function()
		local roll = SpinRoll.roll("body", "normal", never, 0.3, 0.7)
		assert(roll ~= nil, "corpo tem skins")
		local cosmetic = Defs.Cosmetics[roll.itemId]
		assert(cosmetic ~= nil and cosmetic.slot == "body", `{roll.itemId} deveria ser um corpo`)
		assert(not roll.duplicate and roll.refund == 0, "skin nova não devolve nada")
	end,

	["duplicate normal spin refunds 50"] = function()
		local roll = SpinRoll.roll("book", "normal", always, 0.3, 0.7)
		assert(roll ~= nil and roll.duplicate and roll.refund == 50, "repetida no normal = 50")
	end,

	["duplicate special spin refunds 150"] = function()
		local roll = SpinRoll.roll("bag", "paid", always, 0.3, 0.7)
		assert(roll ~= nil and roll.duplicate and roll.refund == 150, "repetida no especial = 150")
	end,

	["rolled item comes from the roulette list with its own rarity"] = function()
		local ids: { [string]: number } = {}
		for _, item in CosmeticCatalog.spinItems("crate") do
			ids[item.id] = item.rarity
		end
		for _, r1 in { 0, 0.25, 0.5, 0.75, 0.999 } do
			local roll = SpinRoll.roll("crate", "paid", never, r1, 0.5)
			assert(roll ~= nil and ids[roll.itemId] ~= nil, `r1={r1}: item fora da roleta da caixa`)
			assert(roll.rarity == ids[roll.itemId], `r1={r1}: raridade {roll.rarity} ~= {ids[roll.itemId]}`)
		end
	end,
}
