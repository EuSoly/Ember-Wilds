--!strict
-- Pontos e ranking (G2): dono dos atributos Score (pontos da vida atual) e
-- Rank (posição no servidor) do Player. Quem ganha pontos chama add (hoje a
-- coleta). O LifeService converte o Score em Golden Ember no fim da vida e o
-- zera. O Rank é recalculado a cada RANK_EVERY só entre quem está vivo; quem
-- está no menu fica sem posição (atributo nil).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Ranking = require(ReplicatedStorage.Shared.Gather.Ranking)
local StatNames = require(ReplicatedStorage.Shared.StatNames)

local RANK_EVERY = 1 -- segundos

local ScoreService = {}

-- Ordem de chegada no servidor (desempate do ranking).
local joinOrder: { [Player]: number } = {}
local nextOrder = 0

local function scoreOf(player: Player): number
	local score = player:GetAttribute(StatNames.Score)
	return if type(score) == "number" and score == score then score else 0
end

-- Soma pontos na vida atual.
function ScoreService.add(player: Player, points: number)
	if not (points > 0) then
		return
	end
	player:SetAttribute(StatNames.Score, scoreOf(player) + points)
end

local function isAlive(player: Player): boolean
	local character = player.Character
	return character ~= nil and character:FindFirstChildOfClass("Humanoid") ~= nil
end

local function updateRanks()
	local entries: { Ranking.Entry } = {}
	local byId: { [number]: Player } = {}
	for _, player in Players:GetPlayers() do
		if isAlive(player) then
			table.insert(entries, { id = player.UserId, score = scoreOf(player), order = joinOrder[player] or 0 })
			byId[player.UserId] = player
		elseif player:GetAttribute(StatNames.Rank) ~= nil then
			player:SetAttribute(StatNames.Rank, nil)
		end
	end
	for id, rank in Ranking.compute(entries) do
		local player = byId[id]
		if player:GetAttribute(StatNames.Rank) ~= rank then
			player:SetAttribute(StatNames.Rank, rank)
		end
	end
end

local function onJoin(player: Player)
	nextOrder += 1
	joinOrder[player] = nextOrder
end

function ScoreService.Start(_self)
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(function(player)
		joinOrder[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		onJoin(player)
	end
	task.spawn(function()
		while true do
			task.wait(RANK_EVERY)
			updateRanks()
		end
	end)
end

return ScoreService
