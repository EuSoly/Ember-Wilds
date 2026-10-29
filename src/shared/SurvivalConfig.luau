--!strict
-- Números da sobrevivência (G1). Ajustar aqui muda o jogo inteiro; as regras
-- ficam em Survival/SurvivalRules. As barras vão de 0 a StatNames.StatusMax (100).
-- Valores aprovados pelo Elizeu (29/10/2026), a partir do Starve.io: veja
-- docs/guia/sobrevivencia.md.
return table.freeze({
	TICK = 0.5, -- segundos entre atualizações das barras no servidor

	HUNGER_DRAIN = 0.6, -- fome que cai por segundo (cheia → vazia em ~2 min 47 s)
	THIRST_DRAIN = 0.5, -- sede que cai por segundo (~3 min 20 s)
	COLD_DRAIN_DAY = 0.4, -- frio que cai por segundo de dia (~4 min 10 s)
	COLD_DRAIN_NIGHT = 1.6, -- frio que cai por segundo de noite (~1 min)
	WATER_COLD_FACTOR = 2, -- na água o frio cai esse tanto de vezes mais rápido
	WATER_THIRST_REFILL = 5, -- na água a sede SOBE isso por segundo
	FIRE_WARMTH = 5, -- perto do fogo o frio SOBE isso por segundo (no lugar de cair)
	CAMPFIRE_RADIUS = 12, -- studs de alcance do calor da fogueira (atributo HeatRadius)

	REGEN_MIN = 35, -- fome, frio e sede precisam estar nisso ou mais para a vida regenerar
	REGEN_RATE = 0.5, -- vida que volta por segundo

	HUNGER_EMPTY_DAMAGE = 1.5, -- vida por segundo com a fome zerada
	COLD_EMPTY_DAMAGE = 1, -- vida por segundo com o frio zerado
	THIRST_EMPTY_DAMAGE = 1, -- vida por segundo com a sede zerada
	OXYGEN_EMPTY_DAMAGE = 1, -- vida por segundo sem fôlego
	HURT_FLASH_EVERY = 2, -- segundos mínimos entre caretas do dano de sobrevivência

	EAT_INTERVAL = 0.5, -- segurando o botão de usar, come uma comida a cada isso (segundos)

	MAX_DEFENSE = 0.9, -- teto do armor.defense (fração do dano de combate cortada)
	MAX_FACTOR = 2, -- teto dos fatores de barra da armadura (coldFactor etc.)

	-- Multiplica a queda do frio por bioma. Reservado para o inverno (N2): hoje
	-- só a floresta é jogável.
	BIOME_COLD_FACTOR = table.freeze({ forest = 1 }),
})
