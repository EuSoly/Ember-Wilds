--!strict
local Defs = require("../src/shared/Defs")
local MissionImages = require("../src/shared/MissionImages")

return {
	["mission images: every icon used by Defs exists"] = function()
		local used: { [string]: string } = {}
		for id, def in Defs.Quests do
			used[def.icon] = `quest {id}`
		end
		for id, def in Defs.Missions do
			used[def.icon] = `missão {id}`
		end
		for id, def in Defs.Achievements do
			used[def.icon] = `conquista {id}`
		end
		for _, key in { "missao_hud", "aba_partida", "aba_diarias", "aba_semanais", "aba_conquistas" } do
			used[key] = "tela"
		end
		for _, key in { "premio_giro_especial", "premio_uso_kit" } do
			used[key] = "prêmio"
		end
		for icon, who in used do
			assert(MissionImages.ICON[icon] ~= nil, `{who}: ícone {icon} não existe em MissionImages.ICON`)
		end
	end,

	["slices inside sizes"] = function()
		for name, piece in MissionImages.PIECES do
			local size, slice = piece.size, piece.slice
			assert(size[1] > 0 and size[2] > 0 and size[1] <= 1024 and size[2] <= 1024, `{name}: tamanho`)
			if slice then
				assert(slice[1] > 0 and slice[2] > 0, `{name}: slice começa dentro`)
				assert(slice[3] < size[1] and slice[4] < size[2], `{name}: slice termina dentro`)
				assert(slice[1] < slice[3] and slice[2] < slice[4], `{name}: slice com miolo`)
			end
		end
	end,

	["every piece has an image field"] = function()
		for _, name in { "WINDOW", "TAB", "TAB_ON", "CARD_ACTIVE", "CARD_DONE", "CARD_FAILED", "BAR_TRACK" } do
			assert(MissionImages.PIECES[name] ~= nil, `falta a peça {name}`)
			assert(type(MissionImages.PIECES[name].image) == "string", `{name}: image`)
		end
		for _, name in { "BAR_ORANGE", "BAR_GREEN", "CLAIM", "CLAIM_DOWN", "PLATE", "DOT" } do
			assert(MissionImages.PIECES[name] ~= nil, `falta a peça {name}`)
		end
		for _, name in { "BANNER_DONE", "BANNER_FAILED", "MEDAL_BRONZE", "MEDAL_SILVER", "MEDAL_GOLD", "MEDAL_LOCKED" } do
			assert(MissionImages.PIECES[name] ~= nil, `falta a peça {name}`)
		end
	end,
}
