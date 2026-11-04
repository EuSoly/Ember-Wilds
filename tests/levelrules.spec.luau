--!strict
local LevelRules = require("../src/shared/Data/LevelRules")

local function fresh(): LevelRules.XpData
	return { Seeded = false, HourWindowStart = 0, HourEarned = 0 }
end

local function same(p: { level: number, into: number, need: number }, level: number, into: number, need: number)
	assert(
		p.level == level and p.into == into and p.need == need,
		`esperado {level}/{into}/{need}, veio {p.level}/{p.into}/{p.need}`
	)
end

return {
	["xpToReach segue +1000 por nível"] = function()
		local expected =
			{ [1] = 0, [2] = 1000, [3] = 3000, [4] = 6000, [8] = 28000, [10] = 45000, [20] = 190000, [50] = 1225000 }
		for level, xp in expected do
			assert(LevelRules.xpToReach(level) == xp, `nível {level}: {LevelRules.xpToReach(level)}`)
		end
	end,

	["progress dá o nível e a barra dentro dele"] = function()
		same(LevelRules.progress(0), 1, 0, 1000)
		same(LevelRules.progress(999), 1, 999, 1000)
		same(LevelRules.progress(1000), 2, 0, 2000)
		same(LevelRules.progress(30000), 8, 2000, 8000)
	end,

	["progress com XP inválido conta como zero"] = function()
		same(LevelRules.progress(0 / 0), 1, 0, 1000)
		same(LevelRules.progress(-5), 1, 0, 1000)
		same(LevelRules.progress(math.huge), 1, 0, 1000)
	end,

	["earn arredonda para baixo e respeita o teto por hora"] = function()
		local d = fresh()
		assert(LevelRules.earn(d, 30000.9, 100) == 30000, "primeira vida")
		assert(d.HourEarned == 30000, `HourEarned {d.HourEarned}`)
		assert(LevelRules.earn(d, 80000, 200) == 70000, "bate no teto")
		assert(LevelRules.earn(d, 5, 300) == 0, "teto cheio")
		assert(LevelRules.earn(d, 5000, 100 + 3600) == 5000, "janela nova")
	end,

	["earn com sair e voltar no mesmo minuto ainda respeita o teto"] = function()
		local d = fresh()
		assert(LevelRules.earn(d, 90000, 1000) == 90000, "primeira")
		assert(LevelRules.earn(d, 30000, 1060) == 10000, "segunda")
	end,

	["earn ignora pontos inválidos"] = function()
		local d = fresh()
		for _, bad in { 0 / 0, math.huge, -10, 0 } do
			assert(LevelRules.earn(d, bad, 100) == 0, `{bad}`)
		end
		assert(d.HourEarned == 0 and d.HourWindowStart == 0, "mudou o estado")
	end,

	["seed copia o total de pontos uma vez só"] = function()
		local d = fresh()
		local stats: { [string]: any } = { score_total = 50000 }
		assert(LevelRules.seed(d, stats) == true, "devia semear")
		assert(stats.xp_total == 50000 and d.Seeded, "semeou errado")
		stats.score_total = 90000
		assert(LevelRules.seed(d, stats) == false, "semeou de novo")
		assert(stats.xp_total == 50000, "mudou na segunda")
	end,

	["seed fica com o maior"] = function()
		local stats: { [string]: any } = { score_total = 100, xp_total = 900 }
		LevelRules.seed(fresh(), stats)
		assert(stats.xp_total == 900, `{stats.xp_total}`)
		local empty: { [string]: any } = {}
		LevelRules.seed(fresh(), empty)
		assert(empty.xp_total == 0, "sem pontos começa em 0")
	end,
}
