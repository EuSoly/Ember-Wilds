--!strict
-- Liga os sistemas de simulação no cliente. O cliente simula só o próprio
-- personagem (predição): a resposta é imediata e o servidor confirma depois.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Simulation = ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Simulation")
local FacingSim = require(Simulation:WaitForChild("FacingSim"))
local UseSim = require(Simulation:WaitForChild("UseSim"))
local WaterSim = require(Simulation:WaitForChild("WaterSim"))

local SimulationController = {}

function SimulationController.Start(_self)
	local localPlayer = Players.LocalPlayer
	local function onlyMe()
		return { localPlayer }
	end
	FacingSim.start(onlyMe)
	UseSim.start(onlyMe)
	WaterSim.start(onlyMe)
end

return SimulationController
