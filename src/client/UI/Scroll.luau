--!strict
-- Painel de pergaminho (arte 29, MonetizationImages.RECIPE_SCROLL, 400x600):
-- o fundo em 9 partes com os rolos de cima e de baixo fixos (escala
-- HudColumn.scrollScale: mais finos no celular baixo) e o conteúdo entre os
-- rolos, longe das bordas do papel. A altura do painel já soma os rolos
-- (HudColumn.scrollExtra). Usado no quadrinho do tutorial e na receita fixada.
-- Sem o id da arte, o papel desenhado por código (Rustic.paper).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local HudColumn = require(Shared:WaitForChild("UIFlow"):WaitForChild("HudColumn"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))
local ScreenMetrics = require(script.Parent:WaitForChild("ScreenMetrics"))

local create = vide.create

-- Linhas finas do papel ficam a ~45 px das bordas da arte: o texto começa depois.
local TEXT_SIDE = 60

local Scroll = {}

local function scale(): number
	return HudColumn.scrollScale(ScreenMetrics.guiHeight())
end

-- O painel: `props` vão para o quadro de fora (Name, Position, Size, Visible...);
-- `content` fica dentro da margem. `tint` (opcional) tinge o papel (ex. o
-- brilho dourado quando muda a etapa do tutorial).
function Scroll.panel(props: { [any]: any }, content: { Instance }, tint: (() -> Color3)?): Frame
	if not MonetizationImages.has(MonetizationImages.RECIPE_SCROLL) then
		local paperProps = table.clone(props)
		table.insert(
			paperProps,
			create("UIPadding")({
				PaddingLeft = UDim.new(0, 12),
				PaddingRight = UDim.new(0, 8),
				PaddingTop = UDim.new(0, 6),
				PaddingBottom = UDim.new(0, 6),
			})
		)
		for _, child in content do
			table.insert(paperProps, child)
		end
		return Rustic.paper(paperProps)
	end
	local frameProps = table.clone(props)
	frameProps.BackgroundTransparency = 1
	frameProps.BorderSizePixel = 0
	table.insert(
		frameProps,
		create("ImageLabel")({
			Name = "ScrollArt",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = MonetizationImages.RECIPE_SCROLL,
			ImageColor3 = tint or Color3.new(1, 1, 1),
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = MonetizationImages.RECIPE_SCROLL_SLICE,
			SliceScale = scale,
			ZIndex = 0,
		})
	)
	-- O conteúdo num quadro à parte: um UIPadding no painel encolheria o fundo.
	local contentProps: { [any]: any } = {
		Name = "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 1,
		create("UIPadding")({
			PaddingLeft = function()
				return UDim.new(0, TEXT_SIDE * scale())
			end,
			PaddingRight = function()
				return UDim.new(0, TEXT_SIDE * scale())
			end,
			PaddingTop = function()
				return UDim.new(0, HudColumn.SCROLL_TEXT_TOP * scale())
			end,
			PaddingBottom = function()
				return UDim.new(0, HudColumn.SCROLL_TEXT_BOTTOM * scale())
			end,
		}),
	}
	for _, child in content do
		table.insert(contentProps, child)
	end
	table.insert(frameProps, create("Frame")(contentProps))
	return create("Frame")(frameProps) :: Frame
end

return Scroll
