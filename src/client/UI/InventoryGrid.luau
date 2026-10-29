--!strict
-- Grade da mochila: os slots além da hotbar (11 até a capacidade). Quantos são
-- depende da mochila vestida e do gamepass, então a grade se monta a partir da
-- capacidade que o servidor manda. Com mais de MAX_VISIBLE_ROWS linhas, rola.
-- Para trocar itens com a hotbar, arraste de uma para a outra.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local InventoryConfig = require(Shared:WaitForChild("InventoryConfig"))
local Theme = require(Shared:WaitForChild("Theme"))
local InventoryState = require(script.Parent.Parent:WaitForChild("InventoryState"))
local SlotButton = require(script.Parent:WaitForChild("SlotButton"))

local create = vide.create

local COLUMNS = 3
local CELL = 52 -- pixels (entre o mínimo de toque e o máximo de slot)
local GAP = 8
local MAX_VISIBLE_ROWS = 3

local InventoryGrid = {}

-- Quantas linhas os slots da mochila ocupam.
local function rowsFor(capacity: number): number
	local bagSlots = math.max(capacity - InventoryConfig.HOTBAR_SLOTS, 0)
	return math.ceil(bagSlots / COLUMNS)
end

-- Altura visível da grade (o resto rola).
function InventoryGrid.height(capacity: number): number
	local rows = math.clamp(rowsFor(capacity), 1, MAX_VISIBLE_ROWS)
	return rows * CELL + (rows - 1) * GAP
end

InventoryGrid.WIDTH = COLUMNS * CELL + (COLUMNS - 1) * GAP

function InventoryGrid.Component(): ScrollingFrame
	-- Índices dos slots da mochila (11 … capacidade), como mapa para o vide.indexes.
	local bagSlots = vide.derive(function()
		local map: { [number]: boolean } = {}
		for index = InventoryConfig.HOTBAR_SLOTS + 1, InventoryState.capacity() do
			map[index] = true
		end
		return map
	end)

	return create("ScrollingFrame")({
		Name = "InventoryGrid",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -12),
		Size = function()
			return UDim2.fromOffset(InventoryGrid.WIDTH + 10, InventoryGrid.height(InventoryState.capacity()))
		end,
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = Theme.ui.border,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		create("UIGridLayout")({
			CellSize = UDim2.fromOffset(CELL, CELL),
			CellPadding = UDim2.fromOffset(GAP, GAP),
			FillDirectionMaxCells = COLUMNS,
			HorizontalAlignment = Enum.HorizontalAlignment.Left,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		vide.indexes(bagSlots, function(_present, index)
			return SlotButton({ index = index })
		end),
	}) :: ScrollingFrame
end

return InventoryGrid
