--!strict
-- Liga os sistemas que rodam dentro da simulação do Server Authority, no servidor.
-- O servidor simula todos os jogadores e é a autoridade final.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FacingSim = require(ReplicatedStorage.Shared.Simulation.FacingSim)

local SimulationService = {}

function SimulationService.Start(_self)
	FacingSim.start(function()
		return Players:GetPlayers()
	end)
end

return SimulationService
