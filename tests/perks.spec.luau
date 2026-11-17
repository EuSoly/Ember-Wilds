--!strict
local Defs = require("../src/shared/Defs")
local Perks = require("../src/shared/Shop/Perks")
local ShopData = require("../src/shared/Shop/ShopData")

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

return {
	["multiplier sums bonuses"] = function()
		local all = { vip = true, ember2x = true, book = true, premium = true }
		local none = { vip = false, ember2x = false, book = false, premium = false }
		local onlyVip = { vip = true, ember2x = false, book = false, premium = false }
		assert(near(Perks.emberMultiplier(all), 2.7), `todos: {Perks.emberMultiplier(all)}`)
		assert(Perks.emberMultiplier(none) == 1, "nenhum")
		assert(near(Perks.emberMultiplier(onlyVip), 1.5), "só VIP")
	end,

	["vip expires by date"] = function()
		local d = ShopData.empty()
		d.VipUntil = 100
		assert(Perks.resolve(d, false, 99).vip == true, "VIP vale antes do fim")
		assert(Perks.resolve(d, false, 100).vip == false, "VIP acaba no fim")
	end,

	["passes and premium resolve"] = function()
		local d = ShopData.empty()
		d.Passes.ember2x = true
		local set = Perks.resolve(d, true, 0)
		assert(set.ember2x and set.premium and not set.book and not set.vip, "conjunto")
		assert(near(Perks.emberMultiplier(set), 2.2), "2x + premium")
	end,

	["premium unlocks starter, vip unlocks vipOnly kits"] = function()
		local none = Perks.unlockedKits({ vip = false, ember2x = false, book = false, premium = false }, Defs.Kits)
		assert(next(none) == nil, "nada sem perks")
		local premium = Perks.unlockedKits({ vip = false, ember2x = false, book = false, premium = true }, Defs.Kits)
		assert(premium.kit_starter == true and premium.kit_vip == nil, "premium")
		local vip = Perks.unlockedKits({ vip = true, ember2x = false, book = false, premium = false }, Defs.Kits)
		assert(vip.kit_vip == true and vip.kit_starter == nil, "vip")
	end,
}
