--!strict
-- Liga os sistemas que rodam dentro da simulação do Server Authority, no servidor.
-- O servidor simula todos os jogadores e é a autoridade final.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FacingSim = require(ReplicatedStorage.Shared.Simulation.FacingSim)
local UseSim = require(ReplicatedStorage.Shared.Simulation.UseSim)

local SimulationService = {}

function SimulationService.Start(_self)
	local function allPlayers()
		return Players:GetPlayers()
	end
	FacingSim.start(allPlayers)
	UseSim.start(allPlayers)
end

return SimulationService
