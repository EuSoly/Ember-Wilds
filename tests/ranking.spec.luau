--!strict
local Ranking = require("../src/shared/Gather/Ranking")

return {
	["more points rank first"] = function()
		local ranks = Ranking.compute({
			{ id = 1, score = 10, order = 1 },
			{ id = 2, score = 50, order = 2 },
			{ id = 3, score = 30, order = 3 },
		})
		assert(ranks[2] == 1 and ranks[3] == 2 and ranks[1] == 3, "ordem por pontos")
	end,

	["ties go to who joined first"] = function()
		local ranks = Ranking.compute({
			{ id = 7, score = 20, order = 5 },
			{ id = 8, score = 20, order = 2 },
		})
		assert(ranks[8] == 1 and ranks[7] == 2, "empate: quem entrou antes")
	end,

	["empty list gives no ranks"] = function()
		assert(next(Ranking.compute({})) == nil, "vazio")
	end,
}
