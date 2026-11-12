--!strict
-- Regras de exibição da tela de Missões (src/shared/UIFlow/MissionView).
local Defs = require("../src/shared/Defs")
local MissionView = require("../src/shared/UIFlow/MissionView")

local function card(id: string, state: number, progress: number?, target: number?, endsAt: number?): any
	return { Id = id, Progress = progress or 0, Target = target or 10, State = state, EndsAt = endsAt or 0 }
end

local function data(): any
	return {
		Creative = false,
		InLife = true,
		Chrono = { card("survive", 1), card("clean_hands", 0) },
		LifeDay = 3,
		Daily = { card("daily_wood", 1), card("daily_gold", 1), card("daily_berry", 2) },
		DailyFinal = card("final", 4, 1, 3, 1000),
		Weekly = { card("weekly_wood", 0) },
		WeeklyFinal = card("final", 4, 0, 3, 5000),
		Achievements = {
			{ Id = "woodcutter", Progress = 12000, Claimed = 1, Ready = true, Soon = false },
			{ Id = "miner", Progress = 10, Claimed = 2, Ready = false, Soon = false },
			{ Id = "hunter", Progress = 0, Claimed = 0, Ready = false, Soon = false },
		},
	}
end

return {
	["badges count ready cards per tab"] = function()
		local b = MissionView.badges(data())
		assert(b.match == 1, `partida {b.match}`)
		assert(b.daily == 2, `diárias {b.daily}`)
		assert(b.weekly == 0, `semanais {b.weekly}`)
		assert(b.achievements == 1, `conquistas {b.achievements}`)
		assert(b.total == 4, `total {b.total}`)
	end,

	["final counts when ready"] = function()
		local d = data()
		d.WeeklyFinal.State = 1
		assert(MissionView.badges(d).weekly == 1, "final semanal pronta não contou")
	end,

	["no badges without data or in creative"] = function()
		assert(MissionView.badges(nil).total == 0, "sem dados")
		local d = data()
		d.Creative = true
		assert(MissionView.badges(d).total == 0, "criativo")
	end,

	["time left formats days hours minutes"] = function()
		assert(MissionView.timeLeft(26 * 3600 + 5) == "1d 2h", MissionView.timeLeft(26 * 3600 + 5))
		assert(MissionView.timeLeft(7 * 3600 + 12 * 60) == "7h 12min", MissionView.timeLeft(7 * 3600 + 12 * 60))
		assert(MissionView.timeLeft(45 * 60) == "45min", MissionView.timeLeft(45 * 60))
		assert(MissionView.timeLeft(45) == "45s", MissionView.timeLeft(45))
		assert(MissionView.timeLeft(-3) == "0s", "nunca negativo")
	end,

	["tab header shows life day"] = function()
		local header = MissionView.tabHeader("match", data(), 0)
		assert(header == "Valem só nesta vida · Dia 3", header)
		local d = data()
		d.InLife = false
		assert(MissionView.tabHeader("match", d, 0) == "Entre no jogo para começar", "fora da vida")
	end,

	["daily header counts down to the turn"] = function()
		local header = MissionView.tabHeader("daily", data(), 1000 - 3 * 3600)
		assert(header == "Renova em 3h 0min", header)
		assert(MissionView.tabHeader("weekly", data(), 0) == "Renova domingo", "semanal")
	end,

	["achievement header counts claimed tiers"] = function()
		local header = MissionView.tabHeader("achievements", data(), 0)
		assert(header == "3 / 9", header)
	end,

	["creative header says missions are off"] = function()
		local d = data()
		d.Creative = true
		assert(MissionView.tabHeader("daily", d, 0) == "Missões desligadas no modo criativo", "criativo")
	end,

	["progress text shows counts"] = function()
		assert(MissionView.progressText(card("daily_wood", 0, 120, 200)) == "120 / 200", "contagem")
	end,

	["mission name fills the target"] = function()
		assert(
			MissionView.missionName("daily_wood", 200) == "Colete 200 madeira",
			MissionView.missionName("daily_wood", 200)
		)
	end,

	["reward text names what the player gets"] = function()
		local ember = MissionView.rewardText({ { kind = "ember", amount = 40 } }, Defs)
		assert(ember == "+40 Golden Ember", ember)
		local kit = MissionView.rewardText({ { kind = "kitOnce", id = "kit_explorer", count = 1 } }, Defs)
		assert(kit == "1 uso de kit", kit)
		local spins = MissionView.rewardText({ { kind = "spins", spin = "paid", count = 2 } }, Defs)
		assert(spins == "2 giros especiais", spins)
		local both = MissionView.rewardText({
			{ kind = "spins", spin = "paid", count = 1 },
			{ kind = "kitOnce", id = "kit_veteran", count = 1 },
		}, Defs)
		assert(both == "1 giros especiais + 1 uso de kit", both)
		local forever = MissionView.rewardText({ { kind = "kit", id = "kit_hunter" } }, Defs)
		assert(forever == "Kit Caçador", forever)
		assert(MissionView.rewardText({}, Defs) == "Em breve", "vazio = em breve")
	end,

	["quest reward shows the item and the points"] = function()
		local text = MissionView.questReward(Defs.Quests.survive, Defs)
		assert(text == "Gema verde · 7500 pts", text)
	end,

	["chrono bar follows the clock"] = function()
		local c = card("survive", 0, 0, 1920, 1000)
		assert(MissionView.chronoFraction(c, 1000 - 1920) == 0, "no começo")
		assert(math.abs(MissionView.chronoFraction(c, 1000 - 960) - 0.5) < 1e-9, "na metade")
		assert(MissionView.chronoFraction(c, 2000) == 1, "passou do prazo")
		local done = card("survive", 1, 1920, 1920, 0)
		assert(MissionView.chronoFraction(done, 0) == 1, "pronta = cheia")
	end,

	["daily header waits for the first snapshot"] = function()
		assert(MissionView.tabHeader("daily", nil, 0) == "", "sem dados mostrou um tempo")
	end,

	["reward badges pair an icon with a short text"] = function()
		local ember = MissionView.rewardBadges({ { kind = "ember", amount = 40 } }, Defs)
		assert(#ember == 1 and ember[1].kind == "ember" and ember[1].text == "+40", "ember")
		local both = MissionView.rewardBadges({
			{ kind = "spins", spin = "paid", count = 1 },
			{ kind = "kitOnce", id = "kit_veteran", count = 1 },
		}, Defs)
		assert(both[1].kind == "spins" and both[1].text == "×1", `giro: {both[1].text}`)
		assert(both[2].kind == "kit" and both[2].id == "kit_veteran" and both[2].text == "×1", "uso de kit")
		local forever = MissionView.rewardBadges({ { kind = "kit", id = "kit_hunter" } }, Defs)
		assert(forever[1].kind == "kit" and forever[1].text == "Caçador", forever[1].text)
		local soon = MissionView.rewardBadges({}, Defs)
		assert(soon[1].kind == "soon" and soon[1].text == "Em breve", "em breve")
	end,

	["quest badges show the item and the points"] = function()
		local badges = MissionView.questBadges(Defs.Quests.survive)
		assert(badges[1].kind == "item" and badges[1].id == "green_gem", "gema")
		assert(badges[2].kind == "score" and badges[2].text == "7500 pts", badges[2].text)
	end,
}
