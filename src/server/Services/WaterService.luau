--!strict
-- Água fora da simulação: publica para cada jogador o atributo InWater e o
-- fôlego (atributo Oxygen, 0 a StatusMax), lendo o resultado do WaterSim.
-- - Na água, o fôlego cai até zerar em WorldConfig.OXYGEN_EMPTY_SECONDS.
-- - Fora, enche em WorldConfig.OXYGEN_REFILL_SECONDS.
-- - Cada vida nova começa com o fôlego cheio.
-- O dano com o fôlego zerado e a sede enchendo na água são do SurvivalService
-- (que só lê InWater e Oxygen).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatNames = require(ReplicatedStorage.Shared.StatNames)
local WorldConfig = require(ReplicatedStorage.Shared.WorldConfig)
local WaterSim = require(ReplicatedStorage.Shared.Simulation.WaterSim)

local TICK = 0.1 -- segundos (10 vezes por segundo)

local WaterService = {}

-- Grava o valor exato: arredondar a cada passo acumula erro (com passos de
-- 0,25 a barra caía 0,3 por passo, ~18% rápido demais).
local function setIfChanged(player: Player, name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

local function refill(player: Player)
	setIfChanged(player, StatNames.Oxygen, StatNames.StatusMax)
	setIfChanged(player, StatNames.InWater, false)
end

local function step(player: Player, dt: number)
	local wet = WaterSim.isInWater(player)
	setIfChanged(player, StatNames.InWater, wet)

	local current = player:GetAttribute(StatNames.Oxygen)
	local oxygen = if type(current) == "number" then current else StatNames.StatusMax
	local rate = if wet
		then -StatNames.StatusMax / WorldConfig.OXYGEN_EMPTY_SECONDS
		else StatNames.StatusMax / WorldConfig.OXYGEN_REFILL_SECONDS
	oxygen = math.clamp(oxygen + rate * dt, 0, StatNames.StatusMax)
	setIfChanged(player, StatNames.Oxygen, oxygen)
end

local function setupPlayer(player: Player)
	refill(player)
	player.CharacterAdded:Connect(function()
		refill(player)
	end)
end

function WaterService.Start(_self)
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(TICK)
			local now = os.clock()
			local dt = now - last
			last = now
			for _, player in Players:GetPlayers() do
				step(player, dt)
			end
		end
	end)
end

return WaterService
