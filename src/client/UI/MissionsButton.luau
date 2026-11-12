--!strict
-- Botão das Missões no HUD: redondo de madeira com o pergaminho, embaixo da
-- engrenagem (CornerLayout.secondRowPosition), com a bolinha vermelha dos
-- prêmios esperando o RESGATAR. Abre e fecha a janela (MissionsScreen).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MissionImages = require(Shared:WaitForChild("MissionImages"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local MissionsState = require(Client:WaitForChild("MissionsState"))
local CornerLayout = require(script.Parent:WaitForChild("CornerLayout"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create
local R = Theme.rustic

local function MissionsButton(): TextButton
	local button = HudArt.roundButton({
		Name = "MissionsButton",
		icon = MissionImages.ICON.missao_hud,
		fallback = "!",
		AnchorPoint = Vector2.new(1, 0),
		Position = function()
			return CornerLayout.secondRowPosition()
		end,
		Size = CornerLayout.buttonSize,
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		minSize = Theme.touchMinSize,
		maxSize = Vector2.new(68, 68),
		Activated = MissionsState.toggle,
	})
	local count = function(): number
		return MissionsState.badges().total
	end
	create("Frame")({
		Name = "Dot",
		Parent = button,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.86, 0.14),
		Size = UDim2.fromScale(0.36, 0.36),
		BackgroundColor3 = Color3.fromHex("#E0412F"),
		Visible = function()
			return count() > 0
		end,
		ZIndex = 5,
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		create("UIStroke")({ Color = R.outline, Thickness = 2 }),
		Rustic.label({
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.8),
			FontFace = Theme.font.number,
			Text = function()
				return tostring(count())
			end,
			maxSize = 14,
			ZIndex = 6,
		}),
	})
	return button
end

return MissionsButton
