--!strict
-- Nomes dos atributos que o servidor publica e a interface lê.
-- Quem escreve (SurvivalService na fase G1; DevStatsService no Studio por enquanto)
-- e quem lê (HUD) usam estes nomes, nunca strings soltas.
return table.freeze({
	-- Barras de status, 0 a StatusMax, atributos no Player
	Health = "Health",
	Hunger = "Hunger",
	Cold = "Cold",
	Thirst = "Thirst",

	-- Pontuação da vida atual e posição no ranking do servidor, atributos no Player
	Score = "Score",
	Rank = "Rank",

	-- true quando o jogador tem a mochila equipada (libera os slots 11–16), atributo no Player
	HasBag = "HasBag",

	-- Instante (GetServerTimeNow) em que o ciclo de dia começou, atributo no Workspace
	CycleStart = "CycleStart",

	StatusMax = 100,
	-- Abaixo desta fração a barra entra em alerta (e a vida para de regenerar)
	WarningFraction = 0.35,
})
