--!strict
-- Botão do livro de receitas (ao lado do de configurações): o botão redondo
-- de madeira com o livro verde; abre e fecha o livro completo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local HudImages = require(Shared:WaitForChild("HudImages"))
local Theme = require(Shared:WaitForChild("Theme"))
local RecipeBookScreen = require(script.Parent.Parent:WaitForChild("Screens"):WaitForChild("RecipeBookScreen"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))

local function RecipeBookButton(): TextButton
	return HudArt.roundButton({
		Name = "RecipeBookButton",
		icon = HudImages.ICON.book,
		fallback = "▤",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.885, 0.25),
		Size = UDim2.fromScale(0.09, 0.09),
		minSize = Theme.touchMinSize,
		maxSize = Vector2.new(68, 68),
		Activated = RecipeBookScreen.toggle,
	})
end

return RecipeBookButton
