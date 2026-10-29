--!strict
-- Hotbar de 10 slots (embaixo, no centro). O slot selecionado ganha borda laranja.
-- Seleciona tocando/clicando no slot ou pelas teclas 1 … 0 (InputActions Slot1 … Slot10).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local InputNames = require(Shared:WaitForChild("InputNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local HotbarState = require(script.Parent.Parent:WaitForChild("HotbarState"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))

local create = vide.create

local SELECTED_STROKE = 2

local function Slot(index: number): TextButton
	local isSelected = vide.derive(function()
		return HotbarState.selected() == index
	end)
	local item = vide.derive(function()
		return HotbarState.slots()[index]
	end)

	return create("TextButton")({
		Name = `Slot{index}`,
		LayoutOrder = index,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.fromScale(0.09, 1),
		BackgroundColor3 = function()
			return if isSelected() then Theme.ui.panelRaised else Theme.ui.panel
		end,
		BackgroundTransparency = Theme.panelTransparency,
		BorderSizePixel = 0,
		create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
		create("UICorner")({ CornerRadius = Theme.slotCorner }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return if isSelected() then Theme.ui.action else Theme.ui.border
			end,
			Thickness = function()
				return if isSelected() then SELECTED_STROKE else Theme.strokeThickness
			end,
		}),
		Activated = function()
			HotbarState.select(index)
		end,
		-- Ícone do item (ou nada, se o slot está vazio).
		vide.show(item, function(current)
			return ItemIcon({ itemId = current().id, count = current().count })
		end),
	}) :: TextButton
end

-- Liga as teclas 1 … 0: cada InputAction SlotN seleciona o slot N.
local function bindSlotKeys()
	task.spawn(function()
		local context = Players.LocalPlayer:WaitForChild(InputNames.Context)
		for index, name in InputNames.Slot do
			local action = context:WaitForChild(name) :: InputAction
			action.Pressed:Connect(function()
				HotbarState.select(index)
			end)
		end
	end)
end

local function Hotbar(): Frame
	bindSlotKeys()

	local slots = {}
	for index = 1, HotbarState.SLOT_COUNT do
		table.insert(slots, Slot(index))
	end

	return create("Frame")({
		Name = "Hotbar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.98),
		Size = UDim2.fromScale(0.62, 0.085),
		BackgroundTransparency = 1,
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0.008, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		slots,
	}) :: Frame
end

return Hotbar
