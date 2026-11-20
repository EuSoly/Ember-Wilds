--!strict
local BotNames = require("../src/shared/Bots/BotNames")
local BotRules = require("../src/shared/Bots/BotRules")
local Rng = require("../src/shared/World/Rng")

local function eq(got: any, want: any, label: string)
	assert(got == want, `{label}: esperava {want}, veio {got}`)
end

return {
	["target: 20 minus players, 0 to 10, capped by server size"] = function()
		eq(BotRules.target(0, 30), 10, "vazio")
		eq(BotRules.target(10, 30), 10, "10 jogadores")
		eq(BotRules.target(11, 30), 9, "11 jogadores")
		eq(BotRules.target(15, 30), 5, "15 jogadores")
		eq(BotRules.target(20, 30), 0, "20 jogadores")
		eq(BotRules.target(25, 30), 0, "25 jogadores")
		eq(BotRules.target(3, 12), 9, "servidor de 12 vagas")
		eq(BotRules.target(12, 12), 0, "servidor de 12 cheio")
	end,

	["populationStep: one change per round"] = function()
		eq(BotRules.populationStep(10, 9), -1, "sobra")
		eq(BotRules.populationStep(7, 10), 1, "falta")
		eq(BotRules.populationStep(5, 5), 0, "certo")
	end,

	["addScore: respects the cap and ignores bad points"] = function()
		eq(BotRules.addScore(2990, 50), BotRules.BOT_SCORE_CAP, "passa do teto")
		eq(BotRules.addScore(BotRules.BOT_SCORE_CAP, 10), BotRules.BOT_SCORE_CAP, "no teto")
		eq(BotRules.addScore(0, 5), 5, "normal")
		eq(BotRules.addScore(10, -3), 10, "negativo")
		eq(BotRules.addScore(10, 0 / 0), 10, "NaN")
		eq(BotRules.BOT_SCORE_CAP, 3000, "teto")
	end,

	["provoked: two hits from the same attacker within the window"] = function()
		local a, b = {}, {}
		local s: BotRules.Provoke = {}
		BotRules.recordHit(s, a, 100)
		assert(not BotRules.provoked(s, a, 100), "um golpe não provoca")
		BotRules.recordHit(s, a, 103)
		assert(BotRules.provoked(s, a, 103), "dois golpes em 3 s provocam")

		local late: BotRules.Provoke = {}
		BotRules.recordHit(late, a, 100)
		BotRules.recordHit(late, a, 105)
		assert(not BotRules.provoked(late, a, 105), "dois golpes em 5 s não provocam")

		local mixed: BotRules.Provoke = {}
		BotRules.recordHit(mixed, a, 100)
		BotRules.recordHit(mixed, b, 101)
		assert(not BotRules.provoked(mixed, a, 101), "atacantes diferentes não somam")
		assert(not BotRules.provoked(mixed, b, 101), "atacantes diferentes não somam (b)")
	end,

	["aimed: a hit counts only when no resource is nearer to the swing than the bot"] = function()
		assert(BotRules.aimedAtBot(1.5, nil), "nada em volta: mirou no bot")
		assert(BotRules.aimedAtBot(1.5, 3), "bot mais perto do golpe que a árvore")
		assert(not BotRules.aimedAtBot(2.5, 0.5), "árvore mais perto: golpe era na árvore")
	end,

	["names: Roblox style, never repeated"] = function()
		local rng = Rng.new(7)
		local function nextNumber(): number
			return rng:nextNumber()
		end
		local taken: { [string]: boolean } = {}
		for _ = 1, 50 do
			local name = BotNames.pick(nextNumber, taken)
			assert(string.match(name, "^[%w_]+$") ~= nil, `nome com caractere estranho: {name}`)
			assert(#name >= 3 and #name <= 20, `tamanho: {name}`)
			assert(not taken[name], `repetido: {name}`)
			taken[name] = true
		end
	end,
}
