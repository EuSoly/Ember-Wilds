--!strict
-- Conteúdo do painel Tutorial (mockup G7a): passos numerados, um por linha,
-- numa lista que rola.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Kit = require(Client:WaitForChild("UI"):WaitForChild("Kit"))

local create = vide.create

local CANVAS_H = 1.3 -- altura do canvas em "janelas"; as linhas dividem por isso
local ROW_H = 0.2
local ROW_GAP = 0.03

local TutorialPanel = {}

function TutorialPanel.build(): Frame
	local rows: { Instance } = {
		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(ROW_GAP / CANVAS_H, 0),
		}) :: Instance,
	}
	for number, key in MockStore.TUTORIAL do
		table.insert(
			rows,
			create("Frame")({
				Name = "Step_" .. number,
				LayoutOrder = number,
				Size = UDim2.fromScale(1, ROW_H / CANVAS_H),
				BackgroundColor3 = Theme.ui.panelRaised,
				BorderSizePixel = 0,
				create("UICorner")({ CornerRadius = Theme.corner }),
				Kit.text({
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					Size = UDim2.fromScale(0.94, 0.8),
					FontFace = Theme.font.body,
					Text = Strings.format("mock.step", { number = number, text = Strings.get(key) }),
					TextXAlignment = Enum.TextXAlignment.Left,
					TextWrapped = true,
					maxSize = 22,
				}),
			})
		)
	end
	return create("Frame")({
		Name = "Tutorial",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.02, 0.15),
		Size = UDim2.fromScale(0.96, 0.82),
		create("ScrollingFrame")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			CanvasSize = UDim2.fromScale(0, CANVAS_H),
			ScrollingDirection = Enum.ScrollingDirection.Y,
			rows,
		}),
	}) :: Frame
end

return TutorialPanel
