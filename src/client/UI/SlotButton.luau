--!strict
-- Um slot do inventário (usado pela hotbar e pela grade da mochila).
-- - Toque/clique rápido num slot da hotbar: seleciona.
-- - Segurar e arrastar: move o item para outro slot (ver DragState).
-- - Borda laranja: slot selecionado da hotbar. Borda amarela: slot debaixo do
--   item que está sendo arrastado (onde ele vai cair).
-- - Trancado (slots da mochila sem mochila): escuro e sem toque.
-- - Botão "+" (canto do slot com item, só com baú perto): põe 1 no baú; Shift+clique
--   põe 10; no celular, segurar 0,5 s põe 10. É um botão à parte e não inicia arrasto.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local HudImages = require(Shared:WaitForChild("HudImages"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local ChestState = require(Client:WaitForChild("ChestState"))
local DragState = require(Client:WaitForChild("DragState"))
local HotbarState = require(Client:WaitForChild("HotbarState"))
local InventoryState = require(Client:WaitForChild("InventoryState"))
local ItemHover = require(Client:WaitForChild("ItemHover"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local ItemIcon = require(script.Parent:WaitForChild("ItemIcon"))

local create = vide.create

local SELECTED_STROKE = 2
local LOCKED_TRANSPARENCY = 0.6
-- O slot de onde o item está saindo fica apagado durante o arrasto.
local DRAG_ORIGIN_TRANSPARENCY = 0.7

-- Quanto o "+" põe: clique = 1; Shift+clique ou segurar no celular = 10.
local PUT_ONE = 1
local PUT_MANY = 10
local HOLD_SECONDS = 0.5
local PLUS_SIZE = 0.4 -- fração do slot

export type Props = {
	index: number,
	Size: UDim2?,
	LayoutOrder: number?,
}

-- O toque/clique caiu em cima do botão `target`? (O InputBegan do slot também
-- dispara por um botão filho, então a posição decide.)
local function pressedOn(target: GuiObject, input: InputObject): boolean
	local at = Vector2.new(input.Position.X, input.Position.Y)
	local from, to = target.AbsolutePosition, target.AbsolutePosition + target.AbsoluteSize
	return at.X >= from.X and at.X <= to.X and at.Y >= from.Y and at.Y <= to.Y
end

-- Com a arte do slot (couro e madeira), o ícone fica dentro da borda dela.
local HAS_ART = HudImages.has(HudImages.SLOT)
local LOCK_SIZE = 0.42

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

	-- O "+" só existe com baú perto e item no slot.
	local plusVisible = vide.derive(function()
		return ChestState.near() ~= nil and item() ~= nil and not locked()
	end)
	-- Segurou até virar "põe 10": o Activated que vem ao soltar não põe mais 1.
	local heldDone = false

	local plus = create("TextButton")({
		Name = "ChestPlus",
		AnchorPoint = Vector2.new(0, 0),
		Position = UDim2.fromScale(0, 0),
		Size = UDim2.fromScale(PLUS_SIZE, PLUS_SIZE),
		ZIndex = 3,
		Visible = plusVisible,
		Text = "+",
		TextScaled = true,
		FontFace = Theme.font.number,
		TextColor3 = Theme.ui.text,
		AutoButtonColor = false,
		BackgroundColor3 = Theme.ui.action,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		InputBegan = function(input: InputObject)
			if input.UserInputType ~= Enum.UserInputType.Touch then
				return
			end
			heldDone = false
			task.delay(HOLD_SECONDS, function()
				if input.UserInputState ~= Enum.UserInputState.End and vide.untrack(plusVisible) then
					heldDone = true
					ChestState.put(index, PUT_MANY)
				end
			end)
		end,
		Activated = function()
			if heldDone then
				heldDone = false
				return
			end
			local shift = UserInputService:IsKeyDown(Enum.KeyCode.LeftShift)
				or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
			ChestState.put(index, if shift then PUT_MANY else PUT_ONE)
		end,
	}) :: TextButton

	-- Arte do slot: couro com madeira; dourada no selecionado; apagada se
	-- trancado (com o cadeado por cima). Lista vazia sem a arte.
	local artChildren: { Instance } = {}
	if HAS_ART then
		table.insert(
			artChildren,
			create("ImageLabel")({
				Name = "Art",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Stretch,
				Image = function()
					return if isSelected() then HudImages.SLOT_SELECTED else HudImages.SLOT
				end,
				ImageTransparency = function()
					return if isDragOrigin() then DRAG_ORIGIN_TRANSPARENCY else 0
				end,
				ImageColor3 = function()
					return if locked() then Color3.fromRGB(120, 120, 120) else Color3.new(1, 1, 1)
				end,
				ZIndex = 0,
			})
		)
		table.insert(
			artChildren,
			create("ImageLabel")({
				Name = "Lock",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(LOCK_SIZE, LOCK_SIZE),
				BackgroundTransparency = 1,
				Image = HudImages.LOCK,
				ScaleType = Enum.ScaleType.Fit,
				Visible = locked,
				ZIndex = 2,
			})
		)
	end

	local button: TextButton
	button = create("TextButton")({
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
			if HAS_ART then
				return 1
			end
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
		artChildren,
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			-- Com a arte, o traço só aparece no slot onde o item arrastado vai cair.
			Transparency = function()
				return if HAS_ART and not isDropTarget() then 1 else 0
			end,
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
		-- Dica do item (UI/ItemTooltip): mouse em cima, ou o dedo no celular.
		MouseEnter = function()
			if not vide.untrack(locked) then
				ItemHover.enter(index, button)
			end
		end,
		MouseLeave = function()
			ItemHover.leave(index)
		end,
		InputBegan = function(input: InputObject)
			local kind = input.UserInputType
			if kind == Enum.UserInputType.Touch and not vide.untrack(locked) then
				ItemHover.touch(index, button)
			end
			-- Apertou o "+": é do baú, não começa arrasto.
			if vide.untrack(plusVisible) and pressedOn(plus, input) then
				return
			end
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
				local icon = ItemIcon({ item = current, bare = HAS_ART })
				-- Com a arte: sem a moldura do tier, dentro da borda de madeira.
				return if HAS_ART then HudArt.inSlot(icon) else icon
			end
		),
		plus,
	}) :: TextButton
	-- O DragState reconhece os slots por este atributo.
	button:SetAttribute("SlotIndex", index)
	return button
end

return SlotButton
