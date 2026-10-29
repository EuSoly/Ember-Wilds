--!strict
local Strings = require("../src/shared/Strings")

return {
	["returns pt-BR text"] = function()
		assert(Strings.get("tier.gold") == "Ouro", `veio {Strings.get("tier.gold")}`)
		assert(Strings.get("rarity.legendary") == "Lendário", `veio {Strings.get("rarity.legendary")}`)
	end,

	["missing key is visible"] = function()
		assert(Strings.get("nao.existe") == "[nao.existe]", `veio {Strings.get("nao.existe")}`)
	end,

	["format fills variables"] = function()
		assert(Strings.format("hud.day", { day = 3 }) == "Dia 3", Strings.format("hud.day", { day = 3 }))
	end,

	["format keeps unknown variables"] = function()
		assert(Strings.format("hud.day", {}) == "Dia {day}", Strings.format("hud.day", {}))
	end,

	["has reports presence"] = function()
		assert(Strings.has("rarity.legendary") == true, "rarity.legendary deveria existir")
		assert(Strings.has("nao.existe") == false, "nao.existe não deveria existir")
	end,
}
