--!strict
-- Livro de receitas: abas em cima, grade de itens à esquerda e a ficha do item
-- selecionado à direita (UI/BookSheet). Só mostra informação: craftar continua
-- pela coluna de receitas do HUD. O que entra em cada aba e na ficha vem do
-- UIFlow/BookInfo (puro, lido dos Defs); aqui só se desenha.
-- Abre pelo botão do livro (RecipeBookButton); o ScreenController liga e
-- desliga a tela (só jogando). Reabre na última aba e no último item da sessão.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local BookImages = require(Shared:WaitForChild("BookImages"))
local BookInfo = require(Shared:WaitForChild("UIFlow"):WaitForChild("BookInfo"))
local HudImages = require(Shared:WaitForChild("HudImages"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local CraftState = require(Client:WaitForChild("CraftState"))
local InventoryState = require(Client:WaitForChild("InventoryState"))
local UI = Client:WaitForChild("UI")
local BookSheet = require(UI:WaitForChild("BookSheet"))
local HudArt = require(UI:WaitForChild("HudArt"))
local ItemIcon = require(UI:WaitForChild("ItemIcon"))
local Kit = require(UI:WaitForChild("Kit"))
local Rustic = require(UI:WaitForChild("Rustic"))
local Template = require(Client:WaitForChild("UITemplates"):WaitForChild("Template"))

local create = vide.create

local CELL = 58 -- px do slot (acima do mínimo de toque)
local GAP = 8
local TAB_HEIGHT = 50
local PAD = 30 -- da borda do painel (passa da moldura de madeira)
local TITLE_HEIGHT = 50
local GRID_SHARE = 0.52 -- fração da largura para a grade (o resto é a ficha)
local TAB_CORNER = 12 -- px lógicos dos cantos da aba

type Tab = BookInfo.Tab
type Source<T> = (() -> T) & ((T) -> T)

local RecipeBookScreen = {
	open = vide.source(false),
	tab = vide.source("tools" :: Tab) :: Source<Tab>,
	selected = vide.source(nil :: string?) :: Source<string?>,
}

local inStudio = RunService:IsStudio()

function RecipeBookScreen.toggle()
	RecipeBookScreen.open(not vide.untrack(RecipeBookScreen.open))
end

-- Mostra a ficha de `itemId`, trocando para a primeira aba que o tem.
function RecipeBookScreen.show(itemId: string)
	local tab = BookInfo.firstTab(itemId, inStudio)
	if tab then
		RecipeBookScreen.tab(tab)
	end
	RecipeBookScreen.selected(itemId)
end

local function counts(): { [string]: number }
	local result = {}
	for _, slot in InventoryState.slots() do
		result[slot.id] = (result[slot.id] or 0) + slot.count
	end
	return result
end

local function slicedArt(kind: string, id: string | () -> string, corner: number): ImageLabel
	local art = BookImages.SLICED[kind]
	return create("ImageLabel")({
		Name = "Art",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = id,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(art.slice[1], art.slice[2], art.slice[3], art.slice[4]),
		SliceScale = corner / art.slice[1],
		ZIndex = 0,
	}) :: ImageLabel
end

-- Uma aba: madeira (laranja quando selecionada) com o ícone e o nome.
local function TabButton(tab: Tab): TextButton
	local active = function()
		return RecipeBookScreen.tab() == tab
	end
	local hasArt = BookImages.has(BookImages.TAB) and BookImages.has(BookImages.TAB_SELECTED)
	local icon = BookImages.TAB_ICON[tab]
	local children: { Instance } = {}
	if hasArt then
		table.insert(
			children,
			slicedArt("tab", function()
				return if active() then BookImages.TAB_SELECTED else BookImages.TAB
			end, TAB_CORNER)
		)
	else
		table.insert(children, create("UICorner")({ CornerRadius = UDim.new(0, TAB_CORNER) }))
		table.insert(children, create("UIStroke")({ Color = Theme.rustic.charcoal, Thickness = 2 }))
	end
	if BookImages.has(icon) then
		table.insert(
			children,
			HudArt.image(icon, {
				Name = "Icon",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.new(0, 10, 0.5, 0),
				Size = UDim2.fromOffset(TAB_HEIGHT - 18, TAB_HEIGHT - 18),
				ZIndex = 2,
			})
		)
	end
	local textLeft = if BookImages.has(icon) then TAB_HEIGHT - 2 else 8
	table.insert(
		children,
		Kit.text({
			Name = "Label",
			Position = UDim2.fromOffset(textLeft, 6),
			Size = UDim2.new(1, -textLeft - 8, 1, -12),
			FontFace = Theme.font.number,
			Text = Strings.get("book.tab." .. tab),
			maxSize = 18,
			ZIndex = 2,
		})
	)
	return create("TextButton")({
		Name = "Tab_" .. tab,
		Text = "",
		AutoButtonColor = false,
		Size = UDim2.new(1 / #BookInfo.TABS, -GAP, 1, 0),
		BackgroundColor3 = function()
			return if active() then Theme.ui.action else Theme.rustic.walnut
		end,
		BackgroundTransparency = if hasArt then 1 else 0,
		BorderSizePixel = 0,
		Activated = function()
			RecipeBookScreen.tab(tab)
		end,
		children,
	}) :: TextButton
end

-- Um item da grade: slot de couro (dourado quando selecionado), o ícone 3D e
-- uma sombra quando ainda não dá para fazer agora.
local function Cell(item: () -> string, index: number): TextButton
	local selected = function()
		return RecipeBookScreen.selected() == item()
	end
	local dim = function()
		return not BookInfo.craftableNow(item(), counts(), CraftState.near())
	end
	local children: { Instance } = {}
	if HudArt.HAS_SLOT then
		table.insert(
			children,
			create("ImageLabel")({
				Name = "SlotArt",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Stretch,
				Image = function()
					return if selected() then HudImages.SLOT_SELECTED else HudImages.SLOT
				end,
				ZIndex = 0,
			})
		)
	else
		table.insert(children, create("UICorner")({ CornerRadius = Theme.slotCorner }))
		table.insert(
			children,
			create("UIStroke")({
				Color = function()
					return if selected() then Theme.ui.action else Theme.ui.border
				end,
				Thickness = 2,
			})
		)
	end
	local icon = ItemIcon({
		item = function()
			return { id = item(), count = 1 }
		end,
		bare = HudArt.HAS_SLOT,
	})
	table.insert(children, if HudArt.HAS_SLOT then HudArt.inSlot(icon) else icon)
	table.insert(
		children,
		create("Frame")({
			Name = "Dim",
			Visible = dim,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.78, 0.78),
			BackgroundColor3 = Theme.rustic.charcoal,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			ZIndex = 5,
			create("UICorner")({ CornerRadius = Theme.slotCorner }),
		})
	)
	return create("TextButton")({
		Name = "Cell",
		LayoutOrder = index,
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = Theme.ui.panel,
		BackgroundTransparency = if HudArt.HAS_SLOT then 1 else Theme.panelTransparency,
		BorderSizePixel = 0,
		Activated = function()
			RecipeBookScreen.selected(item())
		end,
		children,
	}) :: TextButton
end

local function CloseButton(): GuiButton
	local function close()
		RecipeBookScreen.open(false)
	end
	if BookImages.has(BookImages.CLOSE) then
		return create("ImageButton")({
			Name = "CloseButton",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 14, 0, -14),
			Size = UDim2.fromOffset(52, 52),
			BackgroundTransparency = 1,
			Image = BookImages.CLOSE,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 10,
			Activated = close,
		}) :: ImageButton
	end
	return HudArt.roundButton({
		Name = "CloseButton",
		icon = "",
		fallback = "X",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 14, 0, -14),
		Size = UDim2.fromOffset(52, 52),
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		Activated = close,
		minSize = Vector2.new(44, 44),
		maxSize = Vector2.new(60, 60),
	})
end

local function Book(): Frame
	local items = vide.derive(function()
		return BookInfo.items(RecipeBookScreen.tab(), inStudio)
	end)
	-- Aba nova (ou primeira vez): seleciona o primeiro item se o atual não está nela.
	vide.effect(function()
		local list = items()
		local current = vide.untrack(RecipeBookScreen.selected)
		if current == nil or table.find(list, current) == nil then
			RecipeBookScreen.selected(list[1])
		end
	end)

	local tabs: { Instance } = {}
	for _, tab in BookInfo.TABS do
		table.insert(tabs, TabButton(tab))
	end

	return Kit.panel({
		Name = "Book",
		Active = true, -- o clique no livro não passa para o mundo
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.9, 0.84),
		create("UISizeConstraint")({ MaxSize = Vector2.new(980, 620) }),
		Rustic.plate({
			Name = "Title",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.fromOffset(300, TITLE_HEIGHT),
			ZIndex = 10,
			Kit.text({
				Size = UDim2.new(1, -24, 1, -14),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Theme.font.number,
				Text = Strings.get("book.title"),
				maxSize = 24,
				ZIndex = 11,
			}),
		}),
		CloseButton(),
		create("Frame")({
			Name = "Body",
			Position = UDim2.fromOffset(PAD, PAD + TITLE_HEIGHT / 2 - 8),
			Size = UDim2.new(1, -2 * PAD, 1, -2 * PAD - TITLE_HEIGHT / 2 + 8),
			BackgroundTransparency = 1,
			create("Frame")({
				Name = "Tabs",
				Size = UDim2.new(1, GAP, 0, TAB_HEIGHT),
				BackgroundTransparency = 1,
				create("UIListLayout")({
					FillDirection = Enum.FillDirection.Horizontal,
					Padding = UDim.new(0, GAP),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				tabs,
			}),
			create("ScrollingFrame")({
				Name = "Grid",
				Position = UDim2.fromOffset(0, TAB_HEIGHT + GAP + 4),
				Size = UDim2.new(GRID_SHARE, -GAP, 1, -TAB_HEIGHT - GAP - 4),
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				ScrollBarThickness = 6,
				ScrollBarImageColor3 = Theme.rustic.cream,
				AutomaticCanvasSize = Enum.AutomaticSize.Y,
				CanvasSize = UDim2.new(),
				ScrollingDirection = Enum.ScrollingDirection.Y,
				create("UIPadding")({ PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4) }),
				create("UIGridLayout")({
					CellSize = UDim2.fromOffset(CELL, CELL),
					CellPadding = UDim2.fromOffset(GAP, GAP),
					SortOrder = Enum.SortOrder.LayoutOrder,
				}),
				vide.indexes(items, Cell),
			}),
			BookSheet({
				item = RecipeBookScreen.selected,
				onShow = RecipeBookScreen.show,
				Position = UDim2.new(GRID_SHARE, GAP, 0, TAB_HEIGHT + GAP + 4),
				Size = UDim2.new(1 - GRID_SHARE, -GAP, 1, -TAB_HEIGHT - GAP - 4),
			}),
		}),
	})
end

function RecipeBookScreen.mount(playerGui: Instance): ScreenGui?
	-- Chamado dentro do vide.root do ScreenController: os efeitos vivem nele.
	local gui = create("ScreenGui")({
		Name = "RecipeBook",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 5, -- acima do HUD
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		Book(),
	}) :: ScreenGui
	Template.bindUiScale(gui)
	gui.Parent = playerGui
	return gui
end

return RecipeBookScreen
