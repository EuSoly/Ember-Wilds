--!strict
-- Medidas do mundo (só números: testável no Lune).
-- Centro do mapa na origem; -Z é "para cima" na tela (câmera fixa).
-- O mapa de verdade é desenhado no Studio (Workspace.Map, ver docs/guia/mapa.md);
-- sem ele, o WorldService cria um chão de teste em volta do SPAWN.

-- Retângulo visto de cima: X de minX a maxX, Z de minZ a maxZ.
export type Rect = { minX: number, minZ: number, maxX: number, maxZ: number }

local function rect(minX: number, minZ: number, maxX: number, maxZ: number): Rect
	return table.freeze({ minX = minX, minZ = minZ, maxX = maxX, maxZ = maxZ })
end

-- Quatro biomas nos cantos; o resto do quadrado (a cruz do meio e a volta) é oceano.
local BIOMES = table.freeze({
	forest = rect(-1110, 150, -150, 1110), -- canto inferior esquerdo da tela
	winter = rect(-1110, -1110, -150, -150), -- superior esquerdo
	lava = rect(150, -1110, 1110, -150), -- superior direito
	desert = rect(150, 150, 1110, 1110), -- inferior direito
})

-- Praia em volta da floresta (studs). Conta como terra: dá para andar, construir
-- e cavar areia (não plantar), os mobs da floresta entram nela e não aparece o
-- aviso de mar. Desenhada por scripts/studio/mar-em-volta.luau.
local BEACH_WIDTH = 60

local function grow(area: Rect, by: number): Rect
	return rect(area.minX - by, area.minZ - by, area.maxX + by, area.maxZ + by)
end

-- Terra firme no lançamento: a floresta mais a praia.
local LAND = grow(BIOMES.forest, BEACH_WIDTH)

return table.freeze({
	-- Lado do chão de teste em studs (só existe sem Workspace.Map), centrado no SPAWN.
	size = 256,
	-- Altura (Y) abaixo da qual o personagem conta como caído do mapa: o
	-- DeathService mata com a causa "death.cause.fall". O topo do chão é Y = 0.
	-- Fica bem acima do Workspace.FallenPartsDestroyHeight do Roblox, para a
	-- morte vir antes de o Roblox apagar a raiz do personagem.
	KILL_Y = -100,

	-- Lado do mapa inteiro (de -MAP_SIZE/2 a +MAP_SIZE/2 em X e Z):
	-- 2 × 960 de biomas + 300 da cruz do oceano. A floresta (960) leva ~1 min
	-- para atravessar a 16 studs/s (decidido pelo Elizeu em 29/10; o Starve.io
	-- leva 1 min 16 s).
	MAP_SIZE = 2220,
	BIOMES = BIOMES,
	-- Bioma aberto no lançamento (só a floresta): minimapa e nascimento.
	PLAYABLE = BIOMES.forest,
	BEACH_WIDTH = BEACH_WIDTH,
	-- Terra firme (floresta + praia): aviso de mar, pá e área dos mobs.
	LAND = LAND,
	-- Onde os mobs de cada bioma podem andar: a floresta inclui a praia (senão a
	-- praia viraria lugar seguro contra os bichos).
	MOB_AREAS = table.freeze({
		forest = LAND,
		winter = BIOMES.winter,
		lava = BIOMES.lava,
		desert = BIOMES.desert,
	}),
	-- Onde o boneco nasce e para onde a câmera do menu olha: centro da floresta.
	SPAWN = table.freeze({ x = -630, y = 0, z = 630 }),

	-- Semente do espalhador de recursos: mesmo mapa em toda partida.
	SEED = 20261029,
	-- Vão livre mínimo (studs) entre as peças sólidas de dois recursos
	-- (o corpo do boneco tem 3 de largura).
	MIN_PASSAGE = 5,

	-- Velocidade normal de andar (studs/s), a do Humanoid; a água multiplica por
	-- WATER_SPEED_FACTOR.
	WALK_SPEED = 16,
	-- Fração da velocidade normal dentro da água (Map/Water).
	WATER_SPEED_FACTOR = 0.6,
	-- Segundos na água para o fôlego ir de cheio a zero.
	OXYGEN_EMPTY_SECONDS = 30,
	-- Segundos fora da água para o fôlego encher de zero a cheio.
	OXYGEN_REFILL_SECONDS = 5,
	-- Em volta da praia é mar (Map/Water/Mar e chão Map/Ground/Ocean_*, feitos
	-- por scripts/studio/mar-em-volta.luau). As paredes invisíveis (Map/Borders)
	-- ficam a SEA_MARGIN studs da beira da praia: perto o bastante para a câmera
	-- (vê ~100 studs em volta) nunca alcançar o fim do chão de mar, que vai a 600
	-- da floresta.
	SEA_MARGIN = 150,
	-- Studs mar adentro (fora da LAND) até aparecer o aviso world.backToLand.
	SEA_WARNING_DEPTH = 4,
})
