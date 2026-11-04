--!strict
-- Tela do giro de um tipo de skin (abre por ShopState.openSpin). No alto, o
-- carrossel passando devagar (Reel); embaixo, os dois lados:
--   giro com Golden Ember (chances baixas) e giro especial com Robux (altas),
--   cada um com as chances, "Você tem N giros", comprar +1/+3/+10 e GIRAR.
-- Girar acontece aqui mesmo: o carrossel para no prêmio e abre só uma
-- janelinha com a skin. Tudo simulado (nada é cobrado nem salvo).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local ShopLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("ShopLayout"))
local SpinRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("SpinRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))
local ShopState = require(script.Parent:WaitForChild("ShopState"))
local SpinTile = require(script.Parent:WaitForChild("SpinTile"))
local Reel = require(script.Parent:WaitForChild("Reel"))

local create = vide.create
local R = Theme.rustic

local BOX_MAX_WIDTH = 980
local TITLE_ROW = 50
local TILE = 100
local TILE_COMPACT = 80
local TILE_GAP = 8
local SIDE_HEIGHT = 260
local WON_TILE = 170
local NORMAL_THEME = Color3.fromHex("#6B4A2E")
local PAID_THEME = Color3.fromHex("#7A4FD8")

export type Won = { item: MockStore.SpinItem, typeId: string, paid: boolean }
export type Hooks = {
	-- Efeitos do giro pago (Task 7). start devolve a função que para tudo.
	startPaid: ((box: GuiObject, window: GuiObject) -> () -> ())?,
	land: ((box: GuiObject) -> ())?,
	celebrate: ((popup: GuiObject, rarity: number, paid: boolean) -> ())?,
}

local SpinScreen = {}

local function typeOf(typeId: string): MockStore.SpinType?
	for _, spinType in MockStore.SPIN_TYPES do
		if spinType.id == typeId then
			return spinType
		end
	end
	return nil
end

local function rarityColor(rarity: number): Color3
	return Theme.tier[MockStore.RARITIES[rarity]]
end

-- Linha das chances: uma célula por raridade, na cor dela.
local function oddsRow(odds: { number }): Frame
	local cells: { Instance } = {
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}) :: Instance,
	}
	for i, value in odds do
		local name = Strings.get(Defs.Tiers[MockStore.RARITIES[i]].rarityKey)
		table.insert(
			cells,
			create("Frame")({
				LayoutOrder = i,
				Size = UDim2.new(1 / #odds, -4, 1, 0),
				BackgroundColor3 = rarityColor(i),
				BorderSizePixel = 0,
				create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
				create("UIStroke")({
					Color = R.outline,
					Thickness = 1.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
				Rustic.label({
					Position = UDim2.fromScale(0.05, 0.04),
					Size = UDim2.fromScale(0.9, 0.55),
					dark = true,
					FontFace = Theme.font.number,
					Text = `{value}%`,
					maxSize = 16,
				}),
				Rustic.label({
					Position = UDim2.fromScale(0.05, 0.58),
					Size = UDim2.fromScale(0.9, 0.38),
					dark = true,
					Text = name,
					maxSize = 11,
				}),
			})
		)
	end
	return create("Frame")({
		Name = "Odds",
		Size = UDim2.new(1, 0, 0, 42),
		BackgroundTransparency = 1,
		cells,
	}) :: Frame
end

-- Um lado da tela (normal ou pago).
local function side(
	kind: SpinRules.Kind,
	typeId: () -> string?,
	currency: () -> number,
	onSpin: (SpinRules.Kind) -> (),
	order: number
): Frame
	local paid = kind == "paid"
	local prices: { MockStore.SpinPrice } = if paid then MockStore.SPIN_PRICES.paid else MockStore.SPIN_PRICES.normal
	local function count(): number
		local id = typeId()
		local entry = if id then ShopState.counts()[id] else nil
		return if entry then entry[kind] else 0
	end

	local buyCells: { Instance } = {
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 8),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}) :: Instance,
	}
	for i, offer in prices do
		table.insert(
			buyCells,
			create("Frame")({
				Name = "Buy" .. offer.qty,
				LayoutOrder = i,
				Size = UDim2.new(1 / #prices, -8, 1, 0),
				BackgroundTransparency = 1,
				ShopParts.outlined({
					Size = UDim2.fromScale(1, 0.34),
					FontFace = Theme.font.number,
					Text = Strings.format("shop.spin.buy", { qty = offer.qty }),
					maxSize = 18,
				}) :: Instance,
				ShopParts.priceButton({
					robux = if paid then offer.price else nil,
					ember = if paid then nil else offer.price,
					missing = if paid
						then nil
						else function()
							return math.max(offer.price - currency(), 0)
						end,
					onClick = function()
						local id = vide.untrack(typeId)
						if id then
							ShopState.buySpins(id, kind, offer.qty, offer.price)
						end
					end,
					position = UDim2.fromScale(0, 0.36),
					size = UDim2.fromScale(1, 0.64),
					textSize = 20,
				}),
			})
		)
	end

	return ShopParts.vividCard(if paid then PAID_THEME else NORMAL_THEME, {
		Name = if paid then "Paid" else "Normal",
		LayoutOrder = order,
		if paid then ShopParts.ribbon(Strings.get("shop.spin.chance"), Theme.tier.gold, R.charcoal) else nil,
		create("Frame")({
			Name = "Content",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 3,
			create("UIPadding")({
				PaddingLeft = UDim.new(0, 14),
				PaddingRight = UDim.new(0, 14),
				PaddingTop = UDim.new(0, 10),
				PaddingBottom = UDim.new(0, 12),
			}),
			create("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			ShopParts.outlined({
				LayoutOrder = 1,
				Size = UDim2.new(1, 0, 0, 28),
				FontFace = Theme.font.number,
				Text = Strings.get(if paid then "shop.spin.paid" else "shop.spin.normal"),
				maxSize = 24,
			}),
			(function()
				local row = oddsRow(if paid then MockStore.SPIN_ODDS.paid else MockStore.SPIN_ODDS.normal)
				row.LayoutOrder = 2
				return row
			end)(),
			ShopParts.outlined({
				LayoutOrder = 3,
				Size = UDim2.new(1, 0, 0, 22),
				FontFace = Theme.font.number,
				Text = function()
					return Strings.format("shop.spin.have", { count = count() })
				end,
				maxSize = 20,
			}),
			create("Frame")({
				Name = "Buy",
				LayoutOrder = 4,
				Size = UDim2.new(1, 0, 0, 62),
				BackgroundTransparency = 1,
				buyCells,
			}),
			Rustic.button({
				Name = "Spin",
				LayoutOrder = 5,
				Size = UDim2.new(0.7, 0, 0, 48),
				kind = function()
					return if count() > 0 and not ShopState.spinning() then "ember" else "disabled"
				end,
				text = Strings.get("shop.spin.go"),
				maxSize = 26,
				Activated = function()
					onSpin(kind)
				end,
			}),
		}),
	})
end

-- Monta a tela do giro (dentro da loja). `open` = loja aberta.
function SpinScreen.build(
	layout: () -> ShopLayout.Layout,
	screenSize: () -> Vector2,
	open: () -> boolean,
	hooks: Hooks
): Frame
	local currency = Sources.attribute(Players.LocalPlayer, StatNames.Currency, 0)
	local won: (() -> Won?) & ((Won?) -> Won?) = vide.source(nil :: Won?) :: any
	local rng = Random.new()

	local function tileSize(): number
		return if layout().compact then TILE_COMPACT else TILE
	end

	local window = create("Frame")({
		Name = "ReelWindow",
		LayoutOrder = 2,
		Size = function()
			return UDim2.new(1, 0, 0, tileSize() + 24)
		end,
		BackgroundColor3 = Color3.fromHex("#1A130D"),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		create("UIStroke")({ Color = R.woodShadow, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		-- Marcador dourado no meio.
		create("Frame")({
			Name = "Marker",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.new(0, 4, 1, 0),
			BackgroundColor3 = Theme.tier.gold,
			BorderSizePixel = 0,
			ZIndex = 10,
		}),
	}) :: Frame

	local box: Frame
	local popup: Frame
	local reel: Reel.Reel? = nil
	local stopFx: (() -> ())? = nil

	local function stopEffects()
		if stopFx then
			stopFx()
			stopFx = nil
		end
	end

	-- Um carrossel por tela aberta; fechar (ou sair da loja) destrói tudo.
	vide.effect(function()
		local id = ShopState.spinType()
		local isOpen = open()
		if reel then
			reel:destroy()
			reel = nil
		end
		stopEffects()
		if not isOpen and id ~= nil then
			-- Saiu da loja com a tela aberta: fecha e destrava.
			task.defer(function()
				ShopState.spinning(false)
				ShopState.spinType(nil)
				won(nil)
			end)
			return
		end
		local spinType = if id then typeOf(id) else nil
		if spinType then
			reel = Reel.new(window, spinType, vide.untrack(tileSize), TILE_GAP)
		end
	end)

	local function spin(kind: SpinRules.Kind)
		local id = vide.untrack(ShopState.spinType)
		local spinType = if id then typeOf(id) else nil
		local current = reel
		if spinType == nil or current == nil or not ShopState.useSpin(spinType.id, kind) then
			return
		end
		ShopState.spinning(true)
		local paid = kind == "paid"
		local odds = if paid then MockStore.SPIN_ODDS.paid else MockStore.SPIN_ODDS.normal
		local rarity = SpinRules.pickIndex(odds, rng:NextNumber())
		local prize = SpinRules.pickItem(spinType.items, rarity, rng:NextNumber())
		if paid and hooks.startPaid then
			stopFx = hooks.startPaid(box, window)
		end
		current:spinTo(prize, function()
			stopEffects()
			if paid and hooks.land then
				hooks.land(box)
			end
			ShopState.spinning(false)
			won({ item = prize, typeId = spinType.id, paid = paid })
		end)
	end

	-- Janelinha do prêmio: refeita a cada prêmio.
	local prizeHolder = create("Frame")({
		Name = "Prize",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.2),
		Size = UDim2.fromOffset(WON_TILE, WON_TILE),
		BackgroundTransparency = 1,
		ZIndex = 32,
	}) :: Frame
	local prizeName = ShopParts.outlined({
		Name = "PrizeName",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0.2, WON_TILE + 10),
		Size = UDim2.new(0.9, 0, 0, 30),
		FontFace = Theme.font.number,
		RichText = true,
		Text = "",
		maxSize = 26,
		ZIndex = 32,
	})
	popup = create("Frame")({
		Name = "WonPopup",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(340, 340),
		BackgroundColor3 = Color3.fromHex("#2B2018"),
		BorderSizePixel = 0,
		ZIndex = 30,
		create("UICorner")({ CornerRadius = UDim.new(0, 14) }),
		create("UIStroke")({ Color = Theme.tier.gold, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		ShopParts.outlined({
			Position = UDim2.fromScale(0.05, 0.04),
			Size = UDim2.new(0.9, 0, 0, 36),
			FontFace = Theme.font.title,
			Text = Strings.get("shop.spin.won"),
			maxSize = 32,
			ZIndex = 32,
		}),
		prizeHolder,
		prizeName,
		Rustic.button({
			Name = "Take",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -14),
			Size = UDim2.fromOffset(170, 48),
			ZIndex = 32,
			kind = "ember",
			text = Strings.get("shop.spin.take"),
			Activated = function()
				won(nil)
				if reel then
					reel:idle()
				end
			end,
		}),
	}) :: Frame

	vide.effect(function()
		local result = won()
		prizeHolder:ClearAllChildren()
		if result == nil then
			return
		end
		local tile = SpinTile.build(result.item, result.typeId, WON_TILE)
		tile.ZIndex = 32
		tile.Parent = prizeHolder
		local rarityName = Strings.get(Defs.Tiers[MockStore.RARITIES[result.item.rarity]].rarityKey)
		prizeName.Text =
			`{Strings.get(result.item.nameKey)} · <font color="#{rarityColor(result.item.rarity):ToHex()}">{rarityName}</font>`
		if hooks.celebrate then
			hooks.celebrate(popup, result.item.rarity, result.paid)
		end
	end)

	local sidesList = create("UIListLayout")({
		FillDirection = function()
			return if layout().spinSideBySide then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
		end,
		Padding = UDim.new(0, 12),
		SortOrder = Enum.SortOrder.LayoutOrder,
	}) :: UIListLayout

	local function sideSize(): UDim2
		return if layout().spinSideBySide then UDim2.new(0.5, -6, 0, SIDE_HEIGHT) else UDim2.new(1, -8, 0, SIDE_HEIGHT)
	end
	local normalSide = side("normal", ShopState.spinType, currency, spin, 1)
	local paidSide = side("paid", ShopState.spinType, currency, spin, 2)
	vide.apply(normalSide)({ Size = sideSize })
	vide.apply(paidSide)({ Size = sideSize })

	box = create("Frame")({
		Name = "SpinBox",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = function()
			return UDim2.new(0.5, 0, 0, layout().contentTop)
		end,
		Size = function()
			local l = layout()
			return UDim2.fromOffset(
				math.min(l.contentWidth, BOX_MAX_WIDTH),
				screenSize().Y - l.contentTop - ShopLayout.MARGIN
			)
		end,
		BackgroundColor3 = Color3.fromHex("#2B2018"),
		BorderSizePixel = 0,
		ZIndex = 21,
		create("UICorner")({ CornerRadius = UDim.new(0, 14) }),
		create("UIStroke")({ Color = R.woodEdge, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		create("UIPadding")({
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 12),
		}),
		create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 10) }),
		create("Frame")({
			Name = "TitleRow",
			LayoutOrder = 1,
			Size = UDim2.new(1, 0, 0, TITLE_ROW),
			BackgroundTransparency = 1,
			ShopParts.outlined({
				Size = UDim2.new(1, -60, 1, 0),
				FontFace = Theme.font.title,
				Text = function()
					local id = ShopState.spinType()
					local spinType = if id then typeOf(id) else nil
					local typeName = if spinType then Strings.get(spinType.nameKey) else ""
					return Strings.format("shop.spin.title", { type = typeName })
				end,
				TextXAlignment = Enum.TextXAlignment.Left,
				maxSize = 34,
			}) :: Instance,
			Rustic.button({
				Name = "Close",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(46, 46),
				kind = function()
					return if ShopState.spinning() then "disabled" else "wood"
				end,
				text = "X",
				Activated = function()
					ShopState.openSpin(nil)
				end,
			}),
		}),
		window,
		create("ScrollingFrame")({
			Name = "Sides",
			LayoutOrder = 3,
			Size = function()
				return UDim2.new(1, 0, 1, -(TITLE_ROW + tileSize() + 24 + 20))
			end,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.fromScale(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			ScrollBarThickness = 5,
			ScrollBarImageColor3 = R.woodEdge,
			create("UIPadding")({
				PaddingTop = UDim.new(0, 6),
				PaddingLeft = UDim.new(0, 4),
				PaddingRight = UDim.new(0, 4),
			}),
			sidesList,
			normalSide,
			paidSide,
		}),
	}) :: Frame

	return create("Frame")({
		Name = "SpinScreen",
		Visible = function()
			return ShopState.spinType() ~= nil and open()
		end,
		Size = UDim2.new(1, 0, 1, 200),
		Position = UDim2.fromOffset(0, -100),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.35,
		Active = true, -- não deixa o clique passar para a loja atrás
		ZIndex = 20,
		create("Frame")({
			Name = "Inner",
			Position = UDim2.fromOffset(0, 100),
			Size = UDim2.new(1, 0, 1, -200),
			BackgroundTransparency = 1,
			ZIndex = 20,
			box,
			create("Frame")({
				Name = "WonOverlay",
				Visible = function()
					return won() ~= nil
				end,
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.4,
				Active = true,
				ZIndex = 29,
				popup,
			}),
		}),
	}) :: Frame
end

return SpinScreen
