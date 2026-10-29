--!strict
local ScreenFlow = require("../src/shared/UIFlow/ScreenFlow")

return {
	["valid transitions"] = function()
		assert(ScreenFlow.next("loading", "ready") == "menu", "loading --ready--> menu")
		assert(ScreenFlow.next("menu", "spawned") == "playing", "menu --spawned--> playing")
		assert(ScreenFlow.next("playing", "died") == "dead", "playing --died--> dead")
		assert(ScreenFlow.next("dead", "spawned") == "playing", "dead --spawned--> playing")
		assert(ScreenFlow.next("dead", "toMenu") == "menu", "dead --toMenu--> menu")
	end,

	["invalid events keep the current screen"] = function()
		assert(ScreenFlow.next("menu", "died") == "menu", "menu não morre")
		assert(ScreenFlow.next("loading", "spawned") == "loading", "loading não nasce")
		assert(ScreenFlow.next("playing", "toMenu") == "playing", "playing não vai ao menu")
		assert(ScreenFlow.next("playing", "ready") == "playing", "ready só vale no loading")
		assert(ScreenFlow.next("dead", "died") == "dead", "morto não morre de novo")
	end,

	["hud only while playing"] = function()
		assert(ScreenFlow.hudVisible("playing") == true, "playing mostra a HUD")
		assert(ScreenFlow.hudVisible("loading") == false, "loading")
		assert(ScreenFlow.hudVisible("menu") == false, "menu")
		assert(ScreenFlow.hudVisible("dead") == false, "dead")
	end,

	["settings open in menu and playing"] = function()
		assert(ScreenFlow.canOpenSettings("menu") == true, "menu")
		assert(ScreenFlow.canOpenSettings("playing") == true, "playing")
		assert(ScreenFlow.canOpenSettings("loading") == false, "loading")
		assert(ScreenFlow.canOpenSettings("dead") == false, "dead")
	end,
}
