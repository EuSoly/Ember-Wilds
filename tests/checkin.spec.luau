--!strict
local CheckInRules = require("../src/shared/Shop/CheckInRules")
local RankRules = require("../src/shared/Data/RankRules")
local ShopConfig = require("../src/shared/Shop/ShopConfig")

local function fresh()
	return { Day = 1, LastDay = 0 }
end

return {
	["first claim gives day 1"] = function()
		local save = fresh()
		local reward = CheckInRules.claim(save, 100)
		assert(reward == ShopConfig.CHECKIN[1], "day 1 prize")
		assert(save.Day == 2 and save.LastDay == 100, "advances and records the day")
	end,
	["second claim same day is refused"] = function()
		local save = fresh()
		assert(CheckInRules.claim(save, 100) ~= nil, "claim ok")
		assert(not CheckInRules.canClaim(save, 100), "same day")
		assert(CheckInRules.claim(save, 100) == nil, "refused")
		assert(save.Day == 2 and save.LastDay == 100, "nothing changed")
	end,
	["next day gives day 2 even after a gap"] = function()
		local save = { Day = 2, LastDay = 10 }
		local reward = CheckInRules.claim(save, 15)
		assert(reward == ShopConfig.CHECKIN[2], "day 2 prize")
		assert(save.Day == 3 and save.LastDay == 15, "advances")
	end,
	["after day 7 comes day 1"] = function()
		local save = { Day = 7, LastDay = 20 }
		assert(CheckInRules.claim(save, 21) == ShopConfig.CHECKIN[7], "day 7 prize")
		assert(save.Day == 1, "wraps")
		assert(CheckInRules.claim(save, 22) == ShopConfig.CHECKIN[1], "day 1 again")
	end,
	["midnight brasilia rolls the day"] = function()
		local before = 1794193199 -- 08/11/2026 23:59:59 em Brasília
		local after = 1794193200 -- 09/11/2026 00:00:00
		local a, b = RankRules.dayIndex(before), RankRules.dayIndex(after)
		assert(a ~= b, "different days")
		local save = fresh()
		assert(CheckInRules.claim(save, a) ~= nil, "claim ok")
		assert(not CheckInRules.canClaim(save, a), "same day")
		assert(CheckInRules.canClaim(save, b), "can claim after midnight")
	end,
	["card states follow the cycle"] = function()
		-- Pronto no dia 3: 1 e 2 resgatados, 3 hoje, 4..7 futuros.
		local ready = { Day = 3, LastDay = 5 }
		local want = { "claimed", "claimed", "today", "future", "future", "future", "future" }
		for day = 1, 7 do
			assert(CheckInRules.cardState(ready, 6, day) == want[day], `ready day {day}`)
		end
		-- Já resgatou hoje (era o 3): 1..3 resgatados, o 4 trancado até amanhã.
		local done = { Day = 4, LastDay = 6 }
		local wantDone = { "claimed", "claimed", "claimed", "locked", "future", "future", "future" }
		for day = 1, 7 do
			assert(CheckInRules.cardState(done, 6, day) == wantDone[day], `done day {day}`)
		end
		-- Resgatou o 7 hoje: o 7 fica resgatado, o 1 (próximo ciclo) trancado.
		local wrapped = { Day = 1, LastDay = 6 }
		assert(CheckInRules.cardState(wrapped, 6, 7) == "claimed", "wrapped")
		assert(CheckInRules.cardState(wrapped, 6, 1) == "locked", "wrapped")
		assert(CheckInRules.cardState(wrapped, 6, 2) == "future", "wrapped")
	end,
}
