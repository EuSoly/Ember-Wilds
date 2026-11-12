--!strict
-- Chrono quests: missões da vida atual, com prazo em dias de jogo (1 dia =
-- DataConfig.DAY_CYCLE_SECONDS). Números da config oficial do Starve
-- (docs/game-design/quests-starve.md). Só Sobreviver e Mãos Limpas (a "peace"
-- do Starve) existem no lançamento: as outras dependem de biomas e mobs que
-- ainda não temos e ficam escritas, desligadas (enabled = false). Ligar uma =
-- trocar enabled e ter o motor do objetivo dela (QuestService).
--
-- Quest nova = uma entrada aqui + "quest.<id>.name"/".desc" em Strings/ptBR.luau.
local Types = require("./Types")

type QuestDef = Types.QuestDef

local function quest(id: string, fields: { [string]: any }): QuestDef
	local def: any = {
		id = id,
		nameKey = `quest.{id}.name`,
		descKey = `quest.{id}.desc`,
		icon = "aba_partida",
		enabled = false,
		goals = {},
		rules = {},
		rewardCount = 1,
	}
	for key, value in fields do
		def[key] = value
	end
	return def
end

local ALONE = { type = "alone" }

local Quests: { [string]: QuestDef } = {
	survive = quest("survive", {
		enabled = true,
		icon = "chrono_sobreviver",
		days = 4,
		ends = "time",
		rules = { ALONE, { type = "unhurt" } },
		rewardItem = "green_gem",
		score = 7500,
	}),
	clean_hands = quest("clean_hands", {
		enabled = true,
		icon = "chrono_maos_limpas",
		days = 6,
		ends = "time",
		rules = { { type = "peaceful" } },
		rewardItem = "blue_gem",
		score = 3000,
	}),
	-- Desligadas (biomas e mobs futuros).
	dragon = quest("dragon", {
		days = 6,
		ends = "goals",
		goals = { { type = "have", item = "dragon_heart", amount = 1, biomes = { "winter", "dragon" } } },
		rules = { ALONE },
		rewardItem = "dragon_orb",
		score = 7500,
	}),
	amethyst = quest("amethyst", {
		days = 3,
		ends = "goals",
		goals = { { type = "have", item = "amethyst", amount = 1 } },
		rules = { ALONE, { type = "mined", items = { "amethyst" } } },
		rewardItem = "blue_cube",
		score = 7500,
	}),
	luck = quest("luck", {
		days = 3,
		ends = "goals",
		goals = { { type = "open", item = "treasure", amount = 5 } },
		rewardItem = "orange_gem",
		score = 3000,
	}),
	farmer = quest("farmer", {
		days = 5,
		ends = "goals",
		goals = {
			{ type = "farm", item = "wild_wheat", amount = 100 },
			{ type = "farm", item = "flour", amount = 100 },
			{ type = "farm", item = "bread", amount = 100 },
		},
		rules = { ALONE, { type = "stay", biomes = { "winter", "dragon" } } },
		rewardItem = "white_wolf_fur",
		score = 3000,
	}),
	hood = quest("hood", {
		days = 5,
		ends = "time",
		rules = { ALONE, { type = "stay", biomes = { "winter", "dragon" } } },
		rewardItem = "black_wolf_fur",
		score = 3000,
	}),
	lava = quest("lava", {
		days = 10,
		ends = "goals",
		goals = { { type = "have", item = "lava_heart", amount = 1, biomes = { "lava" } } },
		rules = { ALONE },
		rewardItem = "lava_orb",
		score = 10000,
	}),
	reidite = quest("reidite", {
		days = 6,
		ends = "goals",
		goals = { { type = "have", item = "reidite", amount = 1 } },
		rules = { ALONE, { type = "mined", items = { "reidite" } } },
		rewardItem = "lava_cube",
		score = 7500,
	}),
	farmer_desert = quest("farmer_desert", {
		days = 7,
		ends = "goals",
		goals = {
			{ type = "farm", item = "wild_wheat", amount = 100 },
			{ type = "farm", item = "flour", amount = 100 },
			{ type = "farm", item = "bread", amount = 100 },
		},
		rules = { ALONE, { type = "stay", biomes = { "desert" } } },
		rewardItem = "pitchfork_part",
		score = 6000,
	}),
	emerald = quest("emerald", {
		days = 6,
		ends = "goals",
		goals = { { type = "have", item = "emerald", amount = 1 } },
		rules = { ALONE, { type = "mined", items = { "emerald" } } },
		rewardItem = "pilot_glasses",
		score = 7500,
	}),
	-- Prêmio = +1 slot de mochila (entra quando o deserto existir).
	sandworm = quest("sandworm", {
		days = 8,
		ends = "goals",
		goals = { { type = "have", item = "sandworm_juice", amount = 1, biomes = { "desert" } } },
		rules = { ALONE },
		rewardItem = "",
		rewardCount = 0,
		score = 10000,
	}),
	explorer = quest("explorer", {
		days = 7,
		ends = "goals",
		goals = {
			{ type = "spend", biomes = { "forest" }, amount = 1 },
			{ type = "spend", biomes = { "winter", "dragon" }, amount = 1 },
			{ type = "spend", biomes = { "desert" }, amount = 1 },
			{ type = "spend", biomes = { "lava" }, amount = 1 },
		},
		rules = { ALONE },
		rewardItem = "",
		rewardCount = 0,
		score = 10000,
	}),
}

for _, def in Quests do
	for _, rule in def.rules do
		if not table.isfrozen(rule) then -- ALONE é a mesma tabela em várias quests
			table.freeze(rule)
		end
	end
	table.freeze(def.rules)
	table.freeze(def.goals)
	table.freeze(def)
end

return table.freeze(Quests)
