--!strict
-- Painel da oferta de revive, por cima do resumo da tela de morte: ícone, preço
-- em Robux (ou a fita GRÁTIS, para o revive grátis do VIP e o guardado), o botão
-- REVIVER e "Não, obrigado". Sem contador (o limite é escondido, do servidor).
-- Cada peça usa a arte de MonetizationImages quando o id existe e, senão, o
-- desenho feito por código (mesmo padrão da loja com ShopImages).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local ScreenState = require(Client:WaitForChild("ScreenState"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))

local create = vide.create
local R = Theme.rustic

local ICON_SIZE = 44
local RIBBON_SIZE = Vector2.new(150, 34)
local BUTTON_HEIGHT = 44
local DECLINE_HEIGHT = 36
local PANEL_BODY = Color3.fromHex("#2B2018")

local ReviveOffer = {}

type Source<T> = (() -> T) & ((T) -> T)

local function answer(accept: boolean)
	-- Uma resposta só: os botões ficam desligados até o ReviveClosed.
	if vide.untrack(ScreenState.reviveSending) then
		return
	end
	ScreenState.reviveSending(true)
	Net.RequestRevive.Fire({ Accept = accept })
end

-- Botão da oferta. Com arte (estados normal/apertado/desligado) usa
-- ImageButton; sem ela cai no botão rústico (`kind` reativo; desligado = cinza).
local function offerButton(props: {
	name: string,
	text: string,
	height: number,
	kind: string,
	art: { [string]: string },
	maxSize: number,
	accept: boolean,
	order: number,
}): GuiButton
	local sending = ScreenState.reviveSending
	if MonetizationImages.has(props.art.normal) then
		local down: Source<boolean> = vide.source(false) :: any
		return create("ImageButton")({
			Name = props.name,
			LayoutOrder = props.order,
			Size = UDim2.new(1, 0, 0, props.height),
			BackgroundTransparency = 1,
			AutoButtonColor = false,
			Active = function()
				return not sending()
			end,
			Image = function()
				if sending() and MonetizationImages.has(props.art.disabled) then
					return props.art.disabled
				elseif down() and MonetizationImages.has(props.art.pressed) then
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
				Position = UDim2.fromScale(0.5, 0.46),
				Size = UDim2.fromScale(0.8, 0.5),
				FontFace = Theme.font.number,
				Text = props.text,
				maxSize = props.maxSize,
				create("UIStroke")({
					Color = R.outline,
					Thickness = 1.5,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual,
				}),
			}),
		}) :: GuiButton
	end
	return Rustic.button({
		Name = props.name,
		LayoutOrder = props.order,
		Size = UDim2.new(1, 0, 0, props.height),
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
local function icon(order: number): GuiObject
	if MonetizationImages.has(MonetizationImages.REVIVE) then
		return create("ImageLabel")({
			Name = "Icon",
			LayoutOrder = order,
			Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
			BackgroundTransparency = 1,
			Image = MonetizationImages.REVIVE,
			ScaleType = Enum.ScaleType.Fit,
		}) :: GuiObject
	end
	return create("Frame")({
		Name = "Icon",
		LayoutOrder = order,
		Size = UDim2.fromOffset(ICON_SIZE, ICON_SIZE),
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
			maxSize = 34,
		}),
	}) :: GuiObject
end

-- Fita GRÁTIS (arte 9-slice sem texto, ou uma faixa de brasa).
local function ribbon(order: number): GuiObject
	local withArt = MonetizationImages.has(MonetizationImages.VIP_RIBBON)
	local label = Rustic.label({
		Name = "Label",
		Size = UDim2.fromScale(0.8, 0.6),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		FontFace = Theme.font.title,
		TextColor3 = if withArt then R.cream else R.charcoal,
		Text = Strings.get("revive.free"),
		maxSize = 22,
	})
	if withArt then
		return create("ImageLabel")({
			Name = "FreeRibbon",
			LayoutOrder = order,
			Size = UDim2.fromOffset(RIBBON_SIZE.X, RIBBON_SIZE.Y),
			BackgroundTransparency = 1,
			Image = MonetizationImages.VIP_RIBBON,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = MonetizationImages.VIP_RIBBON_SLICE,
			label,
		}) :: GuiObject
	end
	return create("Frame")({
		Name = "FreeRibbon",
		LayoutOrder = order,
		Size = UDim2.fromOffset(RIBBON_SIZE.X, RIBBON_SIZE.Y),
		BackgroundColor3 = R.ember,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
		create("UIStroke")({ Color = R.outline, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		label,
	}) :: GuiObject
end

-- Painel completo. `place` traz Position/Size dentro da janela da tela de morte;
-- só aparece com uma oferta pendente. `showIcon` esconde o ícone em janela baixa.
function ReviveOffer.build(place: { [string]: any }, showIcon: () -> boolean): Frame
	local offer = ScreenState.reviveOffer
	local hasPanelArt = MonetizationImages.has(MonetizationImages.REVIVE_PANEL)

	local iconFrame = icon(1)
	vide.effect(function()
		iconFrame.Visible = showIcon()
	end)
	local freeRibbon = ribbon(1)
	vide.effect(function()
		local o = offer()
		freeRibbon.Visible = o ~= nil and o.Free
	end)

	local panel = create("Frame")({
		Name = "ReviveOffer",
		Visible = function()
			return offer() ~= nil
		end,
		ZIndex = 20,
		Active = true, -- come o toque: nada por baixo reage
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
		create("ImageLabel")({
			Name = "Art",
			Visible = hasPanelArt,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = MonetizationImages.REVIVE_PANEL,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = MonetizationImages.REVIVE_PANEL_SLICE,
			ZIndex = 0,
		}),
		create("UIPadding")({
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
			PaddingLeft = UDim.new(0, 24),
			PaddingRight = UDim.new(0, 24),
		}),
		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 6),
		}),
		iconFrame,
		Rustic.label({
			Name = "Title",
			LayoutOrder = 2,
			Size = UDim2.new(1, 0, 0, 24),
			FontFace = Theme.font.title,
			TextColor3 = R.emberLight,
			Text = string.upper(Strings.get("revive.title")),
			maxSize = 24,
			create("UIStroke")({ Color = R.outline, Thickness = 2 }),
		}),
		-- Preço (Robux) ou a fita GRÁTIS; ocupam o mesmo lugar.
		create("Frame")({
			Name = "PriceSlot",
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, RIBBON_SIZE.Y),
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
				TextColor3 = R.cream,
				Visible = function()
					local o = offer()
					return o ~= nil and not o.Free
				end,
				Text = function()
					local o = offer()
					return if o then Strings.format("revive.price", { price = o.Robux }) else ""
				end,
				maxSize = 28,
			}),
		}),
		offerButton({
			name = "ReviveButton",
			text = Strings.get("revive.accept"),
			height = BUTTON_HEIGHT,
			kind = "green",
			art = MonetizationImages.REVIVE_BUTTON,
			maxSize = 26,
			accept = true,
			order = 4,
		}),
		offerButton({
			name = "DeclineButton",
			text = Strings.get("revive.decline"),
			height = DECLINE_HEIGHT,
			kind = "leather",
			art = MonetizationImages.DECLINE_BUTTON,
			maxSize = 20,
			accept = false,
			order = 5,
		}),
	}) :: Frame
	return vide.apply(panel)(place) :: Frame
end

return ReviveOffer
