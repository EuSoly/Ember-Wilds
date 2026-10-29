--!strict
-- SÓ PARA DESENVOLVIMENTO (roda apenas no Studio).
-- Preenche os atributos de status e pontuação com valores falsos que se mexem,
-- para o HUD poder ser construído antes da gameplay existir.
-- Na fase G1 o SurvivalService passa a escrever esses atributos de verdade
-- e este arquivo é apagado.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StatNames = require(ReplicatedStorage.Shared.StatNames)

local INITIAL: { [string]: number } = {
	[StatNames.Health] = 100,
	[StatNames.Hunger] = 80,
	[StatNames.Cold] = 60,
	[StatNames.Thirst] = 30,
	[StatNames.Score] = 1240,
	[StatNames.Rank] = 3,
}
-- Barras que descem 1 por segundo (e voltam a 100 ao zerar).
local DRAINING = { StatNames.Hunger, StatNames.Cold, StatNames.Thirst }
-- Barras de status que voltam ao valor inicial a cada nascimento (até o
-- sistema de sobrevivência existir). A pontuação não: quem a zera é a morte.
local STATUS = { StatNames.Health, StatNames.Hunger, StatNames.Cold, StatNames.Thirst }

local DevStatsService = {}

local function resetStatus(player: Player)
	for _, name in STATUS do
		player:SetAttribute(name, INITIAL[name])
	end
end

local function setup(player: Player)
	for name, value in INITIAL do
		player:SetAttribute(name, value)
	end
	player.CharacterAdded:Connect(function()
		resetStatus(player)
	end)
end

local function tick()
	for _, player in Players:GetPlayers() do
		for _, name in DRAINING do
			local value = (player:GetAttribute(name) :: number?) or StatNames.StatusMax
			player:SetAttribute(name, if value <= 0 then StatNames.StatusMax else value - 1)
		end
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
	task.spawn(function()
		while true do
			task.wait(1)
			tick()
		end
	end)
end

return DevStatsService
