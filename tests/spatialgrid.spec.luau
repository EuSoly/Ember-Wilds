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

	["empty grid returns nothing"] = function()
		assert(#SpatialGrid.new(16):query(0, 0, 50) == 0, "vazio")
	end,
}
