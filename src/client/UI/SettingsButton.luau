--!strict
-- Botão de configurações (canto superior direito, abaixo do minimapa): o
-- botão redondo de madeira com a engrenagem; abre e fecha as configurações.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudImages = require(Shared:WaitForChild("HudImages"))
local Theme = require(Shared:WaitForChild("Theme"))
local SettingsScreen = require(script.Parent.Parent:WaitForChild("Screens"):WaitForChild("SettingsScreen"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))

local function SettingsButton(): TextButton
	return HudArt.roundButton({
		Name = "SettingsButton",
		icon = HudImages.ICON.settings,
		fallback = "⚙",
		AnchorPoint = Vector2.new(1, 0),
		-- O minimapa ocupa de 0.02 até ~0.22 da altura (lado = 0.2 da altura).
		Position = UDim2.fromScale(0.98, 0.25),
		Size = UDim2.fromScale(0.09, 0.09),
		minSize = Theme.touchMinSize,
		maxSize = Vector2.new(68, 68),
		Activated = SettingsScreen.toggle,
	})
end

return SettingsButton
