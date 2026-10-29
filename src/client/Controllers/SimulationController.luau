--!strict
-- Liga os sistemas de simulação no cliente. O cliente simula só o próprio
-- personagem (predição): a resposta é imediata e o servidor confirma depois.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local FacingSim = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Simulation"):WaitForChild("FacingSim"))

local SimulationController = {}

function SimulationController.Start(_self)
	local localPlayer = Players.LocalPlayer
	FacingSim.start(function()
		return { localPlayer }
	end)
end

return SimulationController
