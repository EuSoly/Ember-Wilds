--!strict
-- Botão de engrenagem da HUD (canto superior direito, abaixo do minimapa):
-- abre e fecha a janela de configurações (Screens/SettingsScreen).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Theme = require(Shared:WaitForChild("Theme"))
local SettingsScreen = require(script.Parent.Parent:WaitForChild("Screens"):WaitForChild("SettingsScreen"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local create = vide.create

local GEAR = "⚙"

local function SettingsButton(): TextButton
	return create("TextButton")({
		Name = "SettingsButton",
		Text = "",
		AutoButtonColor = true,
		AnchorPoint = Vector2.new(1, 0),
		-- O minimapa ocupa de 0.02 até ~0.22 da altura (lado = 0.2 da altura).
		Position = UDim2.fromScale(0.98, 0.25),
		Size = UDim2.fromScale(0.08, 0.08),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = Theme.ui.panel,
		BackgroundTransparency = Theme.panelTransparency,
		BorderSizePixel = 0,
		create("UISizeConstraint")({ MinSize = Theme.touchMinSize, MaxSize = Vector2.new(64, 64) }),
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		create("UIStroke")({
			Color = Theme.ui.border,
			Thickness = Theme.strokeThickness,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Activated = SettingsScreen.toggle,
		Kit.text({
			Size = UDim2.fromScale(0.7, 0.7),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Theme.font.number,
			Text = GEAR,
			maxSize = 32,
		}),
	}) :: TextButton
end

return SettingsButton
