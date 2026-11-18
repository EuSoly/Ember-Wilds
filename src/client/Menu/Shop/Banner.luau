--!strict
-- Cartão deitado da fileira de cima da aba de gamepasses (VIP, boost de XP e
-- Premium). As caixas do ícone, dos textos e do botão saem de
-- ShopLayout.bannerParts no tamanho real do cartão: no PC largo (VIP) ficam
-- em linha; no PC estreito (boost, Premium) ícone e textos em cima e o botão
-- embaixo; no celular é uma faixa baixa sem ícone. (Até 17/11/2026 a coluna
-- do meio esticava por UIFlexItem e os textos saíam com ~8 px no PC.)
-- Fundo, na ordem: as camadas (base → efeitos → moldura, UI/CardFx, com os
-- efeitos recortados dentro da moldura), a arte 9-slice inteira (com o
-- brilho de canto), ou o degradê do vividCard.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local ShopLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("ShopLayout"))
local Theme = require(Shared:WaitForChild("Theme"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))
local ScreenMetrics = require(script.Parent.Parent.Parent:WaitForChild("UI"):WaitForChild("ScreenMetrics"))

local create = vide.create

local Banner = {}

type Source<T> = (() -> T) & ((T) -> T)

-- Uma linha da coluna de textos: `text` reativo, `height` = fração da altura
-- da coluna, `maxSize` = maior tamanho da fonte. No celular (compact) o cartão
-- é uma faixa baixa: `compactText` troca o texto por um curto, `compactHeight`
-- a altura e `hideInCompact` some com a linha. No PC o título não fica menor
-- que BANNER_TITLE_MIN e as outras linhas que BANNER_DESC_MIN.
export type Line = {
	name: string,
	text: () -> string,
	height: number,
	maxSize: number,
	title: boolean?,
	wrapped: boolean?,
	compactText: (() -> string)?,
	compactHeight: number?,
	hideInCompact: boolean?,
	stackedHeight: number?, -- altura no PC estreito (empilhado), se diferente
}

-- Cartão em camadas: base e moldura de MonetizationImages, efeitos na cor `fx`.
export type Layers = {
	set: { [string]: string },
	size: Vector2,
	slice: Rect,
	tint: Color3?, -- base neutra tingida (cartão genérico 41)
	fx: Color3,
}

export type Props = {
	name: string,
	theme: Color3,
	icon: GuiObject, -- o cartão dá a posição e o tamanho
	lines: { Line },
	button: GuiObject, -- o cartão dá a largura e a altura
	layers: Layers?, -- usadas se as artes existem
	art: (() -> string)?, -- 9-slice inteira por cima do fundo ("" = sem arte)
	slice: Rect?,
	overlay: (() -> string)?, -- brilho de canto por cima da arte ("" = nenhum)
	frame: { [any]: any }, -- Size, LayoutOrder, Visible… do cartão
	compact: () -> boolean, -- celular: faixa baixa (ver Line)
}

local function offset(b: ShopLayout.Box): (UDim2, UDim2)
	return UDim2.fromOffset(b.x, b.y), UDim2.fromOffset(b.w, b.h)
end

-- Acompanha o tamanho do cartão em pixels lógicos (sem o UIScale da tela).
local function trackSize(card: GuiObject, size: Source<Vector2>)
	local function read()
		size(ShopParts.innerSize(card))
	end
	card:GetPropertyChangedSignal("AbsoluteSize"):Connect(read)
	card:GetAttributeChangedSignal("CardInset"):Connect(read)
	card.AncestryChanged:Connect(read)
	read()
end

function Banner.build(p: Props): Frame
	local size: Source<Vector2> = vide.source(Vector2.zero) :: any
	local parts = vide.derive(function()
		local s = size()
		return ShopLayout.bannerParts(s.X, s.Y, p.compact())
	end)

	local texts: { Instance } = {
		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 2),
		}),
	}
	for order, line in p.lines do
		table.insert(
			texts,
			ShopParts.outlined({
				Name = line.name,
				LayoutOrder = order,
				Visible = function()
					return not (line.hideInCompact and (p.compact() or ScreenMetrics.short()))
				end,
				Size = function()
					local share = if p.compact()
						then line.compactHeight or line.height
						elseif parts().stacked then line.stackedHeight or line.height
						else line.height
					return UDim2.fromScale(1, share)
				end,
				FontFace = if line.title then Theme.font.number else Theme.font.label,
				Text = function()
					-- Celular: o texto curto também no cartão inteiro (a coluna é estreita).
					local short = line.compactText
					if short and (p.compact() or ScreenMetrics.short()) then
						return short()
					end
					return line.text()
				end,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = line.wrapped or false,
				maxSize = line.maxSize,
				minSize = function()
					if p.compact() then
						return 9
					end
					-- Celular: os mínimos do PC estouravam a coluna (teste de 18/11/2026).
					if ScreenMetrics.short() then
						return if line.title then 12 else 10
					end
					return if line.title then ShopLayout.BANNER_TITLE_MIN else ShopLayout.BANNER_DESC_MIN
				end,
			})
		)
	end

	vide.apply(p.icon)({
		Visible = function()
			return parts().icon ~= nil
		end,
		AnchorPoint = Vector2.zero,
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		Position = function()
			local icon = parts().icon
			return if icon then UDim2.fromOffset(icon.x, icon.y) else UDim2.new()
		end,
		Size = function()
			local icon = parts().icon
			return if icon then UDim2.fromOffset(icon.w, icon.h) else UDim2.new()
		end,
		ZIndex = 3,
	})
	local textColumn = create("Frame")({
		Name = "Texts",
		Position = function()
			return (offset(parts().text))
		end,
		Size = function()
			local _, s = offset(parts().text)
			return s
		end,
		BackgroundTransparency = 1,
		ZIndex = 3,
		texts,
	}) :: Frame
	local buttonBox = create("Frame")({
		Name = "ButtonBox",
		Position = function()
			return (offset(parts().button))
		end,
		Size = function()
			local _, s = offset(parts().button)
			return s
		end,
		BackgroundTransparency = 1,
		ZIndex = 3,
		p.button,
	}) :: Frame

	local layers = p.layers
	local layered = layers ~= nil and MonetizationImages.hasLayers(layers.set)
	local children: { Instance } = {}
	local background: Frame? = nil
	-- Margem do cartão (ShopParts.applyInset): as caixas são de dentro dela, e o
	-- fundo começa `inset` px antes.
	local inset: Source<number> = vide.source(0) :: any
	if layers and layered then
		-- Raios e halo atrás do ícone (no celular, sem ícone, no meio do cartão).
		background = ShopParts.layers(layers.set, layers.size, layers.slice, layers.tint, layers.fx, function()
			local icon = parts().icon
			if icon then
				local pad = inset()
				return UDim2.fromOffset(icon.x + icon.w / 2 + pad, icon.y + icon.h / 2 + pad)
			end
			return UDim2.fromScale(0.5, 0.5)
		end)
		table.insert(children, background :: Frame)
	else
		table.insert(
			children,
			create("ImageLabel")({
				Name = "Art",
				Visible = function()
					return p.art ~= nil and p.art() ~= ""
				end,
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = function()
					return if p.art then p.art() else ""
				end,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = p.slice or Rect.new(0, 0, 0, 0),
				ZIndex = 1,
			})
		)
	end
	-- Brilho de canto (VIP ativo) só com a arte inteira: nas camadas ele saía
	-- por cima da moldura e da borda do cartão (teste de 18/11/2026); lá o
	-- "VIP ativo até" já diz o estado.
	if not layered then
		table.insert(
			children,
			create("ImageLabel")({
				Name = "Overlay",
				Visible = function()
					return p.overlay ~= nil and p.overlay() ~= ""
				end,
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromScale(0.5, 0.5),
				BackgroundTransparency = 1,
				Image = function()
					return if p.overlay then p.overlay() else ""
				end,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 2,
			})
		)
	end
	table.insert(children, p.icon)
	table.insert(children, textColumn)
	table.insert(children, buttonBox)

	local props = p.frame
	props.Name = p.name
	for _, child in children do
		table.insert(props, child)
	end
	local card: Frame
	if layered then
		-- O fundo são as camadas: o vividCard sem `art` desenharia o degradê por baixo.
		card = vide.apply(create("Frame")({ BackgroundTransparency = 1, BorderSizePixel = 0 }))(props) :: Frame
		if background then
			-- Os botões e textos não passam da linha de dentro da moldura (VIP, Premium).
			ShopParts.applyInset(card, background)
		end
	else
		card = ShopParts.vividCard(p.theme, props)
	end
	local function readInset()
		local pad = card:GetAttribute("CardInset")
		inset(if type(pad) == "number" then pad else 0)
	end
	card:GetAttributeChangedSignal("CardInset"):Connect(readInset)
	readInset()
	trackSize(card, size)
	return card
end

-- Ícone (o cartão dá posição e tamanho): imagem se já existe, senão `fallback`
-- (texto; `font` troca a fonte, ex. a do símbolo do Premium).
function Banner.icon(image: string, fallback: string, color: Color3, font: Font?): Frame
	local box = create("Frame")({
		Name = "Icon",
		BackgroundTransparency = 1,
		ZIndex = 3,
	}) :: Frame
	if image ~= "" then
		create("ImageLabel")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = image,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 3,
			Parent = box,
		})
	else
		ShopParts.outlined({
			Size = UDim2.fromScale(1, 1),
			FontFace = font or Theme.font.title,
			TextColor3 = color,
			Text = fallback,
			maxSize = 60,
			Parent = box,
		})
	end
	return box
end

return Banner
