--!strict
-- Pontos da vida atual e posição no ranking do servidor (canto superior esquerdo).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Sources = require(script.Parent:WaitForChild("Sources"))

local create = vide.create

local function ScorePill(): Frame
	local player = Players.LocalPlayer
	local score = Sources.attribute(player, StatNames.Score, 0)
	local rank = Sources.attribute(player, StatNames.Rank, 0)

	return Kit.pill({
		Name = "ScorePill",
		Position = UDim2.fromScale(0.02, 0.02),
		Size = UDim2.fromScale(0.2, 0.065),
		create("UIAspectRatioConstraint")({ AspectRatio = 4 }),
		text = function()
			return `{Strings.format("hud.points", { points = score() })} · {Strings.format(
				"hud.rank",
				{ rank = rank() }
			)}`
		end,
	})
end

return ScorePill
