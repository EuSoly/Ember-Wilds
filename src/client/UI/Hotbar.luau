--!strict
-- Hotbar de 10 slots (embaixo, no centro): os slots 1–10 do inventário.
-- O slot selecionado ganha borda laranja. Seleciona tocando/clicando no slot ou
-- pelas teclas 1 … 0 (InputActions Slot1 … Slot10). Mover itens é arrastando
-- (veja DragState).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local InputNames = require(Shared:WaitForChild("InputNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local HotbarState = require(script.Parent.Parent:WaitForChild("HotbarState"))
local SlotButton = require(script.Parent:WaitForChild("SlotButton"))

local create = vide.create

local SLOT_WIDTH = 0.09 -- fração da largura da hotbar

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

-- `above`: componentes presos logo acima da hotbar (os anéis de status).
-- Ficam como filhos dela para nunca se sobreporem, qualquer que seja o tamanho da tela.
local function Hotbar(above: { Instance }?): Frame
	bindSlotKeys()

	local slots = {}
	for index = 1, HotbarState.SLOT_COUNT do
		table.insert(slots, SlotButton({ index = index, Size = UDim2.fromScale(SLOT_WIDTH, 1) }))
	end

	return create("Frame")({
		Name = "Hotbar",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 0.98),
		Size = UDim2.fromScale(0.62, 0.085),
		BackgroundTransparency = 1,
		-- A altura acompanha o slot: entre o mínimo de toque e o máximo.
		create("UISizeConstraint")({
			MinSize = Vector2.new(0, Theme.slotMinSize.Y),
			MaxSize = Vector2.new(math.huge, Theme.slotMaxSize.Y),
		}),
		-- Os slots ficam numa fileira própria, para o layout não arrumar
		-- também os componentes de `above`.
		create("Frame")({
			Name = "Row",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0.008, 0),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			slots,
		}),
		above or {},
	}) :: Frame
end

return Hotbar
