--!strict
-- Botão de girar a peça (só no celular, só com peça colocável na mão).
-- Fica logo acima do joystick direito; cada toque gira 45 graus (a tecla R
-- faz o mesmo no PC).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local BuildRotation = require(script.Parent.Parent:WaitForChild("BuildRotation"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Sources = require(script.Parent:WaitForChild("Sources"))

local create = vide.create

local function RotateButton(): TextButton
	local isTouch = Sources.isTouch()
	return create("TextButton")({
		Name = "RotateButton",
		Visible = function()
			return isTouch() and BuildRotation.placing()
		end,
		Text = "",
		AutoButtonColor = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		-- Entre o botão da mochila e o joystick direito.
		Position = UDim2.fromScale(0.88, 0.5),
		Size = UDim2.fromScale(0.09, 0.09),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = Theme.ui.panel,
		BackgroundTransparency = Theme.panelTransparency,
		BorderSizePixel = 0,
		create("UISizeConstraint")({
			MinSize = Theme.touchMinSize + Vector2.new(12, 12),
			MaxSize = Vector2.new(72, 72),
		}),
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		create("UIStroke")({ Color = Theme.ui.border, Thickness = Theme.strokeThickness }),
		Activated = BuildRotation.rotate,
		Kit.text({
			Size = UDim2.fromScale(0.8, 0.4),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = Strings.get("hud.rotate"),
			maxSize = 14,
		}),
	}) :: TextButton
end

return RotateButton
