--!strict
local BookImages = require("../src/shared/BookImages")
local BookInfo = require("../src/shared/UIFlow/BookInfo")

local function sliceInside(slice: { number }, size: { number }): boolean
	return slice[1] > 0
		and slice[2] > 0
		and slice[3] < size[1]
		and slice[4] < size[2]
		and slice[1] < slice[3]
		and slice[2] < slice[4]
end

return {
	["every tab has an icon key"] = function()
		for _, tab in BookInfo.TABS do
			assert(BookImages.TAB_ICON[tab] ~= nil, `sem ícone da aba {tab}`)
		end
	end,

	["every station has an icon key"] = function()
		for id, station in BookInfo.STATIONS do
			assert(BookImages.STATION[station.icon] ~= nil, `sem ícone da estação {id}`)
		end
	end,

	["sliced rects stay inside their art"] = function()
		for name, art in BookImages.SLICED do
			assert(sliceInside(art.slice, art.size), `9 partes de {name} fora da arte`)
		end
	end,

	["every map resource with gather has an icon key"] = function()
		for _, id in { "tree", "rock", "gold_vein", "berry_bush" } do
			assert(BookImages.RESOURCE[id] ~= nil, `sem ícone do recurso {id}`)
		end
	end,
}
