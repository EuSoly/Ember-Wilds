--!strict
-- Números do ranking semanal (UI 6) num lugar só. Ver
-- docs/superpowers/specs/2026-11-09-ranking-semanal-design.md.
return table.freeze({
	-- Abas, na ordem da tela (o índice 1..5 viaja na rede).
	CATEGORIES = table.freeze({ "points", "xp", "days", "players", "creatures" }),
	-- "max" = melhor vida da semana; "sum" = soma da semana.
	KIND = table.freeze({ points = "max", xp = "sum", days = "max", players = "sum", creatures = "sum" }),

	-- Semana de Brasília (UTC−3, sem horário de verão): termina domingo 23:59:59
	-- e a seguinte começa segunda 00:00 (decisão do Elizeu, 09/11).
	UTC_OFFSET = -3 * 3600,
	FIRST_MONDAY = 345600, -- 1970-01-05 00:00 UTC, a primeira segunda depois do 0 do unix
	WEEK_SECONDS = 604800,
	DAY_SECONDS = 86400,

	LIST_SIZE = 50, -- linhas da lista na tela
	READ_SIZE = 100, -- quantos o servidor lê (posição própria só até aqui; depois "100+")
	CACHE_SECONDS = 180, -- quanto tempo o top de cada categoria fica em cache no servidor
	WRITE_MIN_INTERVAL = 60, -- segundos entre gravações do mesmo jogador no placar
	REQUEST_MIN_INTERVAL = 0.5, -- segundos entre pedidos do mesmo cliente

	-- Abates do mesmo jogador por dia que contam no ranking (0 = sem limite).
	-- Desligado por enquanto: pouca gente jogando (Elizeu, 09/11).
	SAME_VICTIM_DAILY_LIMIT = 0,

	-- Nome dos DataStores ordenados: STORE_PREFIX .. categoria, escopo "W" .. semana.
	-- No Studio ganha o DataConfig.DEV_STORE_PREFIX na frente.
	STORE_PREFIX = "Rank_",
})
