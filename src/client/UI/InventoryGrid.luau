--!strict
-- Grade da mochila: só os 6 slots da mochila (11–16). Os slots 1–10 ficam na
-- hotbar; para trocar itens entre as duas, arraste de uma para a outra.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local SlotButton = require(script.Parent:WaitForChild("SlotButton"))

local create = vide.create

local FIRST_BAG_SLOT = 11
local LAST_BAG_SLOT = 16
local COLUMNS = 3

local function InventoryGrid(): Frame
	local slots = {}
	for index = FIRST_BAG_SLOT, LAST_BAG_SLOT do
		table.insert(slots, SlotButton({ index = index }))
	end

	return create("Frame")({
		Name = "InventoryGrid",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.94),
		Size = UDim2.fromScale(0.9, 0.7),
		BackgroundTransparency = 1,
		create("UIGridLayout")({
			CellSize = UDim2.fromScale(0.3, 0.45),
			CellPadding = UDim2.fromScale(0.03, 0.06),
			FillDirectionMaxCells = COLUMNS,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		slots,
	}) :: Frame
end

return InventoryGrid
