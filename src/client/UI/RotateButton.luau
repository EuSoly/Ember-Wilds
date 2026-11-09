--!strict
-- Botão de girar a peça (só no celular, só com peça colocável na mão).
-- Fica logo acima do joystick direito; cada toque gira 45 graus (a tecla R
-- faz o mesmo no PC).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudImages = require(Shared:WaitForChild("HudImages"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local BuildRotation = require(script.Parent.Parent:WaitForChild("BuildRotation"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local Sources = require(script.Parent:WaitForChild("Sources"))

local function RotateButton(): TextButton
	local isTouch = Sources.isTouch()
	return HudArt.roundButton({
		Name = "RotateButton",
		icon = HudImages.ICON.rotate,
		fallback = Strings.get("hud.rotate"),
		Visible = function()
			return isTouch() and BuildRotation.placing()
		end,
		-- Entre o botão da mochila e o joystick direito.
		Position = UDim2.fromScale(0.88, 0.5),
		Size = UDim2.fromScale(0.1, 0.1),
		minSize = Theme.touchMinSize + Vector2.new(12, 12),
		maxSize = Vector2.new(76, 76),
		Activated = BuildRotation.rotate,
	})
end

return RotateButton
