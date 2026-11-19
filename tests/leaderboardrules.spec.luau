--!strict
local LeaderboardRules = require("../src/shared/UIFlow/LeaderboardRules")

return {
	["12 jogadores cortam em 10 e o local em 12º entra como 11ª linha"] = function()
		local entries = {}
		for i = 1, 12 do
			table.insert(entries, {
				name = string.format("P%02d", i),
				score = (13 - i) * 100,
				userId = i,
			})
		end
		-- Jogador local em 3º (dentro do limite 10): 10 linhas.
		local topIn = LeaderboardRules.top(entries, 10, 3)
		assert(#topIn == 10, `esperava 10 linhas, veio {#topIn}`)
		assert(topIn[1].rank == 1 and topIn[1].name == "P01" and topIn[1].score == 1200 and not topIn[1].isMe, "#1")
		assert(topIn[3].rank == 3 and topIn[3].isMe == true, "#3 é o local")
		assert(topIn[10].rank == 10 and topIn[10].name == "P10", "#10")

		-- Jogador local em 12º (fora do limite 10): 11 linhas, com rank real 12 no fim.
		local topOut = LeaderboardRules.top(entries, 10, 12)
		assert(#topOut == 11, `esperava 11 linhas, veio {#topOut}`)
		local last = topOut[11]
		assert(last.rank == 12 and last.name == "P12" and last.score == 100 and last.isMe == true, "11ª linha = #12")
	end,

	["empate ordena por nome"] = function()
		local entries = {
			{ name = "Carlos", score = 500, userId = 1 },
			{ name = "Ana", score = 500, userId = 2 },
			{ name = "Bruno", score = 500, userId = 3 },
		}
		local top = LeaderboardRules.top(entries, 10, 3)
		assert(#top == 3, "3 linhas")
		assert(top[1].name == "Ana" and top[1].rank == 1, "Ana #1")
		assert(top[2].name == "Bruno" and top[2].rank == 2 and top[2].isMe, "Bruno #2 (me)")
		assert(top[3].name == "Carlos" and top[3].rank == 3, "Carlos #3")
	end,

	["lista vazia devolve vazia"] = function()
		local top = LeaderboardRules.top({}, 10, 1)
		assert(#top == 0, "vazia")
	end,

	["pódio: só os 3 primeiros, sem acrescentar o local"] = function()
		local entries = {}
		for i = 1, 6 do
			table.insert(entries, { name = string.format("P%02d", i), score = (7 - i) * 10, userId = i })
		end
		local fora = LeaderboardRules.podium(entries, 5)
		assert(#fora == 3, `esperava 3 linhas, veio {#fora}`)
		assert(fora[1].rank == 1 and fora[3].rank == 3, "ranks 1 a 3")
		for _, row in fora do
			assert(not row.isMe, "o local (5º) não entra no pódio")
		end
		local dentro = LeaderboardRules.podium(entries, 2)
		assert(#dentro == 3 and dentro[2].isMe, "o local em 2º aparece marcado")
		assert(#LeaderboardRules.podium({ { name = "Só", score = 0, userId = 9 } }, 9) == 1, "1 jogador: 1 linha")
	end,
}
