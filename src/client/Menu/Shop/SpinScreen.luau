--!strict
-- Tela do giro de um tipo de skin (abre por ShopState.openSpin). No alto, o
-- carrossel passando devagar (Reel); embaixo, os dois lados:
--   giro com Golden Ember (chances baixas) e giro especial com Robux (altas),
--   cada um com as chances, "Você tem N giros", comprar +1/+3/+10 e GIRAR.
-- Girar acontece aqui mesmo: o carrossel para no prêmio e abre só uma
-- janelinha com a skin. Os saldos de giros são do jogador (um normal e um
-- especial, que servem em qualquer roleta); o sorteio e a entrega são do
-- servidor (Net.RequestSpin → SpinResult); o carrossel anima até o prêmio
-- que o servidor mandou. Repetida devolve Golden Ember (mostrado no prêmio).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local ShopConfig = require(Shared:WaitForChild("Shop"):WaitForChild("ShopConfig"))
local ShopLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("ShopLayout"))
local SpinRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("SpinRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local ShopData = require(Client:WaitForChild("ShopData"))
local Net = require(Client:WaitForChild("Net"))
local MenuState = require(script.Parent.Parent:WaitForChild("MenuState"))
local Purchase = require(script.Parent.Parent:WaitForChild("Purchase"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))
local ShopState = require(script.Parent:WaitForChild("ShopState"))
local SpinTile = require(script.Parent:WaitForChild("SpinTile"))
local Reel = require(script.Parent:WaitForChild("Reel"))

local create = vide.create
local R = Theme.rustic

local BOX_MAX_WIDTH = 980
local TILE_GAP = 8
local WON_TILE = 170
local NORMAL_THEME = Color3.fromHex("#6B4A2E")
local PAID_THEME = Color3.fromHex("#7A4FD8")

export type Won = { item: MockStore.SpinItem, typeId: string, paid: boolean, refund: number }
-- Sons de um giro (SpinSounds): frame a cada quadro, land ao parar, stop se fechar.
export type SoundSession = {
	frame: (progress: number, tile: number) -> (),
	land: () -> (),
	stop: () -> (),
}
export type Hooks = {
	sounds: ((rarity: number, paid: boolean) -> SoundSession)?,
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
	return Color3.fromHex(MockStore.RARITIES[rarity].color)
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
		local name = Strings.get(MockStore.RARITIES[i].nameKey)
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

-- Um lado da tela (normal ou pago). O saldo é o mesmo em qualquer roleta.
local function side(
	kind: SpinRules.Kind,
	_typeId: () -> string?,
	currency: () -> number,
	onSpin: (SpinRules.Kind) -> (),
	order: number,
	layout: () -> ShopLayout.Layout
): Frame
	local paid = kind == "paid"
	-- Compacto (celular): 3 linhas — título com o contador, chances, e
	-- comprar +1/+3/+10 com o GIRAR na mesma linha.
	local function compact(): boolean
		return layout().compact
	end
	local prices: { ShopConfig.SpinPack } = ShopConfig.SPIN_PACKS[kind]
	-- Saldo único do jogador (serve em qualquer roleta).
	local function count(): number
		return ShopData.spins(kind)
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
				Size = function()
					local n = if compact() then #prices + 1 else #prices
					return UDim2.new(1 / n, -8, 1, 0)
				end,
				BackgroundTransparency = 1,
				ShopParts.outlined({
					Size = UDim2.fromScale(1, 0.24),
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
						Purchase.buy(`spins_{kind}_{offer.qty}`)
					end,
					position = UDim2.fromScale(0, 0.26),
					size = UDim2.fromScale(1, 0.74),
					textSize = 20,
				}),
			})
		)
	end

	local function spinKind(): Rustic.Kind
		return if count() > 0 and not ShopState.spinning() then "ember" else "disabled"
	end
	-- GIRAR dentro da linha de compra (só no compacto), com o contador no texto.
	table.insert(
		buyCells,
		create("Frame")({
			Name = "SpinCell",
			LayoutOrder = #prices + 1,
			Visible = compact,
			Size = UDim2.new(1 / (#prices + 1), -8, 1, 0),
			BackgroundTransparency = 1,
			Rustic.button({
				Name = "Spin",
				Position = UDim2.fromScale(0, 0.26),
				Size = UDim2.fromScale(1, 0.74),
				kind = spinKind,
				text = function()
					return `{Strings.get("shop.spin.go")} · {count()}`
				end,
				maxSize = 18,
				Activated = function()
					onSpin(kind)
				end,
			}),
		})
	)

	return ShopParts.vividCard(if paid then PAID_THEME else NORMAL_THEME, {
		art = if paid then "purple" else nil,
		Name = if paid then "Paid" else "Normal",
		LayoutOrder = order,
		if paid then ShopParts.ribbon(Strings.get("shop.spin.chance"), Theme.tier.gold, R.charcoal) else nil,
		create("Frame")({
			Name = "Content",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 3,
			create("UIPadding")({
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 12),
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
			}),
			create("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = function()
					return UDim.new(0, if compact() then 4 else 8)
				end,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			ShopParts.outlined({
				LayoutOrder = 1,
				Size = function()
					return UDim2.new(1, 0, 0, if compact() then 20 else 28)
				end,
				FontFace = Theme.font.number,
				Text = function()
					local title = Strings.get(if paid then "shop.spin.paid" else "shop.spin.normal")
					return if compact() then `{title} · {count()}` else title
				end,
				maxSize = 24,
			}),
			(function()
				local row = oddsRow(ShopConfig.SPIN_ODDS[kind])
				row.LayoutOrder = 2
				vide.apply(row)({
					Size = function()
						return UDim2.new(1, 0, 0, if compact() then 28 else 42)
					end,
				})
				return row
			end)(),
			ShopParts.outlined({
				LayoutOrder = 3,
				Visible = function()
					return not compact()
				end,
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
				Size = UDim2.new(1, 0, 0, 62), -- "+N" em cima e o botão (44+) embaixo
				BackgroundTransparency = 1,
				buyCells,
			}),
			Rustic.button({
				Name = "Spin",
				LayoutOrder = 5,
				Visible = function()
					return not compact()
				end,
				Size = UDim2.new(0.7, 0, 0, 48),
				kind = spinKind,
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

	local function tileSize(): number
		return layout().spinTile
	end

	local window = create("Frame")({
		Name = "ReelWindow",
		LayoutOrder = 2,
		Size = function()
			return UDim2.new(1, 0, 0, tileSize() + ShopLayout.SPIN_REEL_EXTRA)
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
	local sound: SoundSession? = nil

	local function stopEffects()
		if stopFx then
			stopFx()
			stopFx = nil
		end
	end

	local function stopSound()
		if sound then
			sound.stop()
			sound = nil
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
		stopSound()
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

	-- Anima o carrossel até o prêmio que o servidor sorteou.
	local function play(spinType: MockStore.SpinType, prize: MockStore.SpinItem, paid: boolean, refund: number)
		local current = reel
		if current == nil then
			ShopState.spinning(false)
			return
		end
		if paid and hooks.startPaid then
			stopFx = hooks.startPaid(box, window)
		end
		-- Os sons seguem a raridade do item que vai sair (o suspense cresce com ela).
		local session = if hooks.sounds then hooks.sounds(prize.rarity, paid) else nil
		sound = session
		current:spinTo(prize, function()
			stopEffects()
			if session then
				session.land()
				if sound == session then
					sound = nil
				end
			end
			if paid and hooks.land then
				hooks.land(box)
			end
			ShopState.spinning(false)
			won({ item = prize, typeId = spinType.id, paid = paid, refund = refund })
		end, if session then session.frame else nil)
	end

	-- GIRAR: pede o giro ao servidor e trava até a resposta (SpinResult).
	local function spin(kind: SpinRules.Kind)
		local id = vide.untrack(ShopState.spinType)
		local spinType = if id then typeOf(id) else nil
		if spinType == nil or reel == nil or vide.untrack(ShopState.spinning) then
			return
		end
		if vide.untrack(function()
			return ShopData.spins(kind)
		end) < 1 then
			return
		end
		ShopState.spinning(true)
		Net.RequestSpin.Fire({ TypeId = spinType.id, Paid = kind == "paid" })
	end

	Net.SpinResult.On(function(result)
		local spinType = typeOf(result.TypeId)
		local prize: MockStore.SpinItem? = nil
		if spinType and result.Ok and result.ItemId then
			for _, item in spinType.items do
				if item.id == result.ItemId then
					prize = item
					break
				end
			end
		end
		-- A tela pode ter fechado (ou trocado de roleta) enquanto esperava.
		if spinType == nil or prize == nil or vide.untrack(ShopState.spinType) ~= result.TypeId then
			ShopState.spinning(false)
			if not result.Ok then
				MenuState.notify(Strings.get("shop.spin.failed"))
			end
			return
		end
		play(spinType, prize, result.Paid, result.Refund)
	end)

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
		Size = UDim2.new(0.9, 0, 0, 52), -- nome e, se repetida, a devolução
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
		local tile = SpinTile.build(result.item, WON_TILE)
		tile.ZIndex = 32
		tile.Parent = prizeHolder
		local rarityName = Strings.get(MockStore.RARITIES[result.item.rarity].nameKey)
		prizeName.Text =
			`{Strings.get(result.item.nameKey)} · <font color="#{rarityColor(result.item.rarity):ToHex()}">{rarityName}</font>`
		-- Repetida: o servidor devolveu Golden Ember no lugar da skin.
		if result.refund > 0 then
			prizeName.Text ..= `\n{Strings.format("shop.spin.duplicate", { amount = result.refund })}`
		end
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
		return UDim2.new(0.5, -6, 0, layout().spinSideHeight)
	end
	local normalSide = side("normal", ShopState.spinType, currency, spin, 1, layout)
	local paidSide = side("paid", ShopState.spinType, currency, spin, 2, layout)
	vide.apply(normalSide)({ Size = sideSize })
	vide.apply(paidSide)({ Size = sideSize })

	box = create("Frame")({
		Name = "SpinBox",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = function()
			return UDim2.new(0.5, 0, 0, layout().spinBoxTop)
		end,
		Size = function()
			local l = layout()
			return UDim2.fromOffset(
				math.min(l.contentWidth, BOX_MAX_WIDTH),
				screenSize().Y - l.spinBoxTop - ShopLayout.MARGIN
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
			PaddingTop = UDim.new(0, ShopLayout.SPIN_PADDING),
			PaddingBottom = UDim.new(0, ShopLayout.SPIN_PADDING),
		}),
		create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, ShopLayout.SPIN_GAP) }),
		create("Frame")({
			Name = "TitleRow",
			LayoutOrder = 1,
			Size = function()
				return UDim2.new(1, 0, 0, layout().spinTitleRow)
			end,
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
				Size = UDim2.fromOffset(44, 44),
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
				local l = layout()
				return UDim2.new(
					1,
					0,
					1,
					-(l.spinTitleRow + l.spinTile + ShopLayout.SPIN_REEL_EXTRA + 2 * ShopLayout.SPIN_GAP)
				)
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
