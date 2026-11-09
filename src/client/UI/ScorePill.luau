--!strict
-- Pontos e posição no ranking do servidor (topo, esquerda): a placa de
-- madeira com a taça do Ranking e "1.240 pts · #3".
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local RankingImages = require(Shared:WaitForChild("RankingImages"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))
local Sources = require(script.Parent:WaitForChild("Sources"))

local create = vide.create

local function ScorePill(): Frame
	local player = Players.LocalPlayer
	local score = Sources.attribute(player, StatNames.Score, 0)
	local rank = Sources.attribute(player, StatNames.Rank, 0)

	return Rustic.plate({
		Name = "ScorePill",
		Position = UDim2.fromScale(0.02, 0.02),
		Size = UDim2.fromScale(0.21, 0.075),
		create("UIAspectRatioConstraint")({ AspectRatio = 4 }),
		create("ImageLabel")({
			Name = "Trophy",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.09, 0.5),
			Size = UDim2.fromScale(0.62, 0.62),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
			Image = RankingImages.TROPHY,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 2,
		}),
		Kit.text({
			Name = "Label",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.27, 0.5),
			Size = UDim2.fromScale(0.66, 0.5),
			FontFace = Theme.font.number,
			TextXAlignment = Enum.TextXAlignment.Left,
			ZIndex = 2,
			Text = function()
				local points = Strings.format("hud.points", { points = score() })
				-- Sem posição (ainda não calculada): só os pontos.
				if rank() <= 0 then
					return points
				end
				return `{points} · {Strings.format("hud.rank", { rank = rank() })}`
			end,
		}),
	}) :: Frame
end

return ScorePill
