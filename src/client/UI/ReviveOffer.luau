--!strict
-- Painel da oferta de revive, por cima do resumo da tela de morte: ícone, preço
-- em Robux (ou a fita GRÁTIS, para o revive grátis do VIP e o guardado), o botão
-- REVIVER e "Não, obrigado". Sem contador (o limite é escondido, do servidor).
-- Cada peça usa a arte de MonetizationImages quando o id existe e, senão, o
-- desenho feito por código (mesmo padrão da loja com ShopImages).
-- O retângulo da oferta (DeathLayout.offer) é só o escurecido que come o
-- toque; o painel desenhado (arte 06 em 9 partes) tem o tamanho do conteúdo e
-- fica no meio dele (DeathLayout.offerCard), sem espaço morto.
-- Composições (DeathLayout): em coluna (PC grande, com ícone de ~96 px;
-- telas médias com o ícone pequeno ou sem ele) e em linha (celular deitado na
-- maior escala): título e preço lado a lado, REVIVER e "Não, obrigado" lado a
-- lado. As medidas vêm do DeathLayout.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local DeathLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("DeathLayout"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local ScreenState = require(Client:WaitForChild("ScreenState"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create
local R = Theme.rustic

local PANEL_BODY = Color3.fromHex("#2B2018")
local COVER = Color3.fromHex("#140E0A")
local PANEL_SLICE_SHARE = 0.5 -- borda do painel mais fina que a proporcional
local RIBBON_WIDTH = 150
local RIBBON_WIDTH_BIG = 200

local ReviveOffer = {}

type Source<T> = (() -> T) & ((T) -> T)

-- Medidas de uma composição: as normais ou as grandes do PC.
type Sizes = {
	padding: number,
	gap: number,
	icon: number,
	title: number,
	price: number,
	button: number,
	decline: number,
	ribbon: number,
}

local NORMAL: Sizes = {
	padding = DeathLayout.OFFER_PADDING,
	gap = DeathLayout.OFFER_GAP,
	icon = DeathLayout.OFFER_ICON,
	title = DeathLayout.OFFER_TITLE,
	price = DeathLayout.OFFER_PRICE,
	button = DeathLayout.OFFER_BUTTON,
	decline = DeathLayout.OFFER_DECLINE,
	ribbon = RIBBON_WIDTH,
}
local BIG: Sizes = {
	padding = DeathLayout.OFFER_PADDING_BIG,
	gap = DeathLayout.OFFER_GAP_BIG,
	icon = DeathLayout.OFFER_ICON_BIG,
	title = DeathLayout.OFFER_TITLE_BIG,
	price = DeathLayout.OFFER_PRICE_BIG,
	button = DeathLayout.OFFER_BUTTON_BIG,
	decline = DeathLayout.OFFER_DECLINE_BIG,
	ribbon = RIBBON_WIDTH_BIG,
}

local function answer(accept: boolean)
	-- Uma resposta só: os botões ficam desligados até o ReviveClosed.
	if vide.untrack(ScreenState.reviveSending) then
		return
	end
	ScreenState.reviveSending(true)
	Net.RequestRevive.Fire({ Accept = accept })
end

-- Metade da linha (duas peças lado a lado, com o espaço entre elas) ou a linha inteira.
local function cellSize(row: () -> boolean, sizes: () -> Sizes, height: (Sizes) -> number): () -> UDim2
	return function()
		local s = sizes()
		local h = height(s)
		return if row() then UDim2.new(0.5, -s.gap / 2, 0, h) else UDim2.new(1, 0, 0, h)
	end
end

-- Botão da oferta. Com arte (estados normal/apertado/desligado) usa
-- ImageButton em 9 partes; sem ela cai no botão rústico (`kind` reativo;
-- desligado = cinza). Em linha, os dois botões ficam lado a lado com a altura
-- de REVIVER.
local function offerButton(props: {
	name: string,
	text: string,
	height: (Sizes) -> number,
	kind: string,
	art: { [string]: string },
	maxSize: number,
	accept: boolean,
	order: number,
	row: () -> boolean,
	sizes: () -> Sizes,
}): GuiButton
	local sending = ScreenState.reviveSending
	local size = cellSize(props.row, props.sizes, function(s: Sizes): number
		return if props.row() then s.button else props.height(s)
	end)
	if MonetizationImages.has(props.art.normal) then
		local down: Source<boolean> = vide.source(false) :: any
		local button = create("ImageButton")({
			Name = props.name,
			LayoutOrder = props.order,
			Size = size,
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Active = function()
				return not sending()
			end,
			Image = function()
				if sending() and MonetizationImages.has(props.art.disabled) then
					return props.art.disabled
				elseif down() and not sending() and MonetizationImages.has(props.art.pressed) then
					return props.art.pressed
				end
				return props.art.normal
			end,
			ImageTransparency = function()
				return if sending() and not MonetizationImages.has(props.art.disabled) then 0.45 else 0
			end,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = MonetizationImages.BUTTON_SLICE,
			MouseButton1Down = function()
				down(true)
			end,
			MouseButton1Up = function()
				down(false)
			end,
			MouseLeave = function()
				down(false)
			end,
			Activated = function()
				answer(props.accept)
			end,
			Rustic.label({
				Name = "Label",
				AnchorPoint = Vector2.new(0.5, 0.5),
				-- A arte apertada desce a face: o texto desce junto.
				Position = function()
					return UDim2.fromScale(0.5, if down() and not sending() then 0.5 else 0.44)
				end,
				Size = UDim2.fromScale(0.8, 0.5),
				FontFace = Theme.font.number,
				TextColor3 = function()
					return if sending() then R.disabledText else R.cream
				end,
				Text = props.text,
				maxSize = props.maxSize,
				create("UIStroke")({
					Color = R.outline,
					Thickness = 1.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				}),
			}),
		}) :: ImageButton
		Rustic.fitSlice(button, MonetizationImages.BUTTON_SIZE)
		return button
	end
	return Rustic.button({
		Name = props.name,
		LayoutOrder = props.order,
		Size = size,
		kind = function()
			return if sending() then "disabled" else props.kind
		end,
		text = props.text,
		maxSize = props.maxSize,
		Activated = function()
			answer(props.accept)
		end,
	}) :: GuiButton
end

-- Ícone do revive: a arte, ou um medalhão de brasa com "+".
local function icon(order: number, sizes: () -> Sizes): GuiObject
	local function size(): UDim2
		local side = sizes().icon
		return UDim2.fromOffset(side, side)
	end
	if MonetizationImages.has(MonetizationImages.REVIVE) then
		return create("ImageLabel")({
			Name = "Icon",
			LayoutOrder = order,
			Size = size,
			BackgroundTransparency = 1,
			Image = MonetizationImages.REVIVE,
			ScaleType = Enum.ScaleType.Fit,
		}) :: GuiObject
	end
	return create("Frame")({
		Name = "Icon",
		LayoutOrder = order,
		Size = size,
		BackgroundColor3 = R.ember,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
		create("UIStroke")({ Color = R.outline, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		Rustic.label({
			Name = "Plus",
			Size = UDim2.fromScale(1, 1),
			FontFace = Theme.font.title,
			TextColor3 = R.charcoal,
			Text = "+",
			maxSize = 60,
		}),
	}) :: GuiObject
end

-- Fita GRÁTIS (arte 9-slice sem texto, ou uma faixa de brasa).
local function ribbon(order: number, sizes: () -> Sizes): GuiObject
	local withArt = MonetizationImages.has(MonetizationImages.VIP_RIBBON)
	local function size(): UDim2
		local s = sizes()
		return UDim2.fromOffset(s.ribbon, s.price)
	end
	local label = Rustic.label({
		Name = "Label",
		Size = UDim2.fromScale(0.62, 0.62),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		FontFace = Theme.font.title,
		TextColor3 = if withArt then R.cream else R.charcoal,
		Text = Strings.get("revive.free"),
		maxSize = 28,
		create("UIStroke")({ Color = R.outline, Thickness = 1.5, Enabled = withArt }),
	})
	if withArt then
		local image = create("ImageLabel")({
			Name = "FreeRibbon",
			LayoutOrder = order,
			Size = size,
			BackgroundTransparency = 1,
			Image = MonetizationImages.VIP_RIBBON,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = MonetizationImages.VIP_RIBBON_SLICE,
			label,
		}) :: ImageLabel
		Rustic.fitSlice(image, MonetizationImages.VIP_RIBBON_SIZE)
		return image
	end
	return create("Frame")({
		Name = "FreeRibbon",
		LayoutOrder = order,
		Size = size,
		BackgroundColor3 = R.ember,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
		create("UIStroke")({ Color = R.outline, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		label,
	}) :: GuiObject
end

-- Oferta completa. `place` traz Position/Size do retângulo da oferta dentro da
-- janela da tela de morte; `layout` é o DeathLayout da tela (painel, ícone,
-- linha, grande). Só aparece com uma oferta pendente.
function ReviveOffer.build(place: { [string]: any }, layout: () -> DeathLayout.Layout): Frame
	local offer = ScreenState.reviveOffer
	local hasPanelArt = MonetizationImages.has(MonetizationImages.REVIVE_PANEL)
	local function row(): boolean
		return layout().offerRow
	end
	local function sizes(): Sizes
		return if layout().offerBig then BIG else NORMAL
	end

	local iconFrame = icon(1, sizes)
	vide.effect(function()
		local l = layout()
		iconFrame.Visible = l.offerIcon and not l.offerRow
	end)
	local freeRibbon = ribbon(1, sizes)
	vide.effect(function()
		local o = offer()
		freeRibbon.Visible = o ~= nil and o.Free
	end)
	local function direction(): Enum.FillDirection
		return if row() then Enum.FillDirection.Horizontal else Enum.FillDirection.Vertical
	end

	local art = create("ImageLabel")({
		Name = "Art",
		Visible = hasPanelArt,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = MonetizationImages.REVIVE_PANEL,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = MonetizationImages.REVIVE_PANEL_SLICE,
		ZIndex = 0,
	}) :: ImageLabel
	Rustic.fitSlice(art, MonetizationImages.REVIVE_PANEL_SIZE, PANEL_SLICE_SHARE)

	local card = create("Frame")({
		Name = "Panel",
		Position = function()
			local c = layout().offerCard
			return UDim2.fromOffset(c.x, c.y)
		end,
		Size = function()
			local c = layout().offerCard
			return UDim2.fromOffset(c.w, c.h)
		end,
		BackgroundColor3 = PANEL_BODY,
		BackgroundTransparency = if hasPanelArt then 1 else 0,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		create("UIStroke")({
			Enabled = not hasPanelArt,
			Color = R.woodLight,
			Thickness = 3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		art,
		create("UIPadding")({
			PaddingTop = function()
				return UDim.new(0, sizes().padding)
			end,
			PaddingBottom = function()
				return UDim.new(0, sizes().padding)
			end,
			PaddingLeft = UDim.new(0, 24),
			PaddingRight = UDim.new(0, 24),
		}),
		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = function()
				return UDim.new(0, sizes().gap)
			end,
		}),
		iconFrame,
		-- Título e preço: um embaixo do outro (coluna) ou lado a lado (linha).
		create("Frame")({
			Name = "Header",
			LayoutOrder = 2,
			Size = function()
				local s = sizes()
				local h = if row() then s.price else s.title + s.gap + s.price
				return UDim2.new(1, 0, 0, h)
			end,
			BackgroundTransparency = 1,
			create("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = direction,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = function()
					return UDim.new(0, sizes().gap)
				end,
			}),
			Rustic.label({
				Name = "Title",
				LayoutOrder = 1,
				Size = cellSize(row, sizes, function(s: Sizes): number
					return s.title
				end),
				FontFace = Theme.font.title,
				TextColor3 = R.emberLight,
				Text = string.upper(Strings.get("revive.title")),
				maxSize = 32,
				create("UIStroke")({ Color = R.outline, Thickness = 2 }),
			}),
			-- Preço (Robux) ou a fita GRÁTIS; ocupam o mesmo lugar.
			create("Frame")({
				Name = "PriceSlot",
				LayoutOrder = 2,
				Size = cellSize(row, sizes, function(s: Sizes): number
					return s.price
				end),
				BackgroundTransparency = 1,
				create("UIListLayout")({
					HorizontalAlignment = Enum.HorizontalAlignment.Center,
					VerticalAlignment = Enum.VerticalAlignment.Center,
				}),
				freeRibbon,
				Rustic.label({
					Name = "PriceLabel",
					LayoutOrder = 2,
					Size = UDim2.fromScale(1, 1),
					FontFace = Theme.font.number,
					-- Sobre o papel creme da arte, o preço vai escuro.
					TextColor3 = if hasPanelArt then R.charcoal else R.cream,
					Visible = function()
						local o = offer()
						return o ~= nil and not o.Free
					end,
					Text = function()
						local o = offer()
						return if o then Strings.format("revive.price", { price = o.Robux }) else ""
					end,
					maxSize = 36,
				}),
			}),
		}),
		-- REVIVER e "Não, obrigado": um embaixo do outro ou lado a lado.
		create("Frame")({
			Name = "Buttons",
			LayoutOrder = 3,
			Size = function()
				local s = sizes()
				local h = if row() then s.button else s.button + s.gap + s.decline
				return UDim2.new(1, 0, 0, h)
			end,
			BackgroundTransparency = 1,
			create("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = direction,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = function()
					return UDim.new(0, sizes().gap)
				end,
			}),
			offerButton({
				name = "ReviveButton",
				text = Strings.get("revive.accept"),
				height = function(s: Sizes): number
					return s.button
				end,
				kind = "green",
				art = MonetizationImages.REVIVE_BUTTON,
				maxSize = 30,
				accept = true,
				order = 1,
				row = row,
				sizes = sizes,
			}),
			offerButton({
				name = "DeclineButton",
				text = Strings.get("revive.decline"),
				height = function(s: Sizes): number
					return s.decline
				end,
				kind = "leather",
				art = MonetizationImages.DECLINE_BUTTON,
				maxSize = 22,
				accept = false,
				order = 2,
				row = row,
				sizes = sizes,
			}),
		}),
	}) :: Frame

	-- O retângulo da oferta: escurece o resumo e come o toque; o painel no meio.
	local cover = create("Frame")({
		Name = "ReviveOffer",
		Visible = function()
			return offer() ~= nil
		end,
		ZIndex = 20,
		Active = true, -- come o toque: nada por baixo reage
		BackgroundColor3 = COVER,
		BackgroundTransparency = 0.15,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		card,
	}) :: Frame
	return vide.apply(cover)(place) :: Frame
end

return ReviveOffer
