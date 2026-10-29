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
}

for _, stat in Stats do
	table.freeze(stat)
end

return table.freeze(Stats)
