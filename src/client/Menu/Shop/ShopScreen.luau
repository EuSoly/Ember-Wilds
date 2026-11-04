--!strict
-- Loja em tela cheia (UI 2): topo com voltar, placa LOJA e 4 abas coloridas;
-- abaixo, uma lista que rola com as seções (Pacotes, Gamepasses, Giros e
-- Golden Ember). A aba da seção visível fica destacada; clicar numa aba (ou
-- pedir uma seção por MenuState.openShop) rola até ela. O card da Golden Ember
-- do canto é do MenuShell e continua por cima.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local ShopLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("ShopLayout"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local MenuState = require(script.Parent.Parent:WaitForChild("MenuState"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))

local create = vide.create
local R = Theme.rustic

type Section = MenuState.ShopSection
type Layout = ShopLayout.Layout

-- Abas na ordem das seções, com a cor de cada uma.
local TABS: { { id: Section, color: Color3 } } = {
	{ id = "packs", color = Color3.fromHex("#E0553A") },
	{ id = "passes", color = Color3.fromHex("#E8AE2A") },
	{ id = "spins", color = Color3.fromHex("#8E62E0") },
	{ id = "ember", color = Color3.fromHex("#EE8A2C") },
}
local SECTION_GAP = 28
local JUMP_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local ACTIVE_SLACK = 40 -- a seção conta como visível um pouco antes de encostar no topo

export type SectionBuilders = { [Section]: () -> GuiObject }

local ShopScreen = {}

-- Monta a loja. `layout` e `screenHeight` vêm do MenuShell; `visible` diz se a
-- loja está aberta; `builders` monta o conteúdo de cada seção.
function ShopScreen.build(
	layout: () -> Layout,
	screenHeight: () -> number,
	visible: () -> boolean,
	builders: SectionBuilders
): Frame
	-- Fonte Vide tipada (sem o tipo, o vide.source alarga "packs" para string).
	local active: (() -> Section) & ((Section) -> Section) = vide.source("packs" :: Section) :: any
	local sectionFrames: { [string]: Frame } = {}

	local scrollChildren: { Instance } = {
		create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, SECTION_GAP) }),
		create("UIPadding")({ PaddingRight = UDim.new(0, 10), PaddingBottom = UDim.new(0, 16) }),
	}
	for i, tab in TABS do
		local builder = builders[tab.id]
		local content = if builder then builder() else nil
		local section = create("Frame")({
			Name = "Section_" .. tab.id,
			LayoutOrder = i,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }),
			ShopParts.sectionTitle("shop.section." .. tab.id),
			content,
		}) :: Frame
		if content then
			content.LayoutOrder = 2
		end
		sectionFrames[tab.id] = section
		table.insert(scrollChildren, section)
	end

	local scroll = create("ScrollingFrame")({
		Name = "List",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.contentX, l.contentTop)
		end,
		Size = function()
			local l = layout()
			return UDim2.fromOffset(l.contentWidth, screenHeight() - l.contentTop - ShopLayout.MARGIN)
		end,
		CanvasSize = UDim2.fromScale(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = R.woodEdge,
		scrollChildren,
	}) :: ScrollingFrame

	-- Topo da seção dentro da lista (em pixels do canvas).
	local function sectionOffset(id: string): number
		local frame = sectionFrames[id]
		return frame.AbsolutePosition.Y - scroll.AbsolutePosition.Y + scroll.CanvasPosition.Y
	end

	local function jump(id: string)
		local maxY = math.max(scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteWindowSize.Y, 0)
		local target = math.clamp(sectionOffset(id), 0, maxY)
		TweenService:Create(scroll, JUMP_INFO, { CanvasPosition = Vector2.new(0, target) }):Play()
	end

	-- A aba ativa é a última seção cujo topo já passou do topo da lista.
	scroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
		local current: Section = "packs"
		local maxY = scroll.AbsoluteCanvasSize.Y - scroll.AbsoluteWindowSize.Y
		for _, tab in TABS do
			if sectionOffset(tab.id) <= scroll.CanvasPosition.Y + ACTIVE_SLACK then
				current = tab.id
			end
		end
		-- No fim da lista a última seção pode não chegar ao topo: vale ela.
		if maxY > 0 and scroll.CanvasPosition.Y >= maxY - 2 then
			current = TABS[#TABS].id
		end
		if vide.untrack(active) ~= current then
			active(current)
		end
	end)

	-- Pedido de seção (aba ou "+" da Golden Ember): rola até ela e limpa.
	vide.effect(function()
		local wanted = MenuState.shopSection()
		if wanted ~= nil and visible() then
			local section: string = wanted
			task.defer(function()
				jump(section)
				MenuState.shopSection(nil)
			end)
		end
	end)

	local tabButtons: { Instance } = {
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, ShopLayout.GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}) :: Instance,
	}
	for i, tab in TABS do
		local isActive = function()
			return active() == tab.id
		end
		table.insert(
			tabButtons,
			create("TextButton")({
				Name = "Tab_" .. tab.id,
				LayoutOrder = i,
				Text = "",
				AutoButtonColor = true,
				Size = UDim2.new(1 / #TABS, -ShopLayout.GAP * (#TABS - 1) / #TABS, 1, 0),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
				create("UIStroke")({
					Color = function()
						return if isActive() then R.cream else R.outline
					end,
					Thickness = function()
						return if isActive() then 3 else 2
					end,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
				create("UIGradient")({
					Rotation = 90,
					Color = ColorSequence.new(ShopParts.shade(tab.color, 1.3), ShopParts.shade(tab.color, 0.75)),
					Transparency = function()
						return NumberSequence.new(if isActive() then 0 else 0.25)
					end,
				}),
				Activated = function()
					jump(tab.id)
				end,
				ShopParts.outlined({
					Size = UDim2.fromScale(0.9, 0.6),
					Position = UDim2.fromScale(0.5, 0.5),
					AnchorPoint = Vector2.new(0.5, 0.5),
					FontFace = Theme.font.number,
					Text = Strings.get("shop.tab." .. tab.id),
					maxSize = 20,
				}),
			})
		)
	end

	return create("Frame")({
		Name = "Shop",
		Visible = visible,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 3,
		-- Fundo escurecido: o mundo continua aparecendo de leve atrás.
		create("Frame")({
			Name = "Dim",
			Size = UDim2.new(1, 0, 1, 200),
			Position = UDim2.fromOffset(0, -100),
			BackgroundColor3 = Color3.fromHex("#0B120E"),
			BackgroundTransparency = 0.2,
			BorderSizePixel = 0,
			ZIndex = 0,
		}),
		Rustic.button({
			Name = "Back",
			Position = function()
				local l = layout()
				return UDim2.fromOffset(l.contentX, l.top)
			end,
			Size = function()
				local l = layout()
				return UDim2.fromOffset(l.backWidth, l.topHeight)
			end,
			kind = "wood",
			text = Strings.get("shop.back"),
			maxSize = 20,
			Activated = function()
				MenuState.open("play")
			end,
		}),
		Rustic.plate({
			Name = "TitlePlate",
			Visible = function()
				return layout().titleWidth > 0
			end,
			Position = function()
				local l = layout()
				return UDim2.fromOffset(l.contentX + l.backWidth + ShopLayout.GAP, l.top)
			end,
			Size = function()
				local l = layout()
				return UDim2.fromOffset(l.titleWidth, l.topHeight)
			end,
			Rustic.label({
				Size = UDim2.fromScale(0.8, 0.6),
				Position = UDim2.fromScale(0.5, 0.48),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Theme.font.title,
				Text = Strings.get("shop.title"),
				maxSize = 28,
				create("UIStroke")({ Color = R.outline, Thickness = 1.5 }),
			}),
		}),
		create("Frame")({
			Name = "Tabs",
			BackgroundTransparency = 1,
			Position = function()
				local l = layout()
				return UDim2.fromOffset(l.tabsX, l.top + 6)
			end,
			Size = function()
				local l = layout()
				return UDim2.fromOffset(l.tabsWidth, l.topHeight - 12)
			end,
			tabButtons,
		}),
		scroll,
	}) :: Frame
end

return ShopScreen
