--!strict
-- Conquistas: permanentes, em 3 níveis. O progresso vem das estatísticas do
-- perfil (quem já joga começa com o que tem). days_best/score_best também
-- olham a vida atual (AchievementRules). Ficaram de fora o que dá para fazer
-- AFK ou de propósito (tempo de jogo, mortes). Guerreiro não tem trava contra
-- farm entre amigos (decisão do Elizeu).
--
-- Nível com rewards vazio = "em breve": a skin exclusiva ainda não foi escolhida
-- (o Elizeu escolhe; a skin sai das roletas com inSpins = false). Pôr a skin =
-- { { kind = "cosmetic", id = "<id>" } } no nível III.
--
-- Conquista nova = uma entrada aqui + "achievement.<id>" em Strings/ptBR.luau.
local Types = require("./Types")

type AchievementDef = Types.AchievementDef
type Reward = Types.MissionReward

local function ember(amount: number): { Reward }
	return { { kind = "ember", amount = amount } }
end

local function spins(count: number): { Reward }
	return { { kind = "spins", spin = "paid", count = count } }
end

local SOON: { Reward } = {}

local function achievement(
	id: string,
	order: number,
	icon: string,
	track: Types.MissionTrack,
	targets: { number },
	rewards: { { Reward } }
): AchievementDef
	local tiers = {}
	for index, target in targets do
		local list = rewards[index]
		for _, reward in list do
			table.freeze(reward)
		end
		tiers[index] = table.freeze({ target = target, rewards = table.freeze(table.clone(list)) })
	end
	return table.freeze({
		id = id,
		order = order,
		nameKey = "achievement." .. id,
		icon = icon,
		track = table.freeze(track),
		tiers = table.freeze(tiers),
	}) :: any
end

local Achievements: { [string]: AchievementDef } = {
	woodcutter = achievement(
		"woodcutter",
		1,
		"conquista_lenhador",
		{ stat = "resources_gathered", key = "wood" },
		{ 1000, 10000, 50000 },
		{ ember(200), spins(2), SOON }
	),
	miner = achievement(
		"miner",
		2,
		"conquista_minerador",
		{ stat = "resources_gathered", key = "gold" },
		{ 300, 3000, 15000 },
		{ ember(200), spins(2), SOON }
	),
	hunter = achievement(
		"hunter",
		3,
		"conquista_cacador",
		{ stat = "mobs_killed" },
		{ 100, 1000, 5000 },
		{ ember(200), spins(2), { { kind = "kit", id = "kit_hunter" } } }
	),
	survivor = achievement(
		"survivor",
		4,
		"conquista_sobrevivente",
		{ stat = "days_best" },
		{ 5, 15, 30 },
		{ ember(200), spins(2), { { kind = "kit", id = "kit_guardian" } } }
	),
	crafter = achievement(
		"crafter",
		5,
		"conquista_artesao",
		{ stat = "items_crafted" },
		{ 100, 1000, 5000 },
		{ ember(200), spins(2), SOON }
	),
	legend = achievement(
		"legend",
		6,
		"conquista_lenda",
		{ stat = "score_best" },
		{ 50000, 200000, 1000000 },
		{ ember(300), spins(3), SOON }
	),
	warrior = achievement(
		"warrior",
		7,
		"conquista_guerreiro",
		{ stat = "players_killed" },
		{ 10, 100, 500 },
		{ ember(300), spins(2), SOON }
	),
	faithful = achievement(
		"faithful",
		8,
		"conquista_fiel",
		{ stat = "daily_sets_completed" },
		{ 7, 30, 100 },
		{ ember(200), spins(2), SOON }
	),
	chronicler = achievement(
		"chronicler",
		9,
		"conquista_cronista",
		{ stat = "chrono_completed" },
		{ 1, 10, 50 },
		{ ember(300), spins(3), spins(5) }
	),
}

return table.freeze(Achievements)
