--!strict
local MenuLayout = require("../src/shared/UIFlow/MenuLayout")

local SIZES = { { 800, 400 }, { 1130, 793 }, { 1920, 1080 } }

local function eachSize(check: (w: number, h: number, l: MenuLayout.Layout) -> ())
	for _, size in SIZES do
		check(size[1], size[2], MenuLayout.compute(size[1], size[2]))
	end
end

return {
	["pods end above the body"] = function()
		eachSize(function(_, _, l)
			assert(l.podBottom <= l.bodyTop, "pods overlap the body")
			assert(l.podTop >= 0, "pod above the screen")
		end)
	end,
	["column and panels end inside the screen"] = function()
		eachSize(function(w, h, l)
			assert(l.columnBottom <= h and l.panelBottom <= h, "runs off the bottom")
			assert(l.columnBottom > l.bodyTop and l.panelBottom > l.contentTop, "no room left")
			assert(l.panelX + l.panelWidth <= w, "panel runs off the right")
			assert(l.panelX >= l.columnX + l.columnWidth, "panel overlaps the column")
		end)
	end,
	["column buttons fit at touch min or the column scrolls"] = function()
		eachSize(function(_, _, l)
			local room = l.columnBottom - l.bodyTop
			assert(l.columnScrolls == (l.columnContentHeight > room), "scroll flag wrong")
			assert(l.columnContentHeight >= MenuLayout.NAV_COUNT * 44, "buttons below touch min")
		end)
		-- No menor caso (800x400) os 6 botões ainda cabem sem rolar.
		assert(not MenuLayout.compute(800, 400).columnScrolls, "800x400 should fit")
	end,
	["title row holds a touch-size close button"] = function()
		assert(MenuLayout.TITLE_ROW >= 44, "title row too short")
	end,
	["tiny screens scroll the column instead of overflowing"] = function()
		assert(MenuLayout.compute(800, 300).columnScrolls, "300 high should scroll")
	end,
}
