--!strict
-- Painel do baú: aparece acima dos anéis de status (filho da hotbar, posição
-- em HudBottom) só enquanto há um baú perto e mostra o item guardado (ícone
-- com a quantidade). Clicar/tocar tira tudo que couber no inventário. Baú
-- vazio: moldura vazia, sem ícone.
--
-- No toque (12/11/2026), ao lado vai o botão "Guardar": ligado, tocar num slot
-- da hotbar põe 1 no baú e segurar põe 10 (SlotButton). O "+" de canto do PC
-- tinha 17 px, pequeno demais para o dedo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local ChestState = require(script.Parent.Parent:WaitForChild("ChestState"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local HudBottom = require(script.Parent:WaitForChild("HudBottom"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create

local SIZE = 64 -- px (acima do mínimo de toque); o InteractPanel empilha por esta altura
local STORE_WIDTH = 104 -- px do botão Guardar
local GAP = 8

local function ChestSlot(): TextButton
	return create("TextButton")({
		Name = "Slot",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(SIZE, SIZE),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.ui.panel,
		-- Com a arte, o couro do slot é o fundo e a borda.
		BackgroundTransparency = if HudArt.HAS_SLOT then 1 else Theme.panelTransparency,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = Theme.slotCorner }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Theme.ui.border,
			Thickness = Theme.strokeThickness,
			Enabled = not HudArt.HAS_SLOT,
		}),
		if HudArt.HAS_SLOT then { HudArt.slotBack() } else {},
		Activated = function()
			ChestState.take()
		end,
		vide.show(ChestState.contents, function(current)
			return if HudArt.HAS_SLOT
				then HudArt.inSlot(ItemIcon({ item = current, bare = true }))
				else ItemIcon({ item = current })
		end),
	}) :: TextButton
end

local function ChestPanel(): Frame
	return create("Frame")({
		Name = "ChestPanel",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = function()
			return HudBottom.above(0)
		end,
		AutomaticSize = Enum.AutomaticSize.X,
		Size = UDim2.fromOffset(0, SIZE),
		BackgroundTransparency = 1,
		Visible = function()
			return ChestState.near() ~= nil
		end,
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		ChestSlot(),
		Rustic.button({
			Name = "Store",
			LayoutOrder = 2,
			Visible = HudBottom.touch,
			Size = UDim2.fromOffset(STORE_WIDTH, 48),
			kind = function()
				return if ChestState.storing() then "green" else "wood"
			end,
			text = function()
				return Strings.get(if ChestState.storing() then "hud.chest_store_done" else "hud.chest_store")
			end,
			maxSize = 18,
			Activated = function()
				ChestState.storing(not vide.untrack(ChestState.storing))
			end,
		}),
	}) :: Frame
end

return ChestPanel
