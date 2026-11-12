--!strict
-- Diárias e semanais: banco de onde cada jogador sorteia as suas (MissionConfig
-- diz quantas). O progresso vem das estatísticas (Defs/Stats) ou da vida atual
-- (track.life). Prêmios = recompensas da loja (ShopService.give), fora do teto
-- de Golden Ember por hora.
--
-- Missão nova = uma entrada aqui + "mission.<id>" em Strings/ptBR.luau ({n} = alvo).
-- "Comer" e "construir" ficam de fora até existir estatística para elas.
local Types = require("./Types")

type MissionDef = Types.MissionDef

local function mission(
	id: string,
	period: "daily" | "weekly",
	icon: string,
	track: Types.MissionTrack,
	target: number,
	ember: number
): MissionDef
	return table.freeze({
		id = id,
		period = period,
		nameKey = "mission." .. id,
		icon = icon,
		track = table.freeze(track),
		target = target,
		rewards = table.freeze({ table.freeze({ kind = "ember", amount = ember }) }),
	}) :: any
end

local function gathered(item: string): Types.MissionTrack
	return { stat = "resources_gathered", key = item }
end

local function killed(mob: string?): Types.MissionTrack
	return { stat = "mobs_killed", key = mob }
end

local Missions: { [string]: MissionDef } = {
	daily_wood = mission("daily_wood", "daily", "conquista_lenhador", gathered("wood"), 200, 40),
	daily_stone = mission("daily_stone", "daily", "conquista_lenhador", gathered("stone"), 150, 40),
	daily_gold = mission("daily_gold", "daily", "conquista_minerador", gathered("gold"), 30, 60),
	daily_berry = mission("daily_berry", "daily", "aba_diarias", gathered("berry"), 40, 30),
	daily_mobs = mission("daily_mobs", "daily", "conquista_cacador", killed(nil), 10, 50),
	daily_wolf = mission("daily_wolf", "daily", "conquista_cacador", killed("wolf"), 3, 60),
	daily_rabbit = mission("daily_rabbit", "daily", "conquista_cacador", killed("rabbit"), 5, 30),
	daily_craft = mission("daily_craft", "daily", "conquista_artesao", { stat = "items_crafted" }, 10, 40),
	daily_days = mission("daily_days", "daily", "conquista_sobrevivente", { life = "days" }, 2, 60),
	daily_score = mission("daily_score", "daily", "conquista_lenda", { life = "score" }, 5000, 50),

	weekly_wood = mission("weekly_wood", "weekly", "conquista_lenhador", gathered("wood"), 3000, 200),
	weekly_gold = mission("weekly_gold", "weekly", "conquista_minerador", gathered("gold"), 300, 250),
	weekly_mobs = mission("weekly_mobs", "weekly", "conquista_cacador", killed(nil), 100, 200),
	weekly_wolf = mission("weekly_wolf", "weekly", "conquista_cacador", killed("wolf"), 25, 250),
	weekly_craft = mission("weekly_craft", "weekly", "conquista_artesao", { stat = "items_crafted" }, 80, 150),
	weekly_days = mission("weekly_days", "weekly", "conquista_sobrevivente", { life = "days" }, 5, 300),
	weekly_score = mission("weekly_score", "weekly", "conquista_lenda", { life = "score" }, 30000, 250),
	weekly_players = mission("weekly_players", "weekly", "conquista_guerreiro", { stat = "players_killed" }, 5, 200),
}

return table.freeze(Missions)
