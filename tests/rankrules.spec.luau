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

	["store names use the dev prefix only in Studio"] = function()
		assert(RankRules.storeName("points", false) == "Rank_points", RankRules.storeName("points", false))
		assert(RankRules.storeName("creatures", true) == "Dev_Rank_creatures", RankRules.storeName("creatures", true))
		assert(RankRules.weekScope(2966) == "W2966", RankRules.weekScope(2966))
	end,

	["position finds the player in the top or 0"] = function()
		local top = { { UserId = 10, Value = 50 }, { UserId = 20, Value = 40 }, { UserId = 30, Value = 30 } }
		assert(RankRules.position(top, 20) == 2, "segundo")
		assert(RankRules.position(top, 99) == 0, "fora do top = 0")
		assert(RankRules.position({}, 10) == 0, "lista vazia = 0")
	end,

	["rollover keeps what the old week still owes the board"] = function()
		local old = RankRules.empty(2965)
		old.creatures = 40
		old.points = 900
		local new, owed = RankRules.rollover(old, 2966, { creatures = true })
		assert(new.Week == 2966 and new.creatures == 0, "semana nova zerada")
		assert(owed ~= nil and owed.week == 2965, "sobra da semana velha")
		assert(owed.values.creatures == 40 and owed.values.points == nil, "só as categorias que faltava gravar")
	end,

	["rollover in the same week owes nothing"] = function()
		local state = RankRules.empty(2966)
		state.xp = 10
		local same, owed = RankRules.rollover(state, 2966, { xp = true })
		assert(same.xp == 10 and owed == nil, "mesma semana: nada a dever")
		local _, nothing = RankRules.rollover(RankRules.empty(2965), 2966, nil)
		assert(nothing == nil, "sem pendência: nada a dever")
	end,

	["private servers do not count"] = function()
		assert(RankRules.counts(0), "servidor público conta")
		assert(not RankRules.counts(123456), "servidor VIP não conta")
	end,

	["requests inside the interval wait instead of being dropped"] = function()
		assert(RankRules.requestDelay(nil, 10, 0.5) == 0, "primeiro pedido: na hora")
		assert(RankRules.requestDelay(9, 10, 0.5) == 0, "fora da janela: na hora")
		local wait = RankRules.requestDelay(9.8, 10, 0.5)
		assert(math.abs(wait - 0.3) < 1e-9, `dentro da janela: espera o resto ({wait})`)
	end,

	["the player sees themself with the current value"] = function()
		local top = { { UserId = 10, Name = "A", Value = 50 }, { UserId = 20, Name = "B", Value = 5 } }
		local merged, position = RankRules.withPlayer(top, 99, "Eu", 7, 100)
		assert(position == 2, `posição {position}`)
		assert(merged[2].UserId == 99 and merged[2].Value == 7 and merged[3].UserId == 20, "entra no lugar certo")
		assert(#top == 2, "não mexe na lista do cache")
	end,

	["an old entry of the player is replaced by the current value"] = function()
		local top = { { UserId = 99, Name = "Eu", Value = 1 }, { UserId = 10, Name = "A", Value = 3 } }
		local merged, position = RankRules.withPlayer(top, 99, "Eu", 9, 100)
		assert(position == 1 and #merged == 2 and merged[2].UserId == 10, "uma linha só, com o valor novo")
	end,

	["empty board shows the player first; zero stays out"] = function()
		local merged, position = RankRules.withPlayer({}, 99, "Eu", 2, 100)
		assert(position == 1 and #merged == 1, "placar vazio: 1º")
		local none, outside = RankRules.withPlayer({ { UserId = 10, Name = "A", Value = 3 } }, 99, "Eu", 0, 100)
		assert(outside == 0 and #none == 1, "sem valor: fora da lista")
	end,

	["beyond the read size the player stays out"] = function()
		local top = {}
		for i = 1, 3 do
			top[i] = { UserId = i, Name = "x", Value = 100 - i }
		end
		local merged, position = RankRules.withPlayer(top, 99, "Eu", 1, 3)
		assert(position == 0 and #merged == 3, "abaixo do último lido: fora")
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
