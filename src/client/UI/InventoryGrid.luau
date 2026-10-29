--!strict
-- Grade 4×4 da mochila: os 16 slots do inventário (1–10 são a hotbar,
-- 11–16 os da mochila, trancados enquanto o jogador não tem mochila).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local SlotButton = require(script.Parent:WaitForChild("SlotButton"))

local create = vide.create

local TOTAL_SLOTS = 16
local COLUMNS = 4

local function InventoryGrid(): Frame
	local slots = {}
	for index = 1, TOTAL_SLOTS do
		table.insert(slots, SlotButton({ index = index }))
	end

	return create("Frame")({
		Name = "InventoryGrid",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.95),
		Size = UDim2.fromScale(0.86, 0.76),
		BackgroundTransparency = 1,
		create("UIGridLayout")({
			CellSize = UDim2.fromScale(0.22, 0.22),
			CellPadding = UDim2.fromScale(0.04, 0.04),
			FillDirectionMaxCells = COLUMNS,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		slots,
	}) :: Frame
end

return InventoryGrid
