--!strict
-- Painel "ESCOLHA SEU KIT" (UI 1): folha de papel à direita do boneco, uma
-- linha por kit com os três jeitos de levar o kit:
--   pontos · 1 vida (de verdade)   Robux · 1 vida   Robux · para sempre (mockup)
-- Kit permanente troca os três por um botão verde "Usar" / "Ativo".
-- O kit que vai nesta vida (KitShop.current) ganha a borda de brasa.
-- Quem chama posiciona e dimensiona o painel (MenuShell, pelo MenuLayout).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local KitRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("KitRules"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local ItemIcon = require(Client:WaitForChild("UI"):WaitForChild("ItemIcon"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local KitShop = require(script.Parent:WaitForChild("KitShop"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))

local create = vide.create
local R = Theme.rustic

local PADDING = 16
local HEADER = 44 -- título + fechar (alvo de toque)
local POINTS_ROW = 24
local ROW_HEIGHT = 116
local ROW_GAP = 8
local ICON = 52
local BUTTONS_HEIGHT = 48
local BUTTON_GAP = 6
local SELECTED_STROKE = 3

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

local function buyButtons(kit: Defs.KitDef, points: () -> number): Frame
	local robux = MockStore.KIT_ROBUX[kit.id]
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
		Visible = function()
			return KitShop.state().owned[kit.id] ~= true
		end,
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
		third(3, {
			Name = "RobuxForever",
			kind = "wood",
			text = Strings.format("kit.robux", { price = if robux then robux.forever else 0 }),
			subtext = Strings.get("kit.forever"),
			Activated = function()
				KitShop.buyForever(kit.id)
			end,
		}),
	}) :: Frame
end

local function useButton(kit: Defs.KitDef): TextButton
	return Rustic.button({
		Name = "Use",
		Size = UDim2.fromScale(1, 1),
		Visible = function()
			return KitShop.state().owned[kit.id] == true
		end,
		kind = "success",
		text = function()
			return Strings.get(if KitShop.state().active == kit.id then "kit.active" else "kit.use")
		end,
		Activated = function()
			KitShop.toggleActive(kit.id)
		end,
	})
end

local function row(kit: Defs.KitDef, points: () -> number): Frame
	local function isCurrent(): boolean
		local id = KitShop.current()
		return id == kit.id
	end
	local icon = create("Frame")({
		Name = "Icon",
		Position = UDim2.fromOffset(10, 8),
		Size = UDim2.fromOffset(ICON, ICON),
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
			Position = UDim2.fromOffset(ICON + 20, 8),
			Size = UDim2.new(1, -(ICON + 30), 0, 24),
			FontFace = Theme.font.number,
			Text = Strings.get(kit.nameKey),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 20,
		}),
		Rustic.label({
			Name = "Items",
			Position = UDim2.fromOffset(ICON + 20, 34),
			Size = UDim2.new(1, -(ICON + 30), 0, 26),
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
			Position = UDim2.new(0, 10, 1, -(BUTTONS_HEIGHT + 8)),
			Size = UDim2.new(1, -20, 0, BUTTONS_HEIGHT),
			BackgroundTransparency = 1,
			buyButtons(kit, points) :: Instance,
			useButton(kit) :: Instance,
		}),
	}) :: Frame
end

-- Monta o painel (chamar dentro de um root Vide).
function KitsPanel.build(): Frame
	local points = Sources.attribute(Players.LocalPlayer, StatNames.KitPoints, 0)
	local rows: { Instance } = {
		create("UIListLayout")({ Padding = UDim.new(0, ROW_GAP), SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding")({ PaddingRight = UDim.new(0, 6) }), -- espaço da barra de rolagem
	}
	for _, kit in KitRules.sorted(Defs.Kits) do
		table.insert(rows, row(kit, points))
	end
	return Rustic.paper({
		Name = "KitsPanel",
		Rustic.label({
			Name = "Title",
			dark = true,
			Position = UDim2.fromOffset(PADDING, PADDING - 4),
			Size = UDim2.new(1, -(PADDING * 2 + HEADER + 8), 0, HEADER),
			FontFace = Theme.font.title,
			Text = Strings.get("kit.panel.title"),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 28,
		}),
		Rustic.button({
			Name = "Close",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -PADDING, 0, PADDING - 4),
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
			Position = UDim2.fromOffset(PADDING, PADDING + HEADER),
			Size = UDim2.new(1, -PADDING * 2, 0, POINTS_ROW),
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
			Position = UDim2.fromOffset(PADDING, PADDING + HEADER + POINTS_ROW + 8),
			Size = UDim2.new(1, -PADDING * 2, 1, -(PADDING * 2 + HEADER + POINTS_ROW + 8)),
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
