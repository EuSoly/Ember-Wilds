--!strict
-- Estatísticas permanentes do jogador (sobrevivem à morte, ficam no perfil).
-- Estatística nova = uma entrada aqui + o texto "stat.<id>" em Strings/ptBR.luau;
-- perfis antigos ganham o campo sozinhos, sem migração. Os ids vão para o
-- DataStore: nunca mude o significado de um id existente.
local Types = require("./Types")

type StatDef = Types.StatDef

local Stats: { [string]: StatDef } = {
	players_killed = { id = "players_killed", nameKey = "stat.players_killed", kind = "counter" },
	mobs_killed = { id = "mobs_killed", nameKey = "stat.mobs_killed", kind = "keyed", keyKind = "mob" },
	resources_gathered = {
		id = "resources_gathered",
		nameKey = "stat.resources_gathered",
		kind = "keyed",
		keyKind = "item",
	},
	items_crafted = { id = "items_crafted", nameKey = "stat.items_crafted", kind = "keyed", keyKind = "item" },
	-- Vidas terminadas (sair do jogo também conta).
	deaths = { id = "deaths", nameKey = "stat.deaths", kind = "counter" },
	score_total = { id = "score_total", nameKey = "stat.score_total", kind = "counter" },
	score_best = { id = "score_best", nameKey = "stat.score_best", kind = "max" },
	-- Ciclos completos (dia + noite) vividos numa vida.
	days_best = { id = "days_best", nameKey = "stat.days_best", kind = "max" },
	playtime_seconds = { id = "playtime_seconds", nameKey = "stat.playtime_seconds", kind = "counter" },
	-- XP total (pontos de cada vida, com teto por hora: LevelRules). O nível sai daqui.
	xp_total = { id = "xp_total", nameKey = "stat.xp_total", kind = "counter" },
	-- Soma dos dias (ciclos completos) de todas as vidas. Começou a contar em 04/11.
	days_total = { id = "days_total", nameKey = "stat.days_total", kind = "counter" },
	-- Só mortes de verdade (sair do jogo não conta; "deaths" conta). Começou em 04/11.
	real_deaths = { id = "real_deaths", nameKey = "stat.real_deaths", kind = "counter" },
}

for _, stat in Stats do
	table.freeze(stat)
end

return table.freeze(Stats)
