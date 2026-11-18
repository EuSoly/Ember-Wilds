--!strict
local RewardBadge = require("../src/shared/Shop/RewardBadge")
local ShopConfig = require("../src/shared/Shop/ShopConfig")

return {
	["every check-in day has an icon and an amount"] = function()
		for day, reward in ShopConfig.CHECKIN do
			local badge = RewardBadge.of(reward)
			assert(badge.icon ~= nil, `dia {day}: sem ícone ({reward.kind})`)
			assert(badge.amount ~= "" and string.find(badge.amount, "[", 1, true) == nil, `dia {day}: quantidade`)
			assert(badge.label ~= "" and string.find(badge.label, "[", 1, true) == nil, `dia {day}: nome do prêmio`)
			if badge.icon == "kit" then
				assert(badge.kitId ~= nil, `dia {day}: kit sem id`)
			end
		end
	end,

	["ember, spins and kit lives read short"] = function()
		assert(RewardBadge.of({ kind = "ember", amount = 1500 }).amount == "1.500", "milhar")
		local paid = RewardBadge.of({ kind = "spins", spin = "paid", count = 5 })
		assert(paid.icon == "spinPaid" and paid.amount == "×5", `giro especial: {paid.amount}`)
		local normal = RewardBadge.of({ kind = "spins", spin = "normal", count = 2 })
		assert(normal.icon == "spinNormal" and normal.amount == "×2", "giro normal")
		local kit = RewardBadge.of({ kind = "kitOnce", id = "kit_explorer", count = 1 })
		assert(kit.icon == "kit" and kit.kitId == "kit_explorer" and kit.amount == "1 vida", "kit 1 vida")
		assert(RewardBadge.of({ kind = "kitOnce", id = "kit_explorer", count = 3 }).amount == "3 vidas", "vidas")
	end,

	["each reward says what it is"] = function()
		assert(RewardBadge.of({ kind = "ember", amount = 150 }).label == "Golden Ember", "moeda")
		assert(RewardBadge.of({ kind = "spins", spin = "normal", count = 1 }).label == "Giro", "1 giro")
		assert(RewardBadge.of({ kind = "spins", spin = "normal", count = 2 }).label == "Giros", "giros")
		assert(RewardBadge.of({ kind = "spins", spin = "paid", count = 5 }).label == "Giros especiais", "especiais")
		local kit = RewardBadge.of({ kind = "kitOnce", id = "kit_explorer", count = 1 })
		assert(kit.label == "Kit Explorador", `kit: {kit.label}`)
	end,

	["unknown rewards fall back to the full text"] = function()
		assert(RewardBadge.of({ kind = "vip", count = 30 }).icon == nil, "sem ícone")
	end,
}
