--!strict
-- Botão de configurações (canto superior direito, abaixo do minimapa): o
-- botão redondo de madeira com a engrenagem; abre e fecha as configurações.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudImages = require(Shared:WaitForChild("HudImages"))
local Theme = require(Shared:WaitForChild("Theme"))
local SettingsScreen = require(script.Parent.Parent:WaitForChild("Screens"):WaitForChild("SettingsScreen"))
local CornerLayout = require(script.Parent:WaitForChild("CornerLayout"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))

local function SettingsButton(): TextButton
	return HudArt.roundButton({
		Name = "SettingsButton",
		icon = HudImages.ICON.settings,
		fallback = "⚙",
		AnchorPoint = Vector2.new(1, 0),
		-- Embaixo do minimapa, na borda direita dele (CornerLayout).
		Position = function()
			return CornerLayout.buttonPosition(false)
		end,
		Size = CornerLayout.buttonSize,
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		minSize = Theme.touchMinSize,
		maxSize = Vector2.new(68, 68),
		Activated = SettingsScreen.toggle,
	})
end

return SettingsButton
