--!strict
local PinRules = require("../src/shared/UIFlow/PinRules")

return {
	["pinned recipe lists ingredients without capping the count"] = function()
		local lines = PinRules.lines("campfire", { wood = 30, stone = 2 })
		assert(#lines == 2, "madeira e pedra")
		assert(
			lines[1].item == "wood" and lines[1].have == 30 and lines[1].need == 25 and lines[1].done,
			"30/25, feito"
		)
		assert(lines[2].item == "stone" and lines[2].have == 2 and lines[2].need == 5 and not lines[2].done, "2/5")
	end,

	["missing items count as zero"] = function()
		local lines = PinRules.lines("wood_pickaxe", {})
		assert(#lines == 1 and lines[1].have == 0 and lines[1].need == 10, "0/10")
	end,

	["unknown recipe has no lines"] = function()
		assert(#PinRules.lines("nao_existe", { wood = 5 }) == 0, "sem receita")
		assert(PinRules.ready("nao_existe", {}) == false, "sem receita não está pronta")
	end,

	["ready when every ingredient is there"] = function()
		assert(not PinRules.ready("campfire", { wood = 30, stone = 4 }), "falta pedra")
		assert(PinRules.ready("campfire", { wood = 25, stone = 5 }), "tem tudo")
	end,
}
