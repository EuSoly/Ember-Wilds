--!strict
-- SÓ PARA DESENVOLVIMENTO (roda apenas no Studio).
-- Põe pontos e posição no ranking falsos em quem entra, para o HUD ter o que
-- mostrar até a pontuação existir (fase de gameplay). As barras de status são
-- do SurvivalService desde a G1.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StatNames = require(ReplicatedStorage.Shared.StatNames)

local INITIAL: { [string]: number } = {
	[StatNames.Score] = 1240,
	[StatNames.Rank] = 3,
}

local DevStatsService = {}

local function setup(player: Player)
	for name, value in INITIAL do
		player:SetAttribute(name, value)
	end
end

function DevStatsService.Start(_self)
	if not RunService:IsStudio() then
		return
	end
	Players.PlayerAdded:Connect(setup)
	for _, player in Players:GetPlayers() do
		setup(player)
	end
end

return DevStatsService
