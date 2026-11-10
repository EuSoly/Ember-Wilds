--!strict
local AssetIds = require("../src/shared/AssetPreload/AssetIds")

return {
	["collects asset ids from nested tables, once each"] = function()
		local ids = AssetIds.fromTable({
			A = "rbxassetid://10",
			B = { x = "rbxassetid://20", y = { z = "rbxassetid://10" } },
			C = "",
			D = "texto qualquer",
			E = 42,
		})
		table.sort(ids)
		assert(#ids == 2 and ids[1] == "rbxassetid://10" and ids[2] == "rbxassetid://20", table.concat(ids, ","))
	end,

	["merge keeps the first group's order and drops repeats"] = function()
		local groups = AssetIds.merge({
			{ name = "ui", ids = { "rbxassetid://1", "rbxassetid://2" } },
			{ name = "tools", ids = { "rbxassetid://2", "rbxassetid://3" } },
		})
		assert(#groups == 2, "dois grupos")
		assert(
			#groups[1].ids == 2 and #groups[2].ids == 1 and groups[2].ids[1] == "rbxassetid://3",
			"o 2 fica só no primeiro"
		)
		assert(AssetIds.total(groups) == 3, "3 no total")
	end,

	["valid ids only"] = function()
		assert(AssetIds.isAsset("rbxassetid://123"), "id")
		assert(AssetIds.isAsset("rbxasset://textures/x.png"), "arquivo do Roblox")
		assert(AssetIds.isAsset("http://www.roblox.com/asset/?id=5"), "url antiga")
		assert(not AssetIds.isAsset(""), "vazio")
		assert(not AssetIds.isAsset("Madeira"), "texto")
	end,
}
