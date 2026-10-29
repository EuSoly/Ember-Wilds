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
	-- Área jogável no lançamento (só a floresta); a borda tem paredes (Map/Borders).
	PLAYABLE = BIOMES.forest,
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
	-- A essa distância (studs) da borda da área jogável aparece o aviso world.locked.
	BORDER_WARNING_DISTANCE = 12,
})
