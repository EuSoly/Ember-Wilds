--!strict
-- Grade espacial no plano XZ: guarda itens por célula e devolve os que estão
-- nas células que um círculo toca (pode trazer alguns um pouco fora do raio;
-- quem chama confere a distância exata). Serve para o golpe de coleta não
-- varrer os ~1.600 recursos do mapa, e para achar as peças de construção por
-- perto (essas saem com remove). (Só números: testável no Lune.)
local SpatialGrid = {}
SpatialGrid.__index = SpatialGrid

export type Grid = typeof(setmetatable({} :: { cellSize: number, cells: { [number]: { any } } }, SpatialGrid))

-- Chave única de uma célula (coordenadas de célula bem abaixo de ±32.768).
local function key(cx: number, cz: number): number
	return cx * 65536 + cz
end

function SpatialGrid.new(cellSize: number): Grid
	return setmetatable({ cellSize = cellSize, cells = {} }, SpatialGrid)
end

function SpatialGrid.insert(self: Grid, item: any, x: number, z: number)
	local k = key(math.floor(x / self.cellSize), math.floor(z / self.cellSize))
	local cell = self.cells[k]
	if cell == nil then
		cell = {}
		self.cells[k] = cell
	end
	table.insert(cell, item)
end

-- Tira o item guardado em (x, z) (as mesmas coordenadas do insert). Devolve
-- se achou. A ordem dentro da célula não importa: troca pelo último e corta.
function SpatialGrid.remove(self: Grid, item: any, x: number, z: number): boolean
	local k = key(math.floor(x / self.cellSize), math.floor(z / self.cellSize))
	local cell = self.cells[k]
	if cell == nil then
		return false
	end
	local index = table.find(cell, item)
	if index == nil then
		return false
	end
	local last = #cell
	cell[index] = cell[last]
	cell[last] = nil
	if last == 1 then
		self.cells[k] = nil
	end
	return true
end

-- Itens das células que o círculo (x, z, radius) toca.
function SpatialGrid.query(self: Grid, x: number, z: number, radius: number): { any }
	local size = self.cellSize
	local found = {}
	for cx = math.floor((x - radius) / size), math.floor((x + radius) / size) do
		for cz = math.floor((z - radius) / size), math.floor((z + radius) / size) do
			local cell = self.cells[key(cx, cz)]
			if cell then
				table.move(cell, 1, #cell, #found + 1, found)
			end
		end
	end
	return found
end

return SpatialGrid
