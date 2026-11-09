--!strict
local Defs = require("../src/shared/Defs")
local ProfileTemplate = require("../src/shared/Data/ProfileTemplate")
local RankRules = require("../src/shared/Data/RankRules")

-- Instantes reais (unix) em Brasília, UTC−3.
local SUN_08_2359 = 1794193199 -- domingo 08/11/2026 23:59:59
local MON_09_0000 = 1794193200 -- segunda 09/11/2026 00:00:00
local SUN_15_2359 = 1794797999 -- domingo 15/11/2026 23:59:59
local MON_16_0000 = 1794798000 -- segunda 16/11/2026 00:00:00

local function sameList(got: { string }, expected: { string })
	table.sort(got)
	table.sort(expected)
	assert(
		table.concat(got, ",") == table.concat(expected, ","),
		`esperado {table.concat(expected, ",")}, veio {table.concat(got, ",")}`
	)
end

return {
	["profile template has the week state"] = function()
		local ranking = ProfileTemplate.build(Defs :: any).Ranking
		assert(type(ranking) == "table", "perfil sem Ranking")
		for _, category in { "points", "xp", "days", "players", "creatures" } do
			assert(ranking[category] == 0, `{category} deveria começar em 0`)
		end
	end,

	["week turns on monday 00:00 in Brasilia"] = function()
		assert(RankRules.weekIndex(SUN_08_2359) == 2965, `domingo: {RankRules.weekIndex(SUN_08_2359)}`)
		assert(RankRules.weekIndex(MON_09_0000) == 2966, `segunda: {RankRules.weekIndex(MON_09_0000)}`)
		assert(RankRules.weekIndex(SUN_15_2359) == 2966, "domingo seguinte ainda é a mesma semana")
		assert(RankRules.weekIndex(MON_16_0000) == 2967, "segunda seguinte vira")
	end,

	["week ends sunday 23:59:59"] = function()
		assert(RankRules.weekEnd(2966) == SUN_15_2359, `fim: {RankRules.weekEnd(2966)}`)
	end,

	["day index turns at local midnight"] = function()
		assert(
			RankRules.dayIndex(SUN_08_2359) + 1 == RankRules.dayIndex(MON_09_0000),
			"meia-noite de Brasília vira o dia"
		)
	end,

	["current keeps this week and resets old or broken state"] = function()
		local empty = RankRules.current(nil, 2966)
		assert(empty.Week == 2966 and empty.points == 0 and empty.creatures == 0, "nil vira semana vazia")
		local old = RankRules.current({ Week = 2965, points = 9 }, 2966)
		assert(old.Week == 2966 and old.points == 0, "semana velha zera")
		local mine = RankRules.empty(2966)
		mine.points = 5
		assert(RankRules.current(mine, 2966).points == 5, "semana atual fica")
		assert(RankRules.current({ Week = 2966, points = "x" }, 2966).points == 0, "campo quebrado zera")
	end,

	["life keeps best points and days and sums xp"] = function()
		local s = RankRules.empty(2966)
		sameList(RankRules.applyLife(s, { points = 100, days = 2, xp = 30 }), { "points", "days", "xp" })
		sameList(RankRules.applyLife(s, { points = 40, days = 1, xp = 20 }), { "xp" })
		assert(s.points == 100 and s.days == 2 and s.xp == 50, `{s.points}/{s.days}/{s.xp}`)
		sameList(RankRules.applyLife(s, { points = 0, days = 0, xp = 0 }), {})
	end,

	["kills count without limit when limit is 0"] = function()
		local s = RankRules.empty(2966)
		for _ = 1, 5 do
			assert(RankRules.applyKill(s, "players", "42", 100, 0), "sem limite conta sempre")
		end
		assert(s.players == 5, `players {s.players}`)
	end,

	["same victim counts up to the limit per day"] = function()
		local s = RankRules.empty(2966)
		local counted = 0
		for _ = 1, 4 do
			if RankRules.applyKill(s, "players", "42", 100, 3) then
				counted += 1
			end
		end
		assert(counted == 3 and s.players == 3, `contou {counted}`)
		assert(RankRules.applyKill(s, "players", "7", 100, 3), "outra vítima conta")
		assert(RankRules.applyKill(s, "players", "42", 101, 3), "no dia seguinte volta a contar")
		assert(s.players == 5, `players {s.players}`)
	end,

	["creatures ignore the victim limit"] = function()
		local s = RankRules.empty(2966)
		for _ = 1, 5 do
			RankRules.applyKill(s, "creatures", nil, 100, 3)
		end
		assert(s.creatures == 5, `creatures {s.creatures}`)
	end,

	["countdown picks the right unit"] = function()
		local key, args = RankRules.countdown(3 * 86400 + 5 * 3600 + 10)
		assert(key == "rank.ends.days" and args.d == 3 and args.h == 5, `{key} {args.d} {args.h}`)
		key, args = RankRules.countdown(2 * 3600 + 7 * 60)
		assert(key == "rank.ends.hours" and args.h == 2 and args.m == 7, `{key}`)
		key, args = RankRules.countdown(125)
		assert(key == "rank.ends.minutes" and args.m == 2, `{key}`)
		key = RankRules.countdown(59)
		assert(key == "rank.ends.soon", key)
	end,
}
