--!strict
local ToolGallery = require("../src/shared/Models/ToolGallery")

return {
	["groups by kind in tier order and sends the rest to outros"] = function()
		local rows = ToolGallery.rows({
			"gold_sword",
			"wrench",
			"wood_sword",
			"stone_pickaxe",
			"wood_pickaxe",
			"super_hammer",
			"crab_spear",
			"book",
		})
		assert(#rows == 4, `fileiras: {#rows}`)
		assert(
			rows[1].kind == "pickaxe" and rows[1].ids[1] == "wood_pickaxe" and rows[1].ids[2] == "stone_pickaxe",
			"picaretas"
		)
		assert(rows[2].kind == "sword" and rows[2].ids[1] == "wood_sword" and rows[2].ids[2] == "gold_sword", "espadas")
		assert(rows[3].kind == "spear" and rows[3].ids[1] == "crab_spear", "lança de caranguejo é lança")
		local others = rows[4]
		assert(others.kind == "outros", "outros por último")
		-- super_hammer: "super" não é tier, vai para outros; ordem alfabética.
		assert(table.concat(others.ids, ",") == "book,super_hammer,wrench", table.concat(others.ids, ","))
	end,

	["empty list has no rows"] = function()
		assert(#ToolGallery.rows({}) == 0, "sem fileiras")
	end,
}
