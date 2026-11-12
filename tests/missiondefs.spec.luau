--!strict
-- Dados das missões: chrono quests (Defs/Quests), diárias e semanais
-- (Defs/Missions), conquistas (Defs/Achievements), kits exclusivos e as
-- estatísticas novas. Números: docs/superpowers/specs/2026-11-12-missoes-design.md
-- e docs/game-design/quests-starve.md.
local Defs = require("../src/shared/Defs")
local Validate = require("../src/shared/Defs/Validate")

local FOREST_MOBS = { rabbit = true, wolf = true, spider = true, boar = true, hawk = true }

local function hasRule(quest: any, ruleType: string): boolean
	for _, rule in quest.rules do
		if rule.type == ruleType then
			return true
		end
	end
	return false
end

local function alwaysHas(_key: string): boolean
	return true
end

return {
	["quests: only survive and clean_hands are enabled"] = function()
		local quests = (Defs :: any).Quests
		assert(quests ~= nil, "Defs.Quests não existe")
		local expected = {
			"dragon",
			"amethyst",
			"survive",
			"luck",
			"clean_hands",
			"farmer",
			"hood",
			"lava",
			"reidite",
			"farmer_desert",
			"emerald",
			"sandworm",
			"explorer",
		}
		for _, id in expected do
			local quest = quests[id]
			assert(quest ~= nil, `quest {id} não existe`)
			local shouldBeOn = id == "survive" or id == "clean_hands"
			assert(quest.enabled == shouldBeOn, `quest {id}: enabled = {quest.enabled}`)
		end
		local count = 0
		for _ in quests do
			count += 1
		end
		assert(count == 13, `esperado 13 quests, veio {count}`)
	end,

	["quests: numbers from the Starve config"] = function()
		local quests = (Defs :: any).Quests
		local survive = quests.survive
		assert(survive.days == 4 and survive.ends == "time", "survive: 4 dias, termina no tempo")
		assert(hasRule(survive, "alone") and hasRule(survive, "unhurt"), "survive: alone + unhurt")
		assert(survive.rewardItem == "green_gem" and survive.rewardCount == 1, "survive: 1 gema verde")
		assert(survive.score == 7500, "survive: 7500 pontos")

		local clean = quests.clean_hands
		assert(clean.days == 6 and clean.ends == "time", "clean_hands: 6 dias, termina no tempo")
		assert(#clean.rules == 1 and hasRule(clean, "peaceful"), "clean_hands: só peaceful")
		assert(clean.rewardItem == "blue_gem" and clean.rewardCount == 1, "clean_hands: 1 gema azul")
		assert(clean.score == 3000, "clean_hands: 3000 pontos")

		local days = {
			dragon = 6,
			amethyst = 3,
			luck = 3,
			farmer = 5,
			hood = 5,
			lava = 10,
			reidite = 6,
			farmer_desert = 7,
			emerald = 6,
			sandworm = 8,
			explorer = 7,
		}
		for id, expected in days do
			assert(quests[id].days == expected, `{id}: {quests[id].days} dias, esperado {expected}`)
		end
		assert(quests.sandworm.rewardItem == "" and quests.explorer.rewardItem == "", "slot de mochila: sem item")
	end,

	["missions: pools have enough for the daily roll"] = function()
		local missions = (Defs :: any).Missions
		assert(missions ~= nil, "Defs.Missions não existe")
		local daily, weekly = 0, 0
		for id, mission in missions do
			if mission.period == "daily" then
				daily += 1
			elseif mission.period == "weekly" then
				weekly += 1
			else
				error(`missão {id}: period {mission.period}`)
			end
			local track = mission.track
			if track.stat then
				local stat = Defs.Stats[track.stat]
				assert(stat ~= nil, `missão {id}: estatística {track.stat} não existe`)
				if track.key then
					local ok = (stat.keyKind == "item" and Defs.Items[track.key] ~= nil)
						or (stat.keyKind == "mob" and FOREST_MOBS[track.key])
					assert(ok, `missão {id}: chave {track.key} inválida`)
				end
			else
				assert(track.life == "days" or track.life == "score", `missão {id}: track inválido`)
			end
		end
		assert(daily >= 3 and weekly >= 3, `diárias {daily}, semanais {weekly}`)
	end,

	["achievements: nine with three growing tiers"] = function()
		local achievements = (Defs :: any).Achievements
		assert(achievements ~= nil, "Defs.Achievements não existe")
		local ids = {
			"woodcutter",
			"miner",
			"hunter",
			"survivor",
			"crafter",
			"legend",
			"warrior",
			"faithful",
			"chronicler",
		}
		for _, id in ids do
			local a = achievements[id]
			assert(a ~= nil, `conquista {id} não existe`)
			assert(#a.tiers == 3, `{id}: {#a.tiers} níveis`)
			assert(a.tiers[1].target < a.tiers[2].target and a.tiers[2].target < a.tiers[3].target, `{id}: alvos`)
		end
		assert(achievements.woodcutter.tiers[3].target == 50000, "lenhador III = 50.000")
		assert(achievements.legend.tiers[3].target == 1000000, "lenda III = 1 milhão")
	end,

	["kits: exclusive kits exist"] = function()
		assert((Defs.Kits.kit_hunter :: any).exclusive == true, "kit_hunter exclusivo")
		assert((Defs.Kits.kit_guardian :: any).exclusive == true, "kit_guardian exclusivo")
		assert((Defs.Kits.kit_veteran :: any).exclusive ~= true, "kit_veteran continua na loja")
	end,

	["stats: new counters"] = function()
		assert(Defs.Stats.daily_sets_completed and Defs.Stats.daily_sets_completed.kind == "counter", "Fiel")
		assert(Defs.Stats.chrono_completed and Defs.Stats.chrono_completed.kind == "counter", "Cronista")
	end,

	["validate rejects bad mission track"] = function()
		local defs = table.clone(Defs :: any)
		defs.Missions = {
			daily_bad = {
				id = "daily_bad",
				period = "daily",
				nameKey = "mission.daily_bad",
				icon = "aba_diarias",
				track = { stat = "nope" },
				target = 10,
				rewards = { { kind = "ember", amount = 10 } },
			},
		}
		local errors = Validate.all(defs, alwaysHas)
		local found = false
		for _, message in errors do
			if string.find(message, "daily_bad", 1, true) and string.find(message, "nope", 1, true) then
				found = true
			end
		end
		assert(found, "esperava erro da estatística nope: " .. table.concat(errors, " | "))
	end,

	["validate rejects empty reward item on an enabled quest"] = function()
		local defs = table.clone(Defs :: any)
		local quests = table.clone(defs.Quests)
		local broken = table.clone(quests.survive)
		broken.rewardItem = ""
		quests.survive = broken
		defs.Quests = quests
		local errors = Validate.all(defs, alwaysHas)
		local found = false
		for _, message in errors do
			if string.find(message, "survive", 1, true) and string.find(message, "rewardItem", 1, true) then
				found = true
			end
		end
		assert(found, "esperava erro de rewardItem: " .. table.concat(errors, " | "))
	end,

	["validate rejects a test only reward on an enabled quest"] = function()
		local defs = table.clone(Defs :: any)
		local quests = table.clone(defs.Quests)
		local broken = table.clone(quests.survive)
		broken.rewardItem = "orange_gem" -- ainda testOnly
		quests.survive = broken
		defs.Quests = quests
		local errors = Validate.all(defs, alwaysHas)
		local found = false
		for _, message in errors do
			if string.find(message, "survive", 1, true) and string.find(message, "testOnly", 1, true) then
				found = true
			end
		end
		assert(found, "esperava erro de prêmio testOnly: " .. table.concat(errors, " | "))
	end,
}
