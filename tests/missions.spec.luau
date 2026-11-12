--!strict
-- Regras puras das diárias, semanais e conquistas (src/shared/Missions).
local Defs = require("../src/shared/Defs")
local ProfileTemplate = require("../src/shared/Data/ProfileTemplate")
local RankRules = require("../src/shared/Data/RankRules")
local MissionConfig = require("../src/shared/Missions/MissionConfig")
local MissionData = require("../src/shared/Missions/MissionData")
local PeriodRules = require("../src/shared/Missions/PeriodRules")
local AchievementRules = require("../src/shared/Missions/AchievementRules")

-- Segunda 09/11/2026 00:00:00 em Brasília (o mesmo instante do rankrules.spec).
local MON_09_0000 = 1794193200

-- Estatísticas falsas: "stat" ou "stat/key" → valor.
local function reader(values: { [string]: number }): (any) -> number
	return function(track: any): number
		local name = if track.key then `{track.stat}/{track.key}` else track.stat
		return values[name] or 0
	end
end

local function noLife(_life: string): number
	return 0
end

local function lifeOf(days: number, score: number): (string) -> number
	return function(life: string): number
		return if life == "days" then days else score
	end
end

-- Um período com um slot fixo (para testar progresso e resgate sem sorteio).
local function periodWith(ids: { string }, base: number?): any
	local save = MissionData.empty().Daily
	save.Index = 1
	for _, id in ids do
		table.insert(save.Slots, { Id = id, Base = base or 0, Best = 0, Claimed = false })
	end
	return save
end

return {
	["profile template has empty missions"] = function()
		local missions = ProfileTemplate.build(Defs :: any).Missions
		assert(missions ~= nil, "perfil sem Missions")
		assert(missions.Daily.Index == 0 and #missions.Daily.Slots == 0, "diária não começa vazia")
		assert(missions.Weekly.Index == 0, "semanal não começa vazia")
		assert(next(missions.Achievements) == nil, "conquistas não começam vazias")
	end,

	["daily roll picks 3 distinct daily missions"] = function()
		local save = MissionData.empty().Daily
		local changed = PeriodRules.ensure(save, "daily", 100, 42, reader({}), Defs)
		assert(changed, "primeiro sorteio deveria mudar")
		assert(#save.Slots == MissionConfig.DAILY_COUNT and MissionConfig.DAILY_COUNT == 3, `{#save.Slots} slots`)
		local seen = {}
		for _, slot in save.Slots do
			assert(not seen[slot.Id], `repetida: {slot.Id}`)
			seen[slot.Id] = true
			assert(Defs.Missions[slot.Id].period == "daily", `{slot.Id} não é diária`)
		end
		assert(save.FinalReward >= 1 and save.FinalReward <= #MissionConfig.DAILY_FINAL, "final sem prêmio")
	end,

	["weekly roll picks 3 weekly missions"] = function()
		local save = MissionData.empty().Weekly
		PeriodRules.ensure(save, "weekly", 7, 42, reader({}), Defs)
		assert(#save.Slots == 3, `{#save.Slots} semanais`)
		for _, slot in save.Slots do
			assert(Defs.Missions[slot.Id].period == "weekly", `{slot.Id} não é semanal`)
		end
	end,

	["same player same day rolls the same"] = function()
		local a, b = MissionData.empty().Daily, MissionData.empty().Daily
		PeriodRules.ensure(a, "daily", 100, 42, reader({}), Defs)
		PeriodRules.ensure(b, "daily", 100, 42, reader({}), Defs)
		for index, slot in a.Slots do
			assert(slot.Id == b.Slots[index].Id, "mesmo dia e jogador deu sorteio diferente")
		end
		assert(not PeriodRules.ensure(a, "daily", 100, 42, reader({}), Defs), "mesmo dia não muda")
	end,

	["next day rolls again"] = function()
		local save = MissionData.empty().Daily
		PeriodRules.ensure(save, "daily", 100, 42, reader({}), Defs)
		save.Slots[1].Claimed = true
		save.FinalClaimed = true
		assert(PeriodRules.ensure(save, "daily", 101, 42, reader({}), Defs), "dia seguinte deveria mudar")
		assert(save.Index == 101, "índice não virou")
		for _, slot in save.Slots do
			assert(not slot.Claimed, "resgate do dia anterior ficou")
		end
		assert(not save.FinalClaimed, "final do dia anterior ficou")
	end,

	["period rolls over at midnight"] = function()
		local save = MissionData.empty().Daily
		local before = RankRules.dayIndex(MON_09_0000 - 1)
		local after = RankRules.dayIndex(MON_09_0000)
		PeriodRules.ensure(save, "daily", before, 42, reader({}), Defs)
		assert(not PeriodRules.ensure(save, "daily", before, 42, reader({}), Defs), "23:59:59 ainda é o mesmo dia")
		assert(PeriodRules.ensure(save, "daily", after, 42, reader({}), Defs), "00:00 vira o dia")
	end,

	["roll records the stat base"] = function()
		local save = MissionData.empty().Daily
		local values = { ["resources_gathered/wood"] = 500, mobs_killed = 30 }
		PeriodRules.ensure(save, "daily", 100, 42, reader(values), Defs)
		for _, slot in save.Slots do
			local def = Defs.Missions[slot.Id]
			if def.track.life then
				assert(slot.Base == 0, `{slot.Id}: missão de vida com base`)
			else
				assert(slot.Base == reader(values)(def.track), `{slot.Id}: base {slot.Base}`)
			end
		end
	end,

	["progress counts only after the roll"] = function()
		local save = periodWith({ "daily_wood" }, 500)
		local slot = save.Slots[1]
		local def = Defs.Missions.daily_wood
		assert(
			PeriodRules.progress(slot, def, reader({ ["resources_gathered/wood"] = 620 }), noLife) == 120,
			"620−500"
		)
		assert(
			PeriodRules.progress(slot, def, reader({ ["resources_gathered/wood"] = 9999 }), noLife) == 200,
			"teto no alvo"
		)
		assert(
			PeriodRules.progress(slot, def, reader({ ["resources_gathered/wood"] = 10 }), noLife) == 0,
			"nunca negativo"
		)
	end,

	["life progress keeps the best life"] = function()
		local save = periodWith({ "daily_days" })
		local slot = save.Slots[1]
		local def = Defs.Missions.daily_days
		slot.Best = 1
		assert(PeriodRules.progress(slot, def, reader({}), lifeOf(0, 0)) == 1, "melhor vida guardada")
		assert(PeriodRules.progress(slot, def, reader({}), lifeOf(2, 0)) == 2, "vida atual conta")
		assert(PeriodRules.observeLife(save, Defs, lifeOf(2, 0)), "deveria guardar o melhor")
		assert(slot.Best == 2, "Best não subiu")
		assert(not PeriodRules.observeLife(save, Defs, lifeOf(1, 0)), "vida pior não muda")
	end,

	["claim twice pays once"] = function()
		local save = periodWith({ "daily_wood" }, 0)
		local values = reader({ ["resources_gathered/wood"] = 200 })
		local rewards = PeriodRules.claim(save, "daily_wood", Defs, values, noLife)
		assert(rewards ~= nil and rewards[1].kind == "ember" and rewards[1].amount == 40, "prêmio da madeira")
		assert(PeriodRules.claim(save, "daily_wood", Defs, values, noLife) == nil, "pagou duas vezes")
	end,

	["claim refuses an unfinished mission"] = function()
		local save = periodWith({ "daily_wood" }, 0)
		local values = reader({ ["resources_gathered/wood"] = 199 })
		assert(PeriodRules.claim(save, "daily_wood", Defs, values, noLife) == nil, "resgatou sem completar")
		assert(PeriodRules.claim(save, "daily_gold", Defs, values, noLife) == nil, "resgatou missão fora do sorteio")
	end,

	["final unlocks after the three claims"] = function()
		local save = periodWith({ "daily_wood", "daily_stone", "daily_gold" }, 0)
		save.FinalReward = 2
		local values = reader({
			["resources_gathered/wood"] = 200,
			["resources_gathered/stone"] = 150,
			["resources_gathered/gold"] = 30,
		})
		PeriodRules.claim(save, "daily_wood", Defs, values, noLife)
		PeriodRules.claim(save, "daily_stone", Defs, values, noLife)
		assert(PeriodRules.claimFinal(save, "daily") == nil, "final com 2 de 3")
		PeriodRules.claim(save, "daily_gold", Defs, values, noLife)
		local final = PeriodRules.claimFinal(save, "daily")
		assert(final ~= nil and #final == 1, "final diária = 1 prêmio")
		assert(final[1] == MissionConfig.DAILY_FINAL[2], "prêmio sorteado no rolo")
		assert(PeriodRules.claimFinal(save, "daily") == nil, "final pagou duas vezes")

		local weekly = periodWith({ "weekly_wood" }, 0)
		weekly.Slots[1].Claimed = true
		local weeklyFinal = PeriodRules.claimFinal(weekly, "weekly")
		assert(weeklyFinal ~= nil and #weeklyFinal == #MissionConfig.WEEKLY_FINAL, "final semanal = todos")
	end,

	["sanitize drops unknown ids and bad fields"] = function()
		local raw = {
			Daily = {
				Index = 5,
				Slots = {
					{ Id = "sumiu", Base = 1, Best = 0, Claimed = false },
					{ Id = "daily_wood", Base = "x", Best = -3, Claimed = "sim" },
				},
				FinalReward = 99,
				FinalClaimed = 1,
			},
			Weekly = "lixo",
			Achievements = { woodcutter = "a", hunter = 2, nao_existe = 1, miner = 7 },
		}
		local save = MissionData.sanitize(raw, Defs)
		assert(save.Daily.Index == 5, "índice perdido")
		assert(#save.Daily.Slots == 1 and save.Daily.Slots[1].Id == "daily_wood", "slot desconhecido ficou")
		local slot = save.Daily.Slots[1]
		assert(slot.Base == 0 and slot.Best == 0 and slot.Claimed == false, "campos quebrados não zeraram")
		assert(save.Daily.FinalReward == 1 and save.Daily.FinalClaimed == false, "final quebrada")
		assert(save.Weekly.Index == 0 and #save.Weekly.Slots == 0, "semanal quebrada não virou vazia")
		assert(save.Achievements.woodcutter == nil and save.Achievements.hunter == 2, "nível de conquista")
		assert(save.Achievements.nao_existe == nil, "conquista desconhecida ficou")
		assert(save.Achievements.miner == 3, "nível acima de 3 não foi limitado")
		local fresh = MissionData.sanitize(nil, Defs)
		assert(fresh.Daily.Index == 0, "nil não virou vazio")
	end,

	["stat reader sums keyed stats without key"] = function()
		local stats = { mobs_killed = { wolf = 3, rabbit = 4 }, resources_gathered = { wood = 10 } }
		local read = MissionData.statReader(stats, Defs)
		assert(read({ stat = "mobs_killed" }) == 7, "soma dos mobs")
		assert(read({ stat = "mobs_killed", key = "wolf" }) == 3, "só lobo")
		assert(read({ stat = "resources_gathered", key = "gold" }) == 0, "sem ouro")
	end,

	["achievement tiers climb one at a time"] = function()
		local save = MissionData.empty()
		local def = Defs.Achievements.woodcutter
		local read = reader({ ["resources_gathered/wood"] = 12000 })
		local progress = AchievementRules.progress(def, read, noLife)
		assert(progress == 12000, `progresso {progress}`)
		local first = AchievementRules.claim(save, def, progress)
		assert(first ~= nil and first[1].kind == "ember" and first[1].amount == 200, "nível I")
		assert(save.Achievements.woodcutter == 1, "nível 1 não gravou")
		local second = AchievementRules.claim(save, def, progress)
		assert(second ~= nil and second[1].kind == "spins", "nível II")
		assert(AchievementRules.claim(save, def, progress) == nil, "nível III pede 50.000")
		assert(save.Achievements.woodcutter == 2, "subiu demais")
	end,

	["single life achievement uses the current life"] = function()
		local def = Defs.Achievements.survivor
		local progress = AchievementRules.progress(def, reader({ days_best = 3 }), lifeOf(6, 0))
		assert(progress == 6, `progresso {progress}`)
		assert(AchievementRules.claimable(def, 0, progress) == 1, "nível I (5 dias) resgatável")
		local older = AchievementRules.progress(def, reader({ days_best = 8 }), lifeOf(2, 0))
		assert(older == 8, "a melhor vida guardada vale")
	end,

	["tier without rewards stays soon"] = function()
		local def = Defs.Achievements.woodcutter
		assert(AchievementRules.claimable(def, 2, 50000) == nil, "nível sem prêmio resgatável")
		assert(AchievementRules.isSoon(def, 2), "nível III do lenhador é em breve")
		assert(not AchievementRules.isSoon(Defs.Achievements.hunter, 2), "caçador III tem kit")
		assert(AchievementRules.claimable(Defs.Achievements.hunter, 2, 5000) == 3, "caçador III resgatável")
	end,

	["period ends at midnight and sunday in Brasilia"] = function()
		local day = RankRules.dayIndex(MON_09_0000)
		assert(PeriodRules.endsAt("daily", day) == MON_09_0000 + 86400 - 1, "diária acaba 23:59:59")
		assert(PeriodRules.endsAt("daily", day - 1) == MON_09_0000 - 1, "dia anterior acaba antes da meia-noite")
		local week = RankRules.weekIndex(MON_09_0000)
		assert(PeriodRules.endsAt("weekly", week) == RankRules.weekEnd(week), "semanal = fim da semana do ranking")
	end,
}
