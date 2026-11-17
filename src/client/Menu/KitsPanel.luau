--!strict
-- Painel "ESCOLHA SEU KIT" (UI 1): folha de papel à direita do boneco, uma
-- linha por kit com os três jeitos de levar o kit:
--   pontos · 1 vida    Robux · +1 no saldo de 1 vida    Robux · para sempre
-- (Robux ainda não é cobrado: o servidor entrega de graça.)
-- Kit para sempre troca os três por um botão verde "Usar" / "Ativo".
-- Com saldo de 1 vida: botão "Usar" (como o do kit para sempre), o número de
-- usos no canto e um "+" que troca o "Usar" pelas opções de compra.
-- O kit que vai nesta vida (KitShop.current) ganha a borda de brasa.
-- Quem chama posiciona e dimensiona o painel (MenuShell, pelo MenuLayout).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local KitRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("KitRules"))
local ShopConfig = require(Shared:WaitForChild("Shop"):WaitForChild("ShopConfig"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local ItemIcon = require(Client:WaitForChild("UI"):WaitForChild("ItemIcon"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local ShopData = require(Client:WaitForChild("ShopData"))
local KitList = require(Client:WaitForChild("Screens"):WaitForChild("KitList"))
local KitShop = require(script.Parent:WaitForChild("KitShop"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))

local create = vide.create
local R = Theme.rustic

local PADDING = 16
local HEADER = 44 -- título + fechar (alvo de toque)
local POINTS_ROW = 24
local ROW_HEIGHT = 130
local ROW_GAP = 8
local ICON = 52
local BUTTONS_HEIGHT = 48
local BUTTON_GAP = 6
local SELECTED_STROKE = 3
local CORNER_WIDTH = 92 -- canto do saldo: "×N" e o botão "+"
local CORNER_HEIGHT = 24
-- Celular deitado (ajuste do Elizeu, 17/11/2026): o painel sobe até o topo e
-- os kits ficam em duas colunas de cartões mais baixos, para os 4 caberem sem
-- rolar. Com kits de conquista a mais, a lista rola.
local COMPACT_PADDING = 12
local COMPACT_POINTS_ROW = 20
local COMPACT_ICON = 36
local COMPACT_BUTTONS = 40
local COMPACT_ROW_MIN = 96
local COMPACT_ROWS = 2

local KitsPanel = {}

-- Itens em texto ("8× Frutinha, 20× Madeira").
local function itemsText(kit: Defs.KitDef): string
	local parts: { string } = {}
	for _, entry in kit.items do
		local def = Defs.Items[entry.id]
		table.insert(parts, `{entry.count}× {if def then Strings.get(def.nameKey) else entry.id}`)
	end
	return table.concat(parts, ", ")
end

-- Item que representa o kit no ícone: o último da lista (a ferramenta ou a
-- mochila nos kits maiores).
local function iconItem(kit: Defs.KitDef): string
	return kit.items[#kit.items].id
end

local function buyButtons(kit: Defs.KitDef, points: () -> number, visible: () -> boolean): Frame
	local robux = ShopConfig.KIT_ROBUX[kit.id]
	local function canBuy(): boolean
		return KitRules.canBuy(kit, points())
	end
	local function third(order: number, props: { [any]: any }): TextButton
		props.LayoutOrder = order
		props.Size = UDim2.new(1 / 3, -BUTTON_GAP * 2 / 3, 1, 0)
		props.maxSize = 18
		return Rustic.button(props)
	end
	return create("Frame")({
		Name = "Buy",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Visible = visible,
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, BUTTON_GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		third(1, {
			Name = "Points",
			kind = function()
				return if canBuy() then "leather" else "disabled"
			end,
			text = Strings.format("kit.price", { price = kit.price }),
			subtext = function()
				if canBuy() then
					return Strings.get("kit.once")
				end
				return Strings.format("kit.missing", { points = kit.price - points() })
			end,
			Activated = function()
				if canBuy() then
					KitShop.choosePoints(kit.id)
				end
			end,
		}),
		third(2, {
			Name = "RobuxOnce",
			kind = "leather",
			text = Strings.format("kit.robux", { price = if robux then robux.once else 0 }),
			subtext = Strings.get("kit.once"),
			Activated = function()
				KitShop.buyOnce(kit.id)
			end,
		}),
		-- Já tem o kit para sempre (o "+" abriu as compras para mais saldo): "Comprado".
		third(3, {
			Name = "RobuxForever",
			kind = function()
				return if ShopData.kitOwned(kit.id) then "disabled" else "wood"
			end,
			text = function()
				if ShopData.kitOwned(kit.id) then
					return Strings.get("shop.bundle.bought")
				end
				return Strings.format("kit.robux", { price = if robux then robux.forever else 0 })
			end,
			subtext = Strings.get("kit.forever"),
			Activated = function()
				if not ShopData.kitOwned(kit.id) then
					KitShop.buyForever(kit.id)
				end
			end,
		}),
	}) :: Frame
end

local function useButton(kit: Defs.KitDef, visible: () -> boolean): TextButton
	return Rustic.button({
		Name = "Use",
		Size = UDim2.fromScale(1, 1),
		Visible = visible,
		kind = "success",
		text = function()
			return Strings.get(if ShopData.kitActive() == kit.id then "kit.active" else "kit.use")
		end,
		Activated = function()
			KitShop.toggleActive(kit.id)
		end,
	})
end

-- "Usar" do saldo de 1 vida: igual ao do kit para sempre; escolhido = "Ativo".
local function balanceUseButton(kit: Defs.KitDef, visible: () -> boolean): TextButton
	return Rustic.button({
		Name = "UseBalance",
		Size = UDim2.fromScale(1, 1),
		Visible = visible,
		kind = "success",
		text = function()
			local chosen = KitList.selected() == kit.id and KitList.source() == "balance"
			return Strings.get(if chosen then "kit.active" else "kit.use")
		end,
		Activated = function()
			KitShop.useBalance(kit.id)
		end,
	})
end

-- Canto da linha com o saldo de 1 vida ("×3") e o "+" que mostra as compras.
local function balanceCorner(kit: Defs.KitDef, expanded: (() -> boolean) & ((boolean) -> boolean)): Frame
	local function balance(): number
		return ShopData.kitBalance(kit.id)
	end
	return create("Frame")({
		Name = "Balance",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -10, 0, 8),
		Size = UDim2.fromOffset(CORNER_WIDTH, CORNER_HEIGHT),
		BackgroundTransparency = 1,
		Visible = function()
			return balance() > 0
		end,
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		-- Só o número, sem fundo (não cobre a descrição do kit).
		Rustic.label({
			Name = "Count",
			dark = true,
			LayoutOrder = 1,
			Size = UDim2.new(0, CORNER_WIDTH - CORNER_HEIGHT - 6, 1, 0),
			FontFace = Theme.font.number,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = function()
				return Strings.format("kit.uses", { n = balance() })
			end,
			maxSize = 18,
		}),
		-- "+" sem fundo (o botão de madeira tem 44 px de mínimo e cobria a descrição).
		create("TextButton")({
			Name = "More",
			LayoutOrder = 2,
			Size = UDim2.fromOffset(CORNER_HEIGHT, CORNER_HEIGHT),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			FontFace = Theme.font.number,
			TextSize = 26,
			TextColor3 = R.emberShadow,
			Text = function()
				return if expanded() then "−" else "+"
			end,
			Activated = function()
				expanded(not vide.untrack(expanded))
			end,
		}),
	}) :: Frame
end

local function row(kit: Defs.KitDef, points: () -> number, compact: () -> boolean): Frame
	local function isCurrent(): boolean
		local id = KitShop.current()
		return id == kit.id
	end
	-- Com saldo, o "+" troca o "Usar" pelas opções de compra.
	local expanded: (() -> boolean) & ((boolean) -> boolean) = vide.source(false) :: any
	local function owned(): boolean
		return ShopData.kitOwned(kit.id)
	end
	local function hasBalance(): boolean
		return ShopData.kitBalance(kit.id) > 0
	end
	vide.effect(function()
		-- Saldo acabou: volta ao jeito normal (compras à vista).
		if not hasBalance() then
			expanded(false)
		end
	end)
	-- Compras: sem nada para usar, ou quando o "+" (que só existe com saldo) abre.
	local function showBuy(): boolean
		return expanded() or (not owned() and not hasBalance())
	end
	local function showUse(): boolean
		return owned() and not expanded()
	end
	local function showBalanceUse(): boolean
		return not owned() and hasBalance() and not expanded()
	end
	local function iconSide(): number
		return if compact() then COMPACT_ICON else ICON
	end
	local function textLeft(): number
		return iconSide() + (if compact() then 16 else 20)
	end
	local icon = create("Frame")({
		Name = "Icon",
		Position = function()
			return if compact() then UDim2.fromOffset(8, 6) else UDim2.fromOffset(10, 8)
		end,
		Size = function()
			return UDim2.fromOffset(iconSide(), iconSide())
		end,
		BackgroundTransparency = 1,
	}) :: Frame
	ItemIcon({
		item = function()
			return { id = iconItem(kit), count = 1 }
		end,
	}).Parent = icon

	return create("Frame")({
		Name = kit.id,
		LayoutOrder = kit.order,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = R.paperLight,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return if isCurrent() then R.ember else R.paperShadow
			end,
			Thickness = function()
				return if isCurrent() then SELECTED_STROKE else 2
			end,
		}),
		icon,
		Rustic.label({
			Name = "Name",
			dark = true,
			Position = function()
				return UDim2.fromOffset(textLeft(), if compact() then 4 else 8)
			end,
			Size = function()
				return UDim2.new(1, -(textLeft() + 10 + CORNER_WIDTH), 0, if compact() then 20 else 24)
			end,
			FontFace = Theme.font.number,
			Text = Strings.get(kit.nameKey),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 20,
		}),
		balanceCorner(kit, expanded),
		Rustic.label({
			Name = "Items",
			Position = function()
				return UDim2.fromOffset(textLeft(), if compact() then 24 else 32)
			end,
			-- Até 2 linhas; encolhe se precisar.
			Size = function()
				return UDim2.new(1, -(textLeft() + 10), 0, if compact() then 28 else 32)
			end,
			FontFace = Theme.font.body,
			TextColor3 = R.textSecondaryLight,
			Text = itemsText(kit),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			TextWrapped = true,
			maxSize = 14,
		}),
		create("Frame")({
			Name = "Actions",
			Position = function()
				return if compact()
					then UDim2.new(0, 6, 1, -(COMPACT_BUTTONS + 6))
					else UDim2.new(0, 10, 1, -(BUTTONS_HEIGHT + 8))
			end,
			Size = function()
				return if compact() then UDim2.new(1, -12, 0, COMPACT_BUTTONS) else UDim2.new(1, -20, 0, BUTTONS_HEIGHT)
			end,
			BackgroundTransparency = 1,
			buyButtons(kit, points, showBuy) :: Instance,
			useButton(kit, showUse) :: Instance,
			balanceUseButton(kit, showBalanceUse) :: Instance,
		}),
	}) :: Frame
end

-- Monta o painel (chamar dentro de um root Vide). `compact`: celular deitado;
-- `height`: altura do painel em px lógicos (quem chama posiciona).
function KitsPanel.build(compact: () -> boolean, height: () -> number): Frame
	local points = Sources.attribute(Players.LocalPlayer, StatNames.KitPoints, 0)
	local function pad(): number
		return if compact() then COMPACT_PADDING else PADDING
	end
	local function pointsRow(): number
		return if compact() then COMPACT_POINTS_ROW else POINTS_ROW
	end
	-- Do topo do painel até a lista (título, pontos e folgas).
	local function listTop(): number
		return pad() + HEADER + pointsRow() + (if compact() then 0 else 8)
	end
	local function pointsTop(): number
		return pad() + HEADER - (if compact() then 4 else 0)
	end
	local function listHeight(): number
		return height() - listTop() - pad()
	end
	-- Uma coluna no PC (linhas de ROW_HEIGHT); duas no celular, com a altura
	-- dividida entre duas fileiras.
	local rows: { Instance } = {
		create("UIGridLayout")({
			CellPadding = UDim2.fromOffset(ROW_GAP, ROW_GAP),
			CellSize = function()
				if not compact() then
					return UDim2.new(1, 0, 0, ROW_HEIGHT)
				end
				local rowHeight = (listHeight() - (COMPACT_ROWS - 1) * ROW_GAP) / COMPACT_ROWS
				return UDim2.new(0.5, -ROW_GAP / 2 - 1, 0, math.max(rowHeight, COMPACT_ROW_MIN))
			end,
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		create("UIPadding")({ PaddingRight = UDim.new(0, 6) }), -- espaço da barra de rolagem
	}
	for _, kit in KitRules.sorted(Defs.Kits) do
		local line = row(kit, points, compact)
		-- Kit só de conquista: só aparece para quem tem a posse.
		if kit.exclusive then
			vide.effect(function()
				line.Visible = ShopData.kitOwned(kit.id)
			end)
		end
		table.insert(rows, line)
	end
	return Rustic.paper({
		Name = "KitsPanel",
		Rustic.label({
			Name = "Title",
			dark = true,
			Position = function()
				return UDim2.fromOffset(pad(), pad() - 4)
			end,
			Size = function()
				return UDim2.new(1, -(pad() * 2 + HEADER + 8), 0, HEADER)
			end,
			FontFace = Theme.font.title,
			Text = Strings.get("kit.panel.title"),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 28,
		}),
		Rustic.button({
			Name = "Close",
			AnchorPoint = Vector2.new(1, 0),
			Position = function()
				return UDim2.new(1, -pad(), 0, pad() - 4)
			end,
			Size = UDim2.fromOffset(HEADER, HEADER),
			kind = "wood",
			text = "X",
			Activated = function()
				MenuState.open("play")
			end,
		}),
		Rustic.label({
			Name = "Points",
			dark = true,
			Position = function()
				return UDim2.fromOffset(pad(), pointsTop())
			end,
			Size = function()
				return UDim2.new(1, -pad() * 2, 0, pointsRow())
			end,
			FontFace = Theme.font.label,
			TextColor3 = R.textSecondaryLight,
			Text = function()
				return Strings.format("kit.yourPoints", { points = points() })
			end,
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 18,
		}),
		create("ScrollingFrame")({
			Name = "List",
			Position = function()
				return UDim2.fromOffset(pad(), listTop())
			end,
			Size = function()
				return UDim2.new(1, -pad() * 2, 1, -(listTop() + pad()))
			end,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromScale(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = R.walnut,
			rows,
		}),
	})
end

return KitsPanel
