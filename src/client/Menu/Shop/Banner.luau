--!strict
-- Cartão deitado da fileira de cima da aba de gamepasses (VIP, boost de XP e
-- Premium): ícone à esquerda, textos no meio (o do meio estica) e o botão à
-- direita. A arte 9-slice (MonetizationImages) vai por cima do fundo quando já
-- foi enviada; sem ela, vale o degradê do vividCard.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Theme = require(Shared:WaitForChild("Theme"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))

local create = vide.create

local Banner = {}

-- Uma linha de texto da coluna do meio: `text` reativo, `height` = fração da
-- altura da coluna, `maxSize` = maior tamanho da fonte.
export type Line = {
	name: string,
	text: () -> string,
	height: number,
	maxSize: number,
	title: boolean?,
	wrapped: boolean?,
}

export type Props = {
	name: string,
	theme: Color3,
	icon: GuiObject, -- quadrado: o cartão o põe à esquerda
	lines: { Line },
	button: GuiObject, -- o cartão dá a largura e a altura
	art: (() -> string)?, -- 9-slice por cima do fundo ("" = sem arte)
	slice: Rect?,
	overlay: (() -> string)?, -- brilho de canto por cima da arte ("" = nenhum)
	frame: { [any]: any }, -- Size, LayoutOrder, Visible… do cartão
}

local BUTTON_SHARE = 0.3 -- largura do botão na largura do cartão

function Banner.build(p: Props): Frame
	local texts: { Instance } = {
		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 2),
		}),
		create("UIFlexItem")({ FlexMode = Enum.UIFlexMode.Fill }),
	}
	for order, line in p.lines do
		table.insert(
			texts,
			ShopParts.outlined({
				Name = line.name,
				LayoutOrder = order,
				Size = UDim2.fromScale(1, line.height),
				FontFace = if line.title then Theme.font.number else Theme.font.label,
				Text = line.text,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextWrapped = line.wrapped or false,
				maxSize = line.maxSize,
				minSize = 9,
			})
		)
	end

	p.icon.LayoutOrder = 1
	local textColumn = create("Frame")({
		Name = "Texts",
		LayoutOrder = 2,
		Size = UDim2.fromScale(0, 1),
		BackgroundTransparency = 1,
		texts,
	}) :: Frame
	local buttonBox = create("Frame")({
		Name = "ButtonBox",
		LayoutOrder = 3,
		Size = UDim2.fromScale(BUTTON_SHARE, 0.62),
		BackgroundTransparency = 1,
		p.button,
	}) :: Frame

	local children: { Instance } = {
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
		}),
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
		}),
		create("Frame")({
			Name = "Body",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 3,
			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
			create("UIPadding")({
				PaddingLeft = UDim.new(0, 10),
				PaddingRight = UDim.new(0, 10),
				PaddingTop = UDim.new(0, 4),
				PaddingBottom = UDim.new(0, 4),
			}),
			p.icon,
			textColumn,
			buttonBox,
		}),
	}
	local props = p.frame
	props.Name = p.name
	for _, child in children do
		table.insert(props, child)
	end
	return ShopParts.vividCard(p.theme, props)
end

-- Ícone quadrado (a altura do cartão manda): imagem se já existe, senão `fallback`.
function Banner.icon(image: string, fallback: string, color: Color3): Frame
	local box = create("Frame")({
		Name = "Icon",
		Size = UDim2.fromScale(0.8, 0.8),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
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
			FontFace = Theme.font.title,
			TextColor3 = color,
			Text = fallback,
			maxSize = 60,
			Parent = box,
		})
	end
	return box
end

return Banner
