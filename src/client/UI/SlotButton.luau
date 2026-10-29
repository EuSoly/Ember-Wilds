--!strict
-- Um slot do inventário (usado pela hotbar e pela grade da mochila).
-- - Borda laranja: slot selecionado da hotbar.
-- - Borda amarela: origem escolhida para mover (mochila aberta).
-- - Trancado (slots da mochila sem mochila): escuro e sem toque.
-- Toque: com a mochila aberta, escolhe/move; fechada, seleciona (só na hotbar).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local BackpackState = require(Client:WaitForChild("BackpackState"))
local HotbarState = require(Client:WaitForChild("HotbarState"))
local InventoryState = require(Client:WaitForChild("InventoryState"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))

local create = vide.create

local SELECTED_STROKE = 2
local LOCKED_TRANSPARENCY = 0.6

export type Props = {
	index: number,
	Size: UDim2?,
	LayoutOrder: number?,
}

local function SlotButton(props: Props): TextButton
	local index = props.index
	local item = vide.derive(function()
		return InventoryState.slots()[index]
	end)
	local locked = vide.derive(function()
		return index > InventoryState.capacity()
	end)
	local isSelected = vide.derive(function()
		return HotbarState.selected() == index
	end)
	local isPicked = vide.derive(function()
		return InventoryState.pick() == index
	end)

	return create("TextButton")({
		Name = `Slot{index}`,
		LayoutOrder = props.LayoutOrder or index,
		Text = "",
		AutoButtonColor = false,
		Size = props.Size or UDim2.fromScale(1, 1),
		Active = function()
			return not locked()
		end,
		BackgroundColor3 = function()
			return if isSelected() then Theme.ui.panelRaised else Theme.ui.panel
		end,
		BackgroundTransparency = function()
			return if locked() then LOCKED_TRANSPARENCY else Theme.panelTransparency
		end,
		BorderSizePixel = 0,
		create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
		-- Escala com a tela, mas nunca menor que o mínimo de toque nem gigante em 1080p.
		create("UISizeConstraint")({ MinSize = Theme.slotMinSize, MaxSize = Theme.slotMaxSize }),
		create("UICorner")({ CornerRadius = Theme.slotCorner }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return if isPicked() then Theme.ui.warning elseif isSelected() then Theme.ui.action else Theme.ui.border
			end,
			Thickness = function()
				return if isPicked() or isSelected() then SELECTED_STROKE else Theme.strokeThickness
			end,
		}),
		Activated = function()
			if vide.untrack(locked) then
				return
			end
			if vide.untrack(BackpackState.open) then
				InventoryState.tap(index)
			else
				HotbarState.select(index)
			end
		end,
		-- Ícone do item (ou nada, se o slot está vazio ou trancado).
		vide.show(
			vide.derive(function()
				return if locked() then nil else item()
			end),
			function(current)
				return ItemIcon({ item = current })
			end
		),
	}) :: TextButton
end

return SlotButton
