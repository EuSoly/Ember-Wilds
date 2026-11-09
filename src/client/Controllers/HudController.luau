--!strict
-- Monta o HUD (UI/App) e as bordas de sofrimento (UI/StatusVignette, atrás
-- do HUD) no PlayerGui do jogador.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local UI = script.Parent.Parent:WaitForChild("UI")
local App = require(UI:WaitForChild("App"))
local StatusVignette = require(UI:WaitForChild("StatusVignette"))

local HudController = {}

function HudController.Start(_self)
	task.spawn(function()
		local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
		vide.mount(StatusVignette, playerGui)
		vide.mount(App, playerGui)
	end)
end

return HudController
