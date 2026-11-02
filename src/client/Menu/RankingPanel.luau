--!strict
-- Conteúdo do painel Ranking (mockup G7a): dez linhas numeradas, com o top 3
-- destacado. Os dados vêm do MockStore.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Kit = require(Client:WaitForChild("UI"):WaitForChild("Kit"))

local create = vide.create

local TOP = 3
local CANVAS_H = 1.4 -- altura do canvas em "janelas"; as linhas dividem por isso
local ROW_H = 0.1
local ROW_GAP = 0.015

local function row(position: number, entry: MockStore.RankRow): Frame
	local top = position <= TOP
	return create("Frame")({
		Name = "Row_" .. position,
		LayoutOrder = position,
		Size = UDim2.fromScale(1, ROW_H / CANVAS_H),
		BackgroundColor3 = if top then Theme.ui.action else Theme.ui.panelRaised,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = Theme.corner }),
		Kit.text({
			Name = "Position",
			Position = UDim2.fromScale(0.03, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromScale(0.12, 0.7),
			FontFace = Theme.font.number,
			Text = Strings.format("mock.rank.position", { position = position }),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 22,
		}),
		Kit.text({
			Name = "Name",
			Position = UDim2.fromScale(0.17, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromScale(0.45, 0.7),
			FontFace = if top then Theme.font.number else Theme.font.body,
			Text = entry.name,
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 22,
		}),
		Kit.text({
			Name = "Points",
			Position = UDim2.fromScale(0.97, 0.5),
			AnchorPoint = Vector2.new(1, 0.5),
			Size = UDim2.fromScale(0.3, 0.7),
			FontFace = Theme.font.number,
			Text = Strings.format("mock.rank.points", { points = entry.points }),
			TextXAlignment = Enum.TextXAlignment.Right,
			maxSize = 22,
		}),
	}) :: Frame
end

local RankingPanel = {}

function RankingPanel.build(): Frame
	local rows: { Instance } = {
		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(ROW_GAP / CANVAS_H, 0),
		}) :: Instance,
	}
	for position, entry in MockStore.RANKING do
		table.insert(rows, row(position, entry))
	end
	return create("Frame")({
		Name = "Ranking",
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

return RankingPanel
