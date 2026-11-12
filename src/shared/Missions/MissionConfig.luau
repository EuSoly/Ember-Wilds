--!strict
-- Números das missões que não são de uma missão só (spec 2026-11-12-missoes).
local Types = require("../Defs/Types")

type Reward = Types.MissionReward

local MissionConfig = {}

-- Quantas missões cada jogador sorteia por período.
MissionConfig.DAILY_COUNT = 3
MissionConfig.WEEKLY_COUNT = 3

-- Final diária (libera com as 3 resgatadas): 1 uso de UM destes kits, sorteado
-- junto com as missões do dia.
local DAILY_FINAL: { Reward } = {
	{ kind = "kitOnce", id = "kit_explorer", count = 1 },
	{ kind = "kitOnce", id = "kit_survivor", count = 1 },
}
MissionConfig.DAILY_FINAL = DAILY_FINAL

-- Final semanal: todos estes juntos.
local WEEKLY_FINAL: { Reward } = {
	{ kind = "spins", spin = "paid", count = 1 },
	{ kind = "kitOnce", id = "kit_veteran", count = 1 },
}
MissionConfig.WEEKLY_FINAL = WEEKLY_FINAL

-- Intervalo mínimo entre dois pedidos de resgate do mesmo jogador (segundos).
MissionConfig.CLAIM_COOLDOWN = 0.3

-- Conquistas de "uma vida só": a estatística guarda a melhor vida terminada, e a
-- vida atual também conta (AchievementRules).
local LIFE_OF_STAT: { [string]: "days" | "score" } = {
	days_best = "days",
	score_best = "score",
}
MissionConfig.LIFE_OF_STAT = LIFE_OF_STAT

for _, list in { DAILY_FINAL, WEEKLY_FINAL } do
	for _, reward in list do
		table.freeze(reward)
	end
	table.freeze(list)
end
table.freeze(LIFE_OF_STAT)

return table.freeze(MissionConfig)
