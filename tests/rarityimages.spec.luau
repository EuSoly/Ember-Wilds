--!strict
local RarityImages = require("../src/shared/RarityImages")

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

return {
	["one background per rarity, clamped"] = function()
		assert(#RarityImages.BACKGROUND == 6, "6 raridades")
		assert(RarityImages.background(0) == RarityImages.BACKGROUND[1], "abaixo de 1 = Comum")
		assert(RarityImages.background(9) == RarityImages.BACKGROUND[6], "acima de 6 = Mítico")
		assert(RarityImages.background(4) == RarityImages.BACKGROUND[4], "Épico")
	end,

	["corners keep the same share of the tile at any size"] = function()
		local small = RarityImages.sliceScale(60)
		local big = RarityImages.sliceScale(240)
		assert(near(big, small * 4), "4x maior = cantos 4x maiores")
		assert(
			near(RarityImages.CORNER * RarityImages.sliceScale(100), 100 * RarityImages.CORNER_SHARE),
			"fração do lado"
		)
	end,

	["corner never passes half of the tile"] = function()
		assert(RarityImages.CORNER_SHARE < 0.5, "cantos menores que metade")
		assert(RarityImages.sliceScale(0) == 0, "lado 0 = escala 0")
	end,
}
