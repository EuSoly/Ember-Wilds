--!strict
local HudImages = require("../src/shared/HudImages")

local function sliceInside(slice: { number }, size: { number }): boolean
	return slice[1] > 0
		and slice[2] > 0
		and slice[3] < size[1]
		and slice[4] < size[2]
		and slice[1] < slice[3]
		and slice[2] < slice[4]
end

return {
	["every status has an icon"] = function()
		for _, stat in { "health", "hunger", "cold", "thirst", "heat", "oxygen" } do
			assert(HudImages.STATUS_ICON[stat] ~= nil, `sem ícone de {stat}`)
		end
	end,

	["nine-slice rects stay inside their art"] = function()
		for name, art in HudImages.SLICED do
			assert(sliceInside(art.slice, art.size), `9 partes de {name} fora da arte`)
		end
	end,

	["one toast per kind"] = function()
		for _, kind in { "info", "alert", "success" } do
			assert(HudImages.TOAST[kind] ~= nil, `sem faixa de aviso {kind}`)
		end
	end,

	["status ring fits inside the medallion hole"] = function()
		assert(HudImages.STATUS_HOLE > 0.5 and HudImages.STATUS_HOLE < 0.8, "furo do medalhão")
		assert(HudImages.MINIMAP_INSET > 0 and HudImages.MINIMAP_INSET < 0.2, "borda do minimapa")
	end,
}
