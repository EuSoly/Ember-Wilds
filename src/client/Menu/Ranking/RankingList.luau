--!strict
-- Lista do Ranking (UI 6): do 4º ao último lido (até RankConfig.LIST_SIZE), em
-- faixas de papel claras e escuras alternadas, rolando; embaixo, fixa, a
-- linha de quem está jogando na faixa vermelha, com a seta apontando para ela.
-- As linhas são um conjunto fixo (montado uma vez) que só troca o conteúdo
-- quando chega outra resposta: trocar de aba não recria nada.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local RankConfig = require(Shared:WaitForChild("Data"):WaitForChild("RankConfig"))
local RankingImages = require(Shared:WaitForChild("RankingImages"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local RankingState = require(script.Parent:WaitForChild("RankingState"))

local create = vide.create
local R = Theme.rustic

local FIRST = 4 -- o pódio mostra 1º a 3º
local ROW_GAP = 4
local ME_GAP = 8
local ARROW_SHARE = 0.62 -- altura da seta, fração da linha "você"

export type Props = {
	rowHeight: () -> number, -- px lógicos (RankingLayout)
}

local RankingList = {}

-- Faixa esticada em 9 partes, com as pontas na escala certa para a altura.
local function strip(image: string, size: Vector2, slice: Rect, fallback: Color3, height: () -> number): Instance
	return create("ImageLabel")({
		Name = "Strip",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = if RankingImages.has(image) then 1 else 0,
		BackgroundColor3 = fallback,
		Image = image,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = slice,
		SliceScale = function()
			return height() / size.Y
		end,
		ZIndex = 1,
	})
end

local function cell(props: { [any]: any }): Instance
	props.dark = if props.dark == nil then true else props.dark
	props.ZIndex = 2
	return Rustic.label(props)
end

local function avatar(userId: () -> number?, xScale: number): Instance
	return create("ImageLabel")({
		Name = "Avatar",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.fromScale(xScale, 0.5),
		Size = UDim2.fromScale(0, 0.7),
		BackgroundColor3 = R.paperShadow,
		Image = function()
			local id = userId()
			return if id then RankingState.headshot(id) else ""
		end,
		ZIndex = 2,
		create("UIAspectRatioConstraint")({ AspectRatio = 1, DominantAxis = Enum.DominantAxis.Height }),
		create("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
		create("UIStroke")({ Color = R.woodShadow, Thickness = 2 }),
	})
end

local function row(position: number, height: () -> number): Frame
	local function entry(): RankingState.Entry?
		local data = RankingState.data()
		return data and data.Entries[position]
	end
	local light = position % 2 == 0
	return create("Frame")({
		Name = "Row" .. position,
		LayoutOrder = position,
		BackgroundTransparency = 1,
		Size = function()
			return UDim2.new(1, 0, 0, height())
		end,
		Visible = function()
			return entry() ~= nil
		end,
		strip(
			if light then RankingImages.ROW_LIGHT else RankingImages.ROW_DARK,
			RankingImages.ROW_SIZE,
			RankingImages.ROW_SLICE,
			if light then R.paperLight else R.paper,
			height
		),
		cell({
			Name = "Position",
			Position = UDim2.fromScale(0.05, 0.2),
			Size = UDim2.fromScale(0.1, 0.6),
			FontFace = Theme.font.number,
			Text = Strings.format("rank.position", { position = position }),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 22,
		}),
		avatar(function()
			local e = entry()
			return e and e.UserId
		end, 0.15),
		cell({
			Name = "PlayerName",
			Position = UDim2.fromScale(0.25, 0.2),
			Size = UDim2.fromScale(0.43, 0.6),
			Text = function()
				local e = entry()
				return if e then e.Name else ""
			end,
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 22,
		}),
		cell({
			Name = "Value",
			Position = UDim2.fromScale(0.68, 0.2),
			Size = UDim2.fromScale(0.27, 0.6),
			FontFace = Theme.font.number,
			TextColor3 = R.emberShadow,
			Text = function()
				local e = entry()
				return if e then RankingState.valueText(RankingState.category(), e.Value) else ""
			end,
			TextXAlignment = Enum.TextXAlignment.Right,
			maxSize = 22,
		}),
	}) :: Frame
end

-- Linha de quem está jogando: posição (ou "100+"/"—"), avatar, nome e valor.
local function meRow(height: () -> number): Frame
	local function positionText(): string
		local data = RankingState.data()
		if data == nil or data.MyValue <= 0 then
			return Strings.get("rank.none")
		elseif data.MyPosition <= 0 then
			return Strings.get("rank.outside")
		end
		return Strings.format("rank.position", { position = data.MyPosition })
	end
	return create("Frame")({
		Name = "Me",
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		BackgroundTransparency = 1,
		Size = function()
			return UDim2.new(1, 0, 0, height() * 1.25)
		end,
		strip(RankingImages.ROW_ME, RankingImages.ROW_ME_SIZE, RankingImages.ROW_ME_SLICE, R.emberShadow, function()
			return height() * 1.25
		end),
		create("ImageLabel")({
			Name = "Arrow",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(0, 4, 0.5, 0),
			Size = UDim2.fromScale(0, ARROW_SHARE),
			BackgroundTransparency = 1,
			Image = RankingImages.ARROW,
			Rotation = 180, -- a arte aponta para a esquerda; aqui aponta para a linha
			Visible = RankingImages.has(RankingImages.ARROW),
			ZIndex = 3,
			create("UIAspectRatioConstraint")({
				AspectRatio = RankingImages.ARROW_RATIO,
				DominantAxis = Enum.DominantAxis.Height,
			}),
		}),
		cell({
			Name = "Position",
			Position = UDim2.fromScale(0.07, 0.22),
			Size = UDim2.fromScale(0.12, 0.56),
			FontFace = Theme.font.number,
			TextColor3 = R.emberLight,
			dark = false,
			Text = positionText,
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 24,
		}),
		avatar(RankingState.localUserId, 0.18),
		cell({
			Name = "PlayerName",
			Position = UDim2.fromScale(0.28, 0.22),
			Size = UDim2.fromScale(0.4, 0.56),
			dark = false,
			Text = Strings.format("rank.you", { name = game:GetService("Players").LocalPlayer.DisplayName }),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 24,
		}),
		cell({
			Name = "Value",
			Position = UDim2.fromScale(0.68, 0.22),
			Size = UDim2.fromScale(0.25, 0.56),
			FontFace = Theme.font.number,
			TextColor3 = R.emberLight,
			dark = false,
			Text = function()
				local data = RankingState.data()
				return RankingState.valueText(RankingState.category(), if data then data.MyValue else 0)
			end,
			TextXAlignment = Enum.TextXAlignment.Right,
			maxSize = 24,
		}),
	}) :: Frame
end

-- Aviso no meio da lista: carregando, erro ou ninguém na semana.
local function notice(): TextLabel
	return Rustic.label({
		Name = "Notice",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromScale(0.9, 0.12),
		dark = true,
		Text = function()
			local status = RankingState.status()
			if status == "loading" then
				return Strings.get("rank.loading")
			elseif status == "error" then
				return Strings.get("rank.error")
			end
			local data = RankingState.data()
			return if data and #data.Entries == 0 then Strings.get("rank.empty") else ""
		end,
		maxSize = 24,
		ZIndex = 3,
	})
end

function RankingList.build(props: Props): Frame
	local rows: { Instance } = {
		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, ROW_GAP),
		}),
		create("UIPadding")({ PaddingRight = UDim.new(0, 10), PaddingLeft = UDim.new(0, 2) }),
	}
	for position = FIRST, RankConfig.LIST_SIZE do
		table.insert(rows, row(position, props.rowHeight))
	end
	return create("Frame")({
		Name = "ListArea",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		create("ScrollingFrame")({
			Name = "Rows",
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = function()
				return UDim2.new(1, 0, 1, -(props.rowHeight() * 1.25 + ME_GAP))
			end,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 6,
			ScrollBarImageColor3 = R.woodLight,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			rows,
		}),
		notice(),
		meRow(props.rowHeight),
	}) :: Frame
end

return RankingList
