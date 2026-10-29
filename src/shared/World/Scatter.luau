--!strict
-- Espalhador de recursos do mapa (puro: testável no Lune).
-- Para cada zona, sorteia pontos com semente fixa (seed + índice da zona) e
-- aceita o ponto se ele está dentro da zona, longe dos bloqueadores (água e
-- NoSpawn) e com folga de todo recurso já colocado. Mesmos dados + mesma
-- semente = mesmas posições, em toda partida.
-- O sorteio usa o Rng (mulberry32) em vez do Random do Roblox, que não existe
-- no Lune: assim o teste roda a mesma conta que o servidor.
local Rng = require("./Rng")
local Shapes = require("./Shapes")
local Types = require("../Defs/Types")

type ResourceDef = Types.ResourceDef

export type Zone = { shape: Shapes.Shape, densities: { [string]: number } }
export type Placement = { resourceId: string, x: number, z: number, variant: number, yaw: number }
export type Params = {
	zones: { Zone },
	blockers: { Shapes.Shape }, -- água + NoSpawn
	fixed: { Placement }, -- recursos colocados à mão (entram primeiro e ocupam espaço)
	resources: { [string]: ResourceDef },
	seed: number,
	minPassage: number,
	maxAttemptsPerItem: number?, -- padrão 30
}

local DEFAULT_MAX_ATTEMPTS = 30
-- Lado da célula da grade espacial (studs): cada ponto só é comparado com os
-- recursos das células vizinhas, em vez de com todos.
local CELL_SIZE = 16
-- Área (studs²) em que a densidade é contada: densidade 4 = 4 a cada 100×100.
local DENSITY_AREA = 10000

local Scatter = {}

type Placed = { x: number, z: number, def: ResourceDef }
type Grid = { [number]: { [number]: { Placed } } }

local function cellOf(value: number): number
	return math.floor(value / CELL_SIZE)
end

local function addToGrid(grid: Grid, placed: Placed)
	local cx, cz = cellOf(placed.x), cellOf(placed.z)
	local column = grid[cx]
	if column == nil then
		column = {}
		grid[cx] = column
	end
	local cell = column[cz]
	if cell == nil then
		cell = {}
		column[cz] = cell
	end
	table.insert(cell, placed)
end

-- Distância mínima entre os centros de dois recursos: um não invade o espaço
-- do outro (radius) e entre as peças de colisão sobra um vão para passar.
local function minDistance(a: ResourceDef, b: ResourceDef, minPassage: number): number
	return math.max(a.radius, b.radius, a.collisionRadius + b.collisionRadius + minPassage)
end

local function hasRoom(grid: Grid, reach: number, x: number, z: number, def: ResourceDef, minPassage: number): boolean
	local cx, cz = cellOf(x), cellOf(z)
	for ix = cx - reach, cx + reach do
		local column = grid[ix]
		if column == nil then
			continue
		end
		for iz = cz - reach, cz + reach do
			local cell = column[iz]
			if cell == nil then
				continue
			end
			for _, other in cell do
				local need = minDistance(def, other.def, minPassage)
				local dx, dz = x - other.x, z - other.z
				if dx * dx + dz * dz < need * need then
					return false
				end
			end
		end
	end
	return true
end

-- O centro precisa ficar a pelo menos `radius` da borda de todo bloqueador
-- (distância exata, não aproximada por pontos de teste).
local function clearOfBlockers(blockers: { Shapes.Shape }, x: number, z: number, radius: number): boolean
	for _, blocker in blockers do
		if Shapes.distanceOutside(blocker, x, z) < radius then
			return false
		end
	end
	return true
end

-- Ordem dos recursos dentro de uma zona: maiores primeiro (os pequenos cabem
-- nos vãos), depois por id. A ordem das chaves de uma tabela não é garantida,
-- e o resultado precisa ser sempre o mesmo.
local function sortedResourceIds(densities: { [string]: number }, resources: { [string]: ResourceDef }): { string }
	local ids: { string } = {}
	for id in densities do
		if resources[id] ~= nil then
			table.insert(ids, id)
		end
	end
	table.sort(ids, function(a, b)
		local ra, rb = resources[a].radius, resources[b].radius
		if ra ~= rb then
			return ra > rb
		end
		return a < b
	end)
	return ids
end

-- Devolve só os recursos gerados (os fixos não se repetem na lista).
function Scatter.generate(params: Params): { Placement }
	local resources = params.resources
	local minPassage = params.minPassage
	local maxAttempts = params.maxAttemptsPerItem or DEFAULT_MAX_ATTEMPTS

	-- Quantas células em volta olhar: a maior distância mínima possível entre
	-- dois recursos conhecidos, em células.
	local maxNeed = 0
	for _, a in resources do
		for _, b in resources do
			maxNeed = math.max(maxNeed, minDistance(a, b, minPassage))
		end
	end
	local reach = math.max(math.ceil(maxNeed / CELL_SIZE), 1)

	local grid: Grid = {}
	for _, fixed in params.fixed do
		local def = resources[fixed.resourceId]
		-- Id desconhecido: o MapService já avisa; aqui só não ocupa espaço.
		if def ~= nil then
			addToGrid(grid, { x = fixed.x, z = fixed.z, def = def })
		end
	end

	local result: { Placement } = {}
	for zoneIndex, zone in params.zones do
		local rng = Rng.new(params.seed + zoneIndex)
		local area = Shapes.area(zone.shape)
		local minX, minZ, maxX, maxZ = Shapes.bounds(zone.shape)

		for _, resourceId in sortedResourceIds(zone.densities, resources) do
			local def = resources[resourceId]
			local target = math.floor(area * math.max(zone.densities[resourceId], 0) / DENSITY_AREA)
			local placed = 0
			local failures = 0
			-- Depois de maxAttempts falhas seguidas a zona está cheia para este
			-- recurso: desiste dele, sem travar o servidor.
			while placed < target and failures < maxAttempts do
				local x = minX + rng:nextNumber() * (maxX - minX)
				local z = minZ + rng:nextNumber() * (maxZ - minZ)
				if
					Shapes.contains(zone.shape, x, z)
					and clearOfBlockers(params.blockers, x, z, def.radius)
					and hasRoom(grid, reach, x, z, def, minPassage)
				then
					addToGrid(grid, { x = x, z = z, def = def })
					table.insert(result, {
						resourceId = resourceId,
						x = x,
						z = z,
						variant = rng:nextInteger(1, def.variants),
						yaw = rng:nextNumber() * 2 * math.pi,
					})
					placed += 1
					failures = 0
				else
					failures += 1
				end
			end
		end
	end
	return result
end

return Scatter
