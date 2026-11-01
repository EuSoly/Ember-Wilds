--!strict
local SpatialGrid = require("../src/shared/World/SpatialGrid")

local function has(list: { any }, item: any): boolean
	return table.find(list, item) ~= nil
end

return {
	["finds items around a point"] = function()
		local grid = SpatialGrid.new(16)
		grid:insert("a", 10, 10)
		grid:insert("b", 100, 100)
		grid:insert("c", 17, 10) -- célula vizinha
		local found = grid:query(12, 10, 6)
		assert(has(found, "a"), "achou a")
		assert(has(found, "c"), "achou c na célula vizinha")
		assert(not has(found, "b"), "não achou b, longe")
	end,

	["negative coordinates work"] = function()
		local grid = SpatialGrid.new(16)
		grid:insert("n", -630, 630)
		assert(has(grid:query(-631, 629, 3), "n"), "achou em coordenada negativa")
	end,

	["remove takes only that item out"] = function()
		local grid = SpatialGrid.new(16)
		grid:insert("a", 10, 10)
		grid:insert("b", 11, 11) -- mesma célula
		grid:insert("c", -5, -5)
		assert(grid:remove("a", 10, 10), "achou a para tirar")
		local found = grid:query(10, 10, 2)
		assert(not has(found, "a"), "a saiu")
		assert(has(found, "b"), "b ficou na mesma célula")
		assert(not grid:remove("a", 10, 10), "tirar de novo não acha")
		assert(not grid:remove("c", 10, 10), "coordenada errada não acha")
		assert(grid:remove("c", -5, -5), "c com negativas")
		assert(grid:remove("b", 11, 11), "b")
		assert(#grid:query(0, 0, 50) == 0, "vazio depois de tirar tudo")
		assert(next(grid.cells) == nil, "célula vazia é apagada")
	end,

	["empty grid returns nothing"] = function()
		assert(#SpatialGrid.new(16):query(0, 0, 50) == 0, "vazio")
	end,
}
