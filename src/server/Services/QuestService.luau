--!strict
-- Chrono quests (aba Partida das Missões; docs/guia/missoes.md). Valem só na
-- vida atual e não salvam: começam quando a vida começa (LifeService.onStarted)
-- e somem quando ela acaba. As regras são puras (Shared/Missions/ChronoRules);
-- aqui ficam o estado por jogador e os vigias:
--   - unhurt: a vida baixou (CharacterService.onHealthLost);
--   - peaceful: acertou um jogador (onPlayerAttacked), acertou um mob manso ou
--     neutro (MobService.onHit; até para se defender) ou pôs um espinho;
--   - alone: está num time de 2 ou mais (TeamService.sizeOf, 1 Hz).
-- O prazo anda pelo tempo da vida (LifeService.lifeSeconds). Resgate pede
-- espaço no inventário para o item; os pontos entram na vida (ScoreService).
-- Modo criativo: sem quests.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local Defs = require(Shared.Defs)
local LifeRules = require(Shared.Data.LifeRules)
local ChronoRules = require(Shared.Missions.ChronoRules)
local CharacterService = require(script.Parent.CharacterService)
local CreativeService = require(script.Parent.CreativeService)
local GhostService = require(script.Parent.GhostService)
local InventoryService = require(script.Parent.InventoryService)
local LifeService = require(script.Parent.LifeService)
local MissionService = require(script.Parent.MissionService)
local MobService = require(script.Parent.MobService)
local ScoreService = require(script.Parent.ScoreService)
local StatsService = require(script.Parent.StatsService)
local StructureService = require(script.Parent.StructureService)
local TeamService = require(script.Parent.TeamService)
local Net = require(script.Parent.Parent.Net)

local KIND_CHRONO = 1
local STATE_OF: { [ChronoRules.Status]: number } = { active = 0, done = 1, claimed = 2, failed = 3 }
local TICK_SECONDS = 1

local QuestService = {}

local states: { [Player]: ChronoRules.ChronoState } = {}

local function notice(player: Player, id: string, done: boolean)
	Net.MissionNotice.Fire(player, { Kind = KIND_CHRONO, Id = id, Done = done })
end

local function fail(player: Player?, rule: ChronoRules.WatchedRule)
	local state = if player then states[player] else nil
	if player == nil or state == nil then
		return
	end
	local failed = ChronoRules.breakRule(state, Defs, rule)
	if #failed == 0 then
		return
	end
	for _, id in failed do
		notice(player, id, false)
	end
	MissionService.publish(player)
end

local function lifeSecondsOf(player: Player): number
	return LifeService.lifeSeconds(player) or 0
end

-- Cartões da aba Partida, do prazo mais curto para o mais longo.
local function cards(player: Player): { MissionService.MissionCard }
	local state = states[player]
	if state == nil then
		return {}
	end
	local seconds = lifeSecondsOf(player)
	local now = Workspace:GetServerTimeNow()
	local list: { MissionService.MissionCard } = {}
	for id, quest in state do
		local def = Defs.Quests[id]
		local total = ChronoRules.secondsLeft(def, 0) -- o prazo inteiro
		table.insert(list, {
			Id = id,
			Progress = math.floor(math.min(seconds, total)),
			Target = math.floor(total),
			State = STATE_OF[quest.status],
			EndsAt = now + ChronoRules.secondsLeft(def, seconds),
		})
	end
	table.sort(list, function(a, b)
		if a.Target ~= b.Target then
			return a.Target < b.Target
		end
		return a.Id < b.Id
	end)
	return list
end

local function claim(player: Player, id: string)
	local state = states[player]
	local def = Defs.Quests[id]
	if state == nil or def == nil then
		return
	end
	local hasSpace = InventoryService.spaceFor(player, def.rewardItem) >= def.rewardCount
	local claimed, problem = ChronoRules.claim(state, Defs, id, hasSpace)
	if problem ~= nil then
		notice(player, "inventory_full", false)
		return
	end
	if claimed == nil then
		return
	end
	local rest = InventoryService.give(player, claimed.rewardItem, claimed.rewardCount)
	if rest > 0 then
		warn(`[QuestService] {player.Name}: {rest}× {claimed.rewardItem} da quest {id} não couberam`)
	end
	if claimed.score > 0 then
		ScoreService.add(player, claimed.score)
	end
	StatsService.add(player, "chrono_completed", 1)
	MissionService.publish(player)
end

-- Studio (DevMissions complete 1 <id>): termina uma quest em andamento.
local function devComplete(player: Player, id: string): boolean
	local quest = states[player] and states[player][id]
	if quest == nil or quest.status ~= "active" then
		return false
	end
	quest.status = "done"
	notice(player, id, true)
	MissionService.publish(player)
	return true
end

local function startLife(player: Player)
	if CreativeService.isOn(player) then
		states[player] = nil
		return
	end
	states[player] = ChronoRules.start(Defs)
	MissionService.publish(player)
end

local function endLife(player: Player)
	states[player] = nil
	MissionService.publish(player)
end

local function tick(player: Player)
	local state = states[player]
	if state == nil then
		return
	end
	if TeamService.sizeOf(player) >= 2 then
		fail(player, "alone")
	end
	local done = ChronoRules.tick(state, Defs, lifeSecondsOf(player))
	if #done > 0 then
		for _, id in done do
			notice(player, id, true)
		end
		MissionService.publish(player)
	end
end

function QuestService.Start(_self)
	MissionService.setChrono({
		cards = cards,
		lifeDay = function(player: Player): number
			return LifeRules.daysSurvived(lifeSecondsOf(player)) + 1
		end,
		claim = claim,
		complete = devComplete,
		dump = function(player: Player): any
			return states[player]
		end,
	})
	LifeService.onStarted(startLife)
	LifeService.onEnded(endLife)
	CharacterService.onHealthLost(function(player)
		fail(player, "unhurt")
	end)
	CharacterService.onPlayerAttacked(function(attacker)
		fail(attacker, "peaceful")
	end)
	MobService.onHit(function(mob, attacker)
		local def = Defs.Mobs[mob.id]
		if def and ChronoRules.isPeacefulTarget(def.behavior) then
			fail(attacker, "peaceful")
		end
	end)
	-- Virou fantasma: perdeu a vida (mesmo podendo ressuscitar).
	GhostService.onGhost(function(player)
		local state = states[player]
		if state == nil then
			return
		end
		local failed = ChronoRules.failAll(state)
		for _, id in failed do
			notice(player, id, false)
		end
		if #failed > 0 then
			MissionService.publish(player)
		end
	end)
	StructureService.onCreated(function(entry)
		if entry.def.kind == "spike" then
			fail(entry.owner, "peaceful")
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)
	-- Vida que começou antes deste Start (LifeService começa antes, Play Solo).
	for _, player in Players:GetPlayers() do
		if states[player] == nil and LifeService.lifeSeconds(player) ~= nil then
			startLife(player)
		end
	end
	task.spawn(function()
		while true do
			task.wait(TICK_SECONDS)
			for player in states do
				local ok, err = pcall(function()
					tick(player)
				end)
				if not ok then
					warn(`[QuestService] {player.Name}: {err}`)
				end
			end
		end
	end)
end

return QuestService
