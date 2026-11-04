--!strict
local StatsRules = require("../src/shared/Data/StatsRules")

-- Defs falsas de cada kind (as reais podem mudar sem quebrar estes testes).
local deaths: any = { id = "deaths", nameKey = "stat.deaths", kind = "counter" }
local mobsKilled: any = { id = "mobs_killed", nameKey = "stat.mobs_killed", kind = "keyed", keyKind = "mob" }
local scoreBest: any = { id = "score_best", nameKey = "stat.score_best", kind = "max" }

return {
	["counter adds"] = function()
		local stats = {}
		assert(StatsRules.add(stats, deaths, 1) == 1, "primeira soma")
		assert(StatsRules.add(stats, deaths, 2) == 3, "segunda soma")
		assert(StatsRules.get(stats, deaths) == 3, `valor {StatsRules.get(stats, deaths)}`)
	end,

	["counter accepts fractions"] = function()
		local stats = {}
		assert(StatsRules.add(stats, deaths, 1.5) == 1.5, "fração aceita (segundos)")
	end,

	["keyed creates the table and adds per key"] = function()
		local stats: { [string]: any } = {}
		assert(StatsRules.add(stats, mobsKilled, 10, "cow") == 10, "vacas")
		assert(StatsRules.add(stats, mobsKilled, 11, "spider") == 11, "aranhas")
		assert(type(stats.mobs_killed) == "table", "tabela criada na primeira soma")
		assert(StatsRules.get(stats, mobsKilled, "cow") == 10, "get vacas")
		assert(StatsRules.get(stats, mobsKilled, "spider") == 11, "get aranhas")
		assert(StatsRules.get(stats, mobsKilled, "wolf") == 0, "chave sem valor = 0")
	end,

	["keyed needs a valid key"] = function()
		local stats: { [string]: any } = {}
		assert(StatsRules.add(stats, mobsKilled, 1) == nil, "sem chave")
		assert(StatsRules.add(stats, mobsKilled, 1, "Cow!") == nil, "chave inválida")
		assert(StatsRules.add(stats, mobsKilled, 1, string.rep("a", 33)) == nil, "chave longa demais")
		assert(stats.mobs_killed == nil, "nada mudou")
	end,

	["key validation"] = function()
		assert(StatsRules.isValidKey("cow") == true, "cow")
		assert(StatsRules.isValidKey(string.rep("a", 32)) == true, "32 caracteres")
		assert(StatsRules.isValidKey(string.rep("a", 33)) == false, "33 caracteres")
		assert(StatsRules.isValidKey("") == false, "vazia")
		assert(StatsRules.isValidKey("Cow") == false, "maiúscula")
	end,

	["counter rejects a key"] = function()
		local stats: { [string]: any } = {}
		assert(StatsRules.add(stats, deaths, 1, "cow") == nil, "counter com chave")
		assert(stats.deaths == nil, "nada mudou")
	end,

	["invalid amounts are rejected"] = function()
		local stats: { [string]: any } = {}
		assert(StatsRules.add(stats, deaths, 0) == nil, "zero")
		assert(StatsRules.add(stats, deaths, -1) == nil, "negativo")
		assert(StatsRules.add(stats, deaths, 0 / 0) == nil, "NaN")
		assert(StatsRules.add(stats, deaths, math.huge) == nil, "infinito")
		assert(stats.deaths == nil, "nada mudou")
	end,

	["add rejects max stats"] = function()
		local stats: { [string]: any } = {}
		assert(StatsRules.add(stats, scoreBest, 5) == nil, "add em max")
	end,

	["record keeps the highest"] = function()
		local stats: { [string]: any } = {}
		local value, changed = StatsRules.record(stats, scoreBest, 5)
		assert(value == 5 and changed == true, "record(5)")
		value, changed = StatsRules.record(stats, scoreBest, 3)
		assert(value == 5 and changed == false, "record(3) mantém 5")
		assert(StatsRules.get(stats, scoreBest) == 5, "get")
	end,

	["record rejects invalid values and other kinds"] = function()
		local stats: { [string]: any } = {}
		local value, changed = StatsRules.record(stats, deaths, 5)
		assert(value == nil and changed == false, "record em counter")
		value, changed = StatsRules.record(stats, scoreBest, -1)
		assert(value == nil and changed == false, "negativo")
		value, changed = StatsRules.record(stats, scoreBest, 0 / 0)
		assert(value == nil and changed == false, "NaN")
		assert(stats.score_best == nil and stats.deaths == nil, "nada mudou")
	end,

	["record zero on an empty stat"] = function()
		local stats: { [string]: any } = {}
		local value, changed = StatsRules.record(stats, scoreBest, 0)
		assert(value == 0 and changed == false, "0 numa estatística vazia não muda nada")
	end,

	["total of counter and max is the value"] = function()
		assert(StatsRules.total({ deaths = 5 }, deaths) == 5, "counter")
		assert(StatsRules.total({ score_best = 12 }, scoreBest) == 12, "max")
		assert(StatsRules.total({}, deaths) == 0, "vazio")
	end,

	["total of keyed sums every key"] = function()
		assert(StatsRules.total({ mobs_killed = { wolf = 3, bear = 2 } }, mobsKilled) == 5, "soma")
		assert(StatsRules.total({}, mobsKilled) == 0, "ausente")
		assert(
			StatsRules.total({ mobs_killed = { wolf = 3, bad = "x" } } :: any, mobsKilled) == 3,
			"ignora não-número"
		)
	end,
}
