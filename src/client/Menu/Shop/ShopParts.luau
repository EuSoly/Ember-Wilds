--!strict
-- Peças repetidas da Loja: título de seção, cartão vibrante (fundo colorido
-- com brilho), botão de preço (Robux ou Golden Ember), fita e selo.
-- Enquanto as artes da loja não chegam, o brilho dos cartões é desenhado
-- com UIGradient; quando chegarem, só este arquivo muda.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local UiImages = require(Shared:WaitForChild("UiImages"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))

local create = vide.create
local R = Theme.rustic

local ShopParts = {}

local CARD_CORNER = UDim.new(0, 12)
local CARD_OUTLINE = 3
local TITLE_HEIGHT = 36

-- Clareia/escurece uma cor (fator > 1 clareia).
function ShopParts.shade(color: Color3, factor: number): Color3
	return Color3.new(
		math.clamp(color.R * factor, 0, 1),
		math.clamp(color.G * factor, 0, 1),
		math.clamp(color.B * factor, 0, 1)
	)
end

-- 20000 → "20.000" (separador de milhar do pt-BR).
function ShopParts.thousands(value: number): string
	local digits = tostring(math.floor(math.max(value, 0)))
	local out = digits:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return (out:gsub("^%.", ""))
end

-- Texto com contorno escuro (para cima de cores vivas).
function ShopParts.outlined(props: { [any]: any }): TextLabel
	table.insert(props, create("UIStroke")({ Color = R.outline, Thickness = 2 }))
	return Rustic.label(props)
end

-- "PACOTES EM DESTAQUE ─────": título da seção com uma linha até a borda.
function ShopParts.sectionTitle(textKey: string): Frame
	return create("Frame")({
		Name = "Title",
		Size = UDim2.new(1, 0, 0, TITLE_HEIGHT),
		BackgroundTransparency = 1,
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 12),
		}),
		Rustic.label({
			Name = "Text",
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			TextScaled = false,
			TextSize = 26,
			FontFace = Theme.font.title,
			TextColor3 = R.textSecondaryDark,
			Text = Strings.get(textKey),
		}),
		create("Frame")({
			Name = "Line",
			Size = UDim2.new(1, 0, 0, 4),
			BackgroundColor3 = R.woodShadow,
			BorderSizePixel = 0,
			create("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		}),
	}) :: Frame
end

-- Cartão de cor viva: degradê da cor `theme`, brilho no alto e contorno
-- escuro. `props` vai para o Frame (tamanho, filhos…).
function ShopParts.vividCard(theme: Color3, props: { [any]: any }): Frame
	local card = create("Frame")({
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ClipsDescendants = true,
		create("UICorner")({ CornerRadius = CARD_CORNER }),
		create("UIStroke")({
			Color = R.outline,
			Thickness = CARD_OUTLINE,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		create("UIGradient")({
			Rotation = 90,
			Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, ShopParts.shade(theme, 1.35)),
				ColorSequenceKeypoint.new(0.55, theme),
				ColorSequenceKeypoint.new(1, ShopParts.shade(theme, 0.6)),
			}),
		}),
		-- Brilho: um círculo claro e transparente atrás do centro do cartão.
		create("Frame")({
			Name = "Glow",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.42),
			Size = UDim2.fromScale(0.9, 0.9),
			SizeConstraint = Enum.SizeConstraint.RelativeXX,
			BackgroundColor3 = Color3.new(1, 1, 1),
			BackgroundTransparency = 0.82,
			BorderSizePixel = 0,
			ZIndex = 0,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		}),
	}) :: Frame
	return vide.apply(card)(props) :: Frame
end

-- Botão de preço. Robux: verde com o símbolo do Robux. Golden Ember: botão
-- laranja com a moeda; com `missing` > 0 fica apagado mostrando "faltam N".
export type PriceProps = {
	robux: number?,
	ember: number?,
	missing: (() -> number)?, -- só Golden Ember: quanto falta (0 = pode comprar)
	onClick: () -> (),
	size: UDim2?,
	position: UDim2?,
	anchor: Vector2?,
	textSize: number?,
}

function ShopParts.priceButton(p: PriceProps): TextButton
	local function missing(): number
		return if p.missing then p.missing() else 0
	end
	local isRobux = p.robux ~= nil
	local button = Rustic.button({
		Name = "Price",
		Size = p.size or UDim2.new(1, 0, 0, 48),
		Position = p.position,
		AnchorPoint = p.anchor,
		kind = function()
			if isRobux then
				return "success"
			end
			return if missing() > 0 then "disabled" else "ember"
		end,
		text = function()
			if isRobux then
				return Strings.format("kit.robux", { price = p.robux :: number })
			end
			if missing() > 0 then
				return Strings.format("shop.missing", { amount = missing() })
			end
			return `      {p.ember}` -- espaço para a moeda à esquerda do número
		end,
		maxSize = p.textSize or 22,
		Activated = function()
			if missing() <= 0 then
				p.onClick()
			end
		end,
	})
	if not isRobux and UiImages.has(UiImages.COIN) then
		create("ImageLabel")({
			Name = "Coin",
			Visible = function()
				return missing() <= 0
			end,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(0.42, 0.46),
			Size = UDim2.fromScale(0.5, 0.62),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
			Image = UiImages.COIN,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 3,
			Parent = button,
		})
	end
	return button
end

-- Fita no canto de cima à direita ("POPULAR", "+ CHANCE"…).
function ShopParts.ribbon(text: string, color: Color3?, textColor: Color3?): Frame
	return create("Frame")({
		Name = "Ribbon",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 4, 0, 10),
		Size = UDim2.fromOffset(0, 24),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundColor3 = color or Theme.status.health,
		BorderSizePixel = 0,
		ZIndex = 4,
		create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
		create("UIStroke")({ Color = R.outline, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		create("UIPadding")({ PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 12) }),
		Rustic.label({
			Size = UDim2.fromScale(0, 1),
			AutomaticSize = Enum.AutomaticSize.X,
			TextScaled = false,
			TextSize = 14,
			FontFace = Theme.font.number,
			TextColor3 = textColor or R.cream,
			Text = text,
			ZIndex = 4,
		}),
	}) :: Frame
end

-- Selo pequeno no canto de cima à esquerda ("PROVISÓRIO").
function ShopParts.badge(text: string): TextLabel
	return Rustic.label({
		Name = "Badge",
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(0, 20),
		AutomaticSize = Enum.AutomaticSize.X,
		TextScaled = false,
		TextSize = 12,
		FontFace = Theme.font.number,
		TextColor3 = Theme.ui.warning,
		BackgroundColor3 = R.outline,
		BackgroundTransparency = 0,
		Text = ` {text} `,
		ZIndex = 4,
		create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
	})
end

-- Grade de cartões com `columns` colunas e cartões de altura `height`.
function ShopParts.grid(columns: () -> number, height: number, gap: number): UIGridLayout
	return create("UIGridLayout")({
		CellPadding = UDim2.fromOffset(gap, gap),
		CellSize = function()
			local n = columns()
			-- -1 px por cartão: sem a folga, o arredondamento empurra o último
			-- cartão para a linha de baixo.
			return UDim2.new(1 / n, -gap * (n - 1) / n - 1, 0, height)
		end,
		SortOrder = Enum.SortOrder.LayoutOrder,
	}) :: UIGridLayout
end

return ShopParts
