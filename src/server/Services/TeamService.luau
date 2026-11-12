--!strict
-- Times pelo totem (TeamRules; docs/guia/times.md). Colocar um totem cria o time
-- do dono (líder). Perto de um totem (TeamRules.TOTEM_RADIUS além do raio dele),
-- quem não tem time entra (TeamJoin) se houver vaga e não estiver trancado; o
-- líder tranca (TeamLock) e expulsa (TeamKick) perto do próprio totem; qualquer
-- membro sai (TeamLeave). Quem sai ou é expulso espera REJOIN_WAIT. O líder sair
-- desfaz o time (fica só ele); o totem sair do mundo (destruído, dono morreu ou
-- saiu) acaba com o time. O time resolve os aliados (BuildRules.setTeamResolver):
-- portas, baús, espinhos, máquinas e o golpe de colega (30%, CharacterService).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BuildRules = require(ReplicatedStorage.Shared.Build.BuildRules)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local TeamRules = require(ReplicatedStorage.Shared.Build.TeamRules)
local StructureService = require(script.Parent.StructureService)
local Net = require(script.Parent.Parent.Net)

local KIND = "totem"

local TeamService = {}

local teams: { [number]: TeamRules.Team } = {} -- por UserId do líder
local leaderOf: { [number]: number } = {} -- UserId → UserId do líder
local totemOf: { [number]: StructureService.Entry } = {} -- líder → totem
local waitUntil: { [number]: number } = {}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function playerById(userId: number): Player?
	return Players:GetPlayerByUserId(userId)
end

local function setMember(userId: number, leader: number?)
	if leader then
		leaderOf[userId] = leader
	else
		leaderOf[userId] = nil
	end
	local player = playerById(userId)
	if player then
		player:SetAttribute(StatNames.Team, leader)
	end
end

local function publish(leader: number)
	local team, totem = teams[leader], totemOf[leader]
	if team and totem then
		totem.model:SetAttribute(StatNames.TeamLeader, leader)
		totem.model:SetAttribute(StatNames.TeamLocked, team.locked)
		totem.model:SetAttribute(StatNames.TeamSize, #team.members)
	end
end

-- Tira todos os membros (menos o líder). keepLeader = o líder segue com o totem.
local function dissolve(leader: number, keepLeader: boolean)
	local team = teams[leader]
	if team == nil then
		return
	end
	local t = now()
	for _, member in team.members do
		if member ~= leader then
			setMember(member, nil)
			waitUntil[member] = t + TeamRules.REJOIN_WAIT
		end
	end
	if keepLeader then
		team.members = { leader }
		team.locked = false
		publish(leader)
	else
		setMember(leader, nil)
		teams[leader] = nil
		totemOf[leader] = nil
	end
end

local function nearTotem(player: Player, leader: number): boolean
	local totem = totemOf[leader]
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if totem == nil or root == nil or not root:IsA("BasePart") then
		return false
	end
	local d = math.sqrt((totem.x - root.Position.X) ^ 2 + (totem.z - root.Position.Z) ^ 2) - totem.radius
	return d <= TeamRules.TOTEM_RADIUS
end

local function onJoin(player: Player, data: { Leader: number })
	local uid, leader = player.UserId, data.Leader
	local team = teams[leader]
	if team == nil or leaderOf[uid] ~= nil or not nearTotem(player, leader) then
		return
	end
	if not TeamRules.canJoin(team, uid, now(), waitUntil[uid]) then
		return
	end
	table.insert(team.members, uid)
	setMember(uid, leader)
	publish(leader)
end

local function onLeave(player: Player)
	local uid = player.UserId
	local leader = leaderOf[uid]
	local team = leader and teams[leader]
	if leader == nil or team == nil then
		return
	end
	if TeamRules.leave(team, uid) then
		dissolve(leader, true)
	else
		setMember(uid, nil)
		waitUntil[uid] = now() + TeamRules.REJOIN_WAIT
		publish(leader)
	end
end

local function onKick(player: Player, data: { UserId: number })
	local leader = player.UserId
	local team = teams[leader]
	if team == nil or not nearTotem(player, leader) or not TeamRules.canKick(team, leader, data.UserId) then
		return
	end
	TeamRules.leave(team, data.UserId)
	setMember(data.UserId, nil)
	waitUntil[data.UserId] = now() + TeamRules.REJOIN_WAIT
	publish(leader)
end

local function onLock(player: Player)
	local leader = player.UserId
	local team = teams[leader]
	if team == nil or not nearTotem(player, leader) then
		return
	end
	team.locked = not team.locked
	publish(leader)
end

-- Quantos estão no time do jogador (ele incluso); 0 sem time. "Sozinho" nas
-- chrono quests = menos de 2.
function TeamService.sizeOf(player: Player): number
	local leader = leaderOf[player.UserId]
	local team = if leader then teams[leader] else nil
	return if team then #team.members else 0
end

function TeamService.Start(_self)
	BuildRules.setTeamResolver(function(userId: number): number?
		return leaderOf[userId]
	end)
	StructureService.onCreated(function(entry)
		if entry.def.kind ~= KIND then
			return
		end
		local leader = entry.owner.UserId
		-- Já num time (o place recusa; por segurança, sai do outro antes).
		if leaderOf[leader] ~= nil and leaderOf[leader] ~= leader then
			onLeave(entry.owner)
		end
		teams[leader] = { leader = leader, members = { leader }, locked = false }
		totemOf[leader] = entry
		setMember(leader, leader)
		publish(leader)
	end)
	StructureService.onRemoved(function(entry)
		if entry.def.kind == KIND and totemOf[entry.owner.UserId] == entry then
			dissolve(entry.owner.UserId, false)
		end
	end)
	Net.TeamJoin.On(onJoin)
	Net.TeamLeave.On(onLeave)
	Net.TeamKick.On(onKick)
	Net.TeamLock.On(onLock)
	Players.PlayerRemoving:Connect(function(player)
		local uid = player.UserId
		local leader = leaderOf[uid]
		local team = leader and teams[leader]
		if team and leader ~= uid then
			TeamRules.leave(team, uid)
			leaderOf[uid] = nil
			publish(leader :: number)
		end
		waitUntil[uid] = nil
	end)
end

return TeamService
