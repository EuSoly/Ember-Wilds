--!strict
-- Monta o HUD (UI/App) no PlayerGui do jogador.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local App = require(script.Parent.Parent:WaitForChild("UI"):WaitForChild("App"))

local HudController = {}

function HudController.Start(_self)
	task.spawn(function()
		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
		vide.mount(App, playerGui)
	end)
end

return HudController
