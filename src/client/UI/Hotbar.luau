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
local HudBottom = require(script.Parent:WaitForChild("HudBottom"))
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

-- `above`: componentes presos acima da hotbar (anéis de status, trava da arma,
-- painéis do baú, da caixa e da peça). Ficam como filhos dela para nunca se
-- sobreporem, qualquer que seja o tamanho da tela (posições em HudBottom).
--
-- No PC: uma linha por escala (62% da largura). No toque (12/11/2026): slots
-- de 44 px no vão entre os joysticks, em uma linha de 10 ou duas de 5
-- (Shared/UIFlow/HudLayout).
local function Hotbar(above: { Instance }?): Frame
	bindSlotKeys()

	local slots = {}
	for index = 1, HotbarState.SLOT_COUNT do
		table.insert(slots, SlotButton({ index = index, Size = UDim2.fromScale(SLOT_WIDTH, 1), LayoutOrder = index }))
	end

	local row = create("Frame")({
		Name = "Row",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		slots,
	}) :: Frame

	-- Um layout por modo (trocar o pai não recria os slots).
	local list = create("UIListLayout")({
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0.008, 0),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	local grid = create("UIGridLayout")({
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		CellSize = function()
			local layout = HudBottom.hotbar()
			return if layout then UDim2.fromOffset(layout.slot, layout.slot) else UDim2.fromOffset(44, 44)
		end,
		CellPadding = function()
			local layout = HudBottom.hotbar()
			return if layout then UDim2.fromOffset(layout.gap, layout.gap) else UDim2.new()
		end,
		FillDirectionMaxCells = function()
			local layout = HudBottom.hotbar()
			return if layout then layout.columns else HotbarState.SLOT_COUNT
		end,
	})
	vide.effect(function()
		local touchMode = HudBottom.hotbar() ~= nil
		list.Parent = if touchMode then nil else row
		grid.Parent = if touchMode then row else nil
	end)

	return create("Frame")({
		Name = "Hotbar",
		Active = true,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = function()
			local layout = HudBottom.hotbar()
			return if layout then UDim2.new(0, layout.centerX, 0.98, 0) else UDim2.fromScale(0.5, 0.98)
		end,
		Size = function()
			local layout = HudBottom.hotbar()
			return if layout then UDim2.fromOffset(layout.width, layout.height) else UDim2.fromScale(0.62, 0.085)
		end,
		BackgroundTransparency = 1,
		-- No PC, a altura acompanha o slot: entre o mínimo de toque e o máximo.
		create("UISizeConstraint")({
			MinSize = Vector2.new(0, Theme.slotMinSize.Y),
			MaxSize = function()
				return if HudBottom.hotbar()
					then Vector2.new(math.huge, math.huge)
					else Vector2.new(math.huge, Theme.slotMaxSize.Y)
			end,
		}),
		-- Os slots ficam numa fileira própria, para o layout não arrumar
		-- também os componentes de `above`.
		row,
		above or {},
	}) :: Frame
end

return Hotbar
