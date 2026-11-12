--!strict
-- Missões salvas no perfil: diárias, semanais e conquistas (docs/guia/missoes.md).
-- As regras ficam em Shared/Missions (puras). Este serviço:
--   - sorteia e vira o período (meia-noite / domingo 23:59:59 de Brasília);
--   - lê o progresso das estatísticas (StatsService) e da vida atual;
--   - manda o retrato completo só para o dono (Net.MissionsData), com a aba
--     Partida vinda do QuestService (setChrono);
--   - entrega os prêmios do RESGATAR por ShopService.give (fora do teto de
--     Golden Ember por hora) e avisa o que ficou pronto (Net.MissionNotice).
-- Modo criativo: nada conta e nada se resgata.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Defs = require(Shared.Defs)
local StatNames = require(Shared.StatNames)
local LifeRules = require(Shared.Data.LifeRules)
local Throttle = require(Shared.Shop.Throttle)
local MissionConfig = require(Shared.Missions.MissionConfig)
local MissionData = require(Shared.Missions.MissionData)
local PeriodRules = require(Shared.Missions.PeriodRules)
local AchievementRules = require(Shared.Missions.AchievementRules)
local MissionRewards = require(Shared.Missions.MissionRewards)
local CosmeticService = require(script.Parent.CosmeticService)
local CreativeService = require(script.Parent.CreativeService)
local DataService = require(script.Parent.DataService)
local LifeService = require(script.Parent.LifeService)
local ShopService = require(script.Parent.ShopService)
local StatsService = require(script.Parent.StatsService)
local Net = require(script.Parent.Parent.Net)

type MissionsSave = MissionData.MissionsSave
type PeriodSave = MissionData.PeriodSave
type Period = PeriodRules.Period
type Reward = Defs.MissionReward

export type MissionCard = { Id: string, Progress: number, Target: number, State: number, EndsAt: number }

-- O que o QuestService (Partida) fornece. Ele se registra no Start dele.
export type ChronoHooks = {
	cards: (player: Player) -> { MissionCard },
	lifeDay: (player: Player) -> number,
	claim: (player: Player, id: string) -> (),
	complete: (player: Player, id: string) -> boolean,
	dump: (player: Player) -> any,
}

local STATE_ACTIVE, STATE_READY, STATE_CLAIMED, STATE_LOCKED = 0, 1, 2, 4
local KIND_CHRONO, KIND_DAILY, KIND_WEEKLY, KIND_ACHIEVEMENT = 1, 2, 3, 4
local TICK_SECONDS = 1

local MissionService = {}

local throttle = Throttle.new(MissionConfig.CLAIM_COOLDOWN)
local chrono: ChronoHooks? = nil
local dirty: { [Player]: boolean } = {}
-- O que já estava pronto na última conta (para avisar só o que ficou pronto agora).
local readySeen: { [Player]: { [string]: boolean } } = {}
-- Só no Studio (DevMissions nextDay/nextWeek): dias e semanas a mais.
local devOffset: { [Player]: { daily: number, weekly: number } } = {}
-- Dias e pontos da vida na última volta do laço (publica quando mudam).
local lastLife: { [Player]: string } = {}
-- Janela aberta (Net.WatchMissions)? Fechada, o retrato só vai quando muda o
-- que aparece sem abrir: bolinhas, estados e o sorteio (não a contagem).
local watching: { [Player]: boolean } = {}
local lastSignature: { [Player]: string } = {}

local function missionsOf(player: Player): MissionsSave?
	local data = DataService.data(player)
	if data == nil then
		return nil
	end
	if type(data.Missions) ~= "table" then
		data.Missions = MissionData.empty()
	end
	return data.Missions
end

local function readerOf(player: Player): (Defs.MissionTrack) -> number
	local data = DataService.data(player)
	return MissionData.statReader(if data then data.Stats else {}, Defs)
end

-- Valor da vida atual: dias completos vividos ou pontos (0 sem vida).
local function lifeValueOf(player: Player): (string) -> number
	return function(life: string): number
		local seconds = LifeService.lifeSeconds(player)
		if seconds == nil then
			return 0
		end
		if life == "days" then
			return LifeRules.daysSurvived(seconds)
		end
		local score = player:GetAttribute(StatNames.Score)
		return if type(score) == "number" and score == score and score >= 0 then score else 0
	end
end

local function indexOf(player: Player, period: Period): number
	local offset = devOffset[player]
	local extra = if offset then offset[period] else 0
	return PeriodRules.indexAt(period, os.time()) + extra
end

local function periodSave(save: MissionsSave, period: Period): PeriodSave
	return if period == "daily" then save.Daily else save.Weekly
end

-- Sorteia/vira os dois períodos se precisar. Devolve true se algo mudou.
local function ensurePeriods(player: Player, save: MissionsSave): boolean
	local read = readerOf(player)
	local lifeValue, lifeKey = lifeValueOf(player), LifeService.lifeKey(player)
	local changed = false
	for _, period: Period in { "daily", "weekly" } :: { Period } do
		local target = periodSave(save, period)
		if
			PeriodRules.ensure(target, period, indexOf(player, period), player.UserId, read, Defs, lifeValue, lifeKey)
		then
			changed = true
		end
	end
	return changed
end

local function periodCards(player: Player, save: PeriodSave, period: Period): ({ MissionCard }, MissionCard)
	local read, lifeValue = readerOf(player), lifeValueOf(player)
	local lifeKey = LifeService.lifeKey(player)
	local endsAt = PeriodRules.endsAt(period, save.Index)
	local cards: { MissionCard } = {}
	for _, slot in save.Slots do
		local def = Defs.Missions[slot.Id]
		local state = if slot.Claimed
			then STATE_CLAIMED
			elseif PeriodRules.isReady(slot, def, read, lifeValue, lifeKey) then STATE_READY
			else STATE_ACTIVE
		table.insert(cards, {
			Id = slot.Id,
			Progress = PeriodRules.progress(slot, def, read, lifeValue, lifeKey),
			Target = def.target,
			State = state,
			EndsAt = endsAt,
		})
	end
	local finalState = if save.FinalClaimed
		then STATE_CLAIMED
		elseif PeriodRules.finalReady(save) then STATE_READY
		else STATE_LOCKED
	local final = {
		Id = "final",
		Progress = PeriodRules.claimedCount(save),
		Target = #save.Slots,
		State = finalState,
		EndsAt = endsAt,
	}
	return cards, final
end

local function achievementCards(player: Player, save: MissionsSave): { any }
	local read, lifeValue = readerOf(player), lifeValueOf(player)
	local list = {}
	for _, def in Defs.Achievements do
		local claimed = save.Achievements[def.id] or 0
		local progress = AchievementRules.progress(def, read, lifeValue)
		table.insert(list, {
			order = def.order,
			card = {
				Id = def.id,
				Progress = math.min(progress, 2 ^ 32 - 1),
				Claimed = claimed,
				Ready = AchievementRules.claimable(def, claimed, progress) ~= nil,
				Soon = AchievementRules.isSoon(def, claimed),
			},
		})
	end
	table.sort(list, function(a, b)
		return a.order < b.order
	end)
	local cards = {}
	for _, entry in list do
		table.insert(cards, entry.card)
	end
	return cards
end

local function emptyFinal(): MissionCard
	return { Id = "final", Progress = 0, Target = 0, State = STATE_LOCKED, EndsAt = 0 }
end

-- Avisa (faixa no topo) o que ficou pronto desde a última conta. `quiet` =
-- só anota (primeira conta depois de entrar: o que já estava pronto não avisa).
local function noticeReady(player: Player, snapshot: any, quiet: boolean)
	local seen = readySeen[player] or {}
	local now: { [string]: boolean } = {}
	local function check(kind: number, key: string, id: string, ready: boolean)
		if not ready then
			return
		end
		now[key] = true
		if not quiet and not seen[key] then
			Net.MissionNotice.Fire(player, { Kind = kind, Id = id, Done = true })
		end
	end
	for _, card in snapshot.Daily do
		check(KIND_DAILY, "d:" .. card.Id, card.Id, card.State == STATE_READY)
	end
	check(KIND_DAILY, "d:final", "final", snapshot.DailyFinal.State == STATE_READY)
	for _, card in snapshot.Weekly do
		check(KIND_WEEKLY, "w:" .. card.Id, card.Id, card.State == STATE_READY)
	end
	check(KIND_WEEKLY, "w:final", "final", snapshot.WeeklyFinal.State == STATE_READY)
	for _, card in snapshot.Achievements do
		check(KIND_ACHIEVEMENT, `a:{card.Id}:{card.Claimed}`, card.Id, card.Ready)
	end
	readySeen[player] = now
end

local function snapshotOf(player: Player): any?
	local save = missionsOf(player)
	if save == nil then
		return nil
	end
	local inLife = LifeService.lifeSeconds(player) ~= nil
	-- Guarda a melhor vida antes de contar: o que aparece pronto já está salvo.
	if inLife and not CreativeService.isOn(player) then
		local lifeValue, lifeKey = lifeValueOf(player), LifeService.lifeKey(player)
		PeriodRules.observeLife(save.Daily, Defs, lifeValue, lifeKey)
		PeriodRules.observeLife(save.Weekly, Defs, lifeValue, lifeKey)
	end
	if CreativeService.isOn(player) then
		return {
			Creative = true,
			InLife = inLife,
			Chrono = {},
			LifeDay = 0,
			Daily = {},
			DailyFinal = emptyFinal(),
			Weekly = {},
			WeeklyFinal = emptyFinal(),
			Achievements = {},
		}
	end
	local daily, dailyFinal = periodCards(player, save.Daily, "daily")
	local weekly, weeklyFinal = periodCards(player, save.Weekly, "weekly")
	return {
		Creative = false,
		InLife = inLife,
		Chrono = if chrono and inLife then chrono.cards(player) else {},
		LifeDay = if chrono and inLife then math.min(chrono.lifeDay(player), 65535) else 0,
		Daily = daily,
		DailyFinal = dailyFinal,
		Weekly = weekly,
		WeeklyFinal = weeklyFinal,
		Achievements = achievementCards(player, save),
	}
end

-- O que muda o que aparece com a janela fechada (bolinhas, estados, sorteio).
local function signatureOf(snapshot: any): string
	local parts = { tostring(snapshot.Creative), tostring(snapshot.InLife) }
	for _, list in { snapshot.Chrono, snapshot.Daily, snapshot.Weekly, { snapshot.DailyFinal, snapshot.WeeklyFinal } } do
		for _, card in list do
			table.insert(parts, `{card.Id}:{card.State}`)
		end
	end
	for _, card in snapshot.Achievements do
		table.insert(parts, `{card.Id}:{card.Claimed}:{card.Ready}`)
	end
	return table.concat(parts, "|")
end

-- Manda o retrato para o dono (e avisa o que ficou pronto). Com a janela
-- fechada, só quando muda o que aparece sem abrir; `force` manda sempre.
function MissionService.publish(player: Player, force: boolean?)
	local snapshot = snapshotOf(player)
	if snapshot == nil then
		return
	end
	dirty[player] = nil
	noticeReady(player, snapshot, readySeen[player] == nil)
	local signature = signatureOf(snapshot)
	if not force and not watching[player] and lastSignature[player] == signature then
		return
	end
	lastSignature[player] = signature
	Net.MissionsData.Fire(player, snapshot)
end

-- Pede um publish na próxima volta do laço (junta várias mudanças seguidas).
function MissionService.markDirty(player: Player)
	dirty[player] = true
end

-- O QuestService registra a aba Partida.
function MissionService.setChrono(hooks: ChronoHooks)
	chrono = hooks
end

local function give(player: Player, rewards: { Reward }, reason: string)
	local function owns(id: string): boolean
		return CosmeticService.owns(player, id)
	end
	for _, original in rewards do
		-- Skin exclusiva que o jogador já tem vira Golden Ember (spec).
		local reward = MissionRewards.resolve(original, owns)
		local ok, problem = ShopService.give(player, reward :: any, reason)
		if not ok then
			warn(`[MissionService] prêmio de {reason} para {player.Name} não entregue: {problem}`)
		end
	end
end

local function claimPeriod(player: Player, save: MissionsSave, period: Period, id: string)
	local target = periodSave(save, period)
	if id == "final" then
		local rewards = PeriodRules.claimFinal(target, period)
		if rewards then
			give(player, rewards, `mission:{period}_final`)
			if period == "daily" then
				StatsService.add(player, "daily_sets_completed", 1)
			end
		end
		return
	end
	local rewards =
		PeriodRules.claim(target, id, Defs, readerOf(player), lifeValueOf(player), LifeService.lifeKey(player))
	if rewards then
		give(player, rewards, `mission:{id}`)
	end
end

local function onClaim(player: Player, request: { Kind: number, Id: string })
	if not Throttle.allow(throttle, player, "claim", os.clock()) or CreativeService.isOn(player) then
		return
	end
	if request.Kind == KIND_CHRONO then
		if chrono then
			chrono.claim(player, request.Id)
		end
		return
	end
	local save = missionsOf(player)
	if save == nil then
		return
	end
	ensurePeriods(player, save)
	if request.Kind == KIND_DAILY then
		claimPeriod(player, save, "daily", request.Id)
	elseif request.Kind == KIND_WEEKLY then
		claimPeriod(player, save, "weekly", request.Id)
	elseif request.Kind == KIND_ACHIEVEMENT then
		local def = Defs.Achievements[request.Id]
		if def then
			local progress = AchievementRules.progress(def, readerOf(player), lifeValueOf(player))
			local rewards = AchievementRules.claim(save, def, progress)
			if rewards then
				give(player, rewards, `achievement:{def.id}:{save.Achievements[def.id]}`)
			end
		end
	end
	DataService.save(player)
	MissionService.publish(player)
end

-- Uma volta do laço: vira período, guarda a melhor vida e publica se mudou.
local function tick(player: Player)
	local save = missionsOf(player)
	if save == nil or CreativeService.isOn(player) then
		return
	end
	local lifeValue, lifeKey = lifeValueOf(player), LifeService.lifeKey(player)
	local changed = ensurePeriods(player, save)
	if PeriodRules.observeLife(save.Daily, Defs, lifeValue, lifeKey) then
		changed = true
	end
	if PeriodRules.observeLife(save.Weekly, Defs, lifeValue, lifeKey) then
		changed = true
	end
	-- Missões e conquistas de vida (dias, pontos) andam sem estatística mudar.
	local life = `{lifeValue("days")}:{lifeValue("score")}`
	if lastLife[player] ~= life then
		lastLife[player] = life
		changed = true
	end
	if changed or dirty[player] then
		MissionService.publish(player)
	end
end

-- ===== Studio: ServerStorage.DevMissions (DevMissionService) =====

-- Põe uma missão no alvo. kind 1 = Partida (QuestService), 2/3 = diária/semanal.
function MissionService.devComplete(player: Player, kind: number, id: string): boolean
	if kind == KIND_CHRONO then
		return chrono ~= nil and chrono.complete(player, id)
	end
	local save = missionsOf(player)
	if save == nil or (kind ~= KIND_DAILY and kind ~= KIND_WEEKLY) then
		return false
	end
	local target = periodSave(save, if kind == KIND_DAILY then "daily" else "weekly")
	for _, slot in target.Slots do
		if slot.Id == id then
			local def = Defs.Missions[id]
			if def.track.life then
				slot.Best = def.target
			else
				slot.Base = readerOf(player)(def.track) - def.target
			end
			MissionService.publish(player)
			return true
		end
	end
	return false
end

-- Avança o dia ou a semana deste jogador (só no Studio).
function MissionService.devAdvance(player: Player, period: Period)
	local offset = devOffset[player] or { daily = 0, weekly = 0 }
	offset[period] += 1
	devOffset[player] = offset
	tick(player)
end

function MissionService.devReset(player: Player)
	local data = DataService.data(player)
	if data then
		data.Missions = MissionData.empty()
		readySeen[player] = nil
		tick(player)
	end
end

function MissionService.devDump(player: Player): any
	return { saved = missionsOf(player), chrono = if chrono then chrono.dump(player) else nil }
end

function MissionService.Start(_self)
	DataService.onLoaded(function(player, data)
		data.Missions = MissionData.sanitize(data.Missions, Defs)
		readySeen[player] = nil
		ensurePeriods(player, data.Missions)
		MissionService.publish(player)
	end)
	StatsService.onChanged(function(player)
		dirty[player] = true
	end)
	LifeService.onStarted(MissionService.markDirty)
	LifeService.onEnded(MissionService.markDirty)
	Net.ClaimMission.On(onClaim)
	Net.WatchMissions.On(function(player, open)
		watching[player] = open == true
		if open then
			MissionService.publish(player, true)
		end
	end)
	Net.RequestMissions.On(function(player)
		if Throttle.allow(throttle, player, "request", os.clock()) then
			MissionService.publish(player, true)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		dirty[player] = nil
		readySeen[player] = nil
		devOffset[player] = nil
		lastLife[player] = nil
		watching[player] = nil
		lastSignature[player] = nil
		Throttle.forget(throttle, player)
	end)
	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)
			for _, player in Players:GetPlayers() do
				local ok, err = pcall(function()
					tick(player)
				end)
				if not ok then
					warn(`[MissionService] {player.Name}: {err}`)
				end
			end
		end
	end)
end

return MissionService
