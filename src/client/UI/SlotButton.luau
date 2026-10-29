--!strict
-- Um slot do inventário (usado pela hotbar e pela grade da mochila).
-- - Toque/clique rápido num slot da hotbar: seleciona.
-- - Segurar e arrastar: move o item para outro slot (ver DragState).
-- - Borda laranja: slot selecionado da hotbar. Borda amarela: slot debaixo do
--   item que está sendo arrastado (onde ele vai cair).
-- - Trancado (slots da mochila sem mochila): escuro e sem toque.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local DragState = require(Client:WaitForChild("DragState"))
local HotbarState = require(Client:WaitForChild("HotbarState"))
local InventoryState = require(Client:WaitForChild("InventoryState"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))

local create = vide.create

local SELECTED_STROKE = 2
local LOCKED_TRANSPARENCY = 0.6
-- O slot de onde o item está saindo fica apagado durante o arrasto.
local DRAG_ORIGIN_TRANSPARENCY = 0.7

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
		return index <= HotbarState.SLOT_COUNT and HotbarState.selected() == index
	end)
	local isDropTarget = vide.derive(function()
		local drag = DragState.current()
		return drag ~= nil and drag.from ~= index and DragState.target() == index and not locked()
	end)
	local isDragOrigin = vide.derive(function()
		local drag = DragState.current()
		return drag ~= nil and drag.from == index
	end)

	local button = create("TextButton")({
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
			return if locked()
				then LOCKED_TRANSPARENCY
				elseif isDragOrigin() then DRAG_ORIGIN_TRANSPARENCY
				else Theme.panelTransparency
		end,
		BorderSizePixel = 0,
		create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
		-- Escala com a tela, mas nunca menor que o mínimo de toque nem gigante em 1080p.
		create("UISizeConstraint")({ MinSize = Theme.slotMinSize, MaxSize = Theme.slotMaxSize }),
		create("UICorner")({ CornerRadius = Theme.slotCorner }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return if isDropTarget()
					then Theme.ui.warning
					elseif isSelected() then Theme.ui.action
					else Theme.ui.border
			end,
			Thickness = function()
				return if isDropTarget() or isSelected() then SELECTED_STROKE else Theme.strokeThickness
			end,
		}),
		InputBegan = function(input: InputObject)
			local kind = input.UserInputType
			if
				not vide.untrack(locked)
				and (kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch)
			then
				DragState.press(index, input)
			end
		end,
		Activated = function()
			-- Foi o fim de um arrasto, não um toque: não seleciona.
			if vide.untrack(locked) or DragState.justDropped() then
				return
			end
			HotbarState.select(index) -- só tem efeito nos slots 1–10
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
	-- O DragState reconhece os slots por este atributo.
	button:SetAttribute("SlotIndex", index)
	return button
end

return SlotButton
