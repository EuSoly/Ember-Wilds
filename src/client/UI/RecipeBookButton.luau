--!strict
-- Botão do livro de receitas, ao lado da engrenagem de configurações.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Theme = require(Shared:WaitForChild("Theme"))
local RecipeBookScreen = require(script.Parent.Parent:WaitForChild("Screens"):WaitForChild("RecipeBookScreen"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local create = vide.create

local function RecipeBookButton(): TextButton
	return create("TextButton")({
		Name = "RecipeBookButton",
		Text = "",
		AutoButtonColor = true,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.89, 0.25),
		Size = UDim2.fromScale(0.08, 0.08),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = Theme.ui.panel,
		BackgroundTransparency = Theme.panelTransparency,
		BorderSizePixel = 0,
		create("UISizeConstraint")({ MinSize = Theme.touchMinSize, MaxSize = Vector2.new(64, 64) }),
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		create("UIStroke")({ Color = Theme.ui.border, Thickness = Theme.strokeThickness }),
		Activated = RecipeBookScreen.toggle,
		Kit.text({
			Size = UDim2.fromScale(0.7, 0.7),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = "▤",
			FontFace = Theme.font.number,
			maxSize = 28,
		}),
	}) :: TextButton
end

return RecipeBookButton
