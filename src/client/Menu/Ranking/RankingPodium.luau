--!strict
-- Pódio do Ranking (UI 6): a imagem dos três degraus com o top 3 em cima.
-- Tudo é posicionado em FRAÇÕES da imagem (RankingImages.PODIUM_SPOTS), e a
-- área mantém a proporção (UIAspectRatioConstraint): em qualquer resolução o
-- avatar fica no tampo do degrau e o "1º/2º/3º" na plaquinha.
-- Cada lugar: avatar (headshot) na moldura redonda, medalha no canto, nome e
-- valor logo acima do avatar.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local RankingImages = require(Shared:WaitForChild("RankingImages"))
local RankingLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("RankingLayout"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local RankingState = require(script.Parent:WaitForChild("RankingState"))

local create = vide.create
local R = Theme.rustic

-- A área tem a imagem embaixo e, em cima, espaço para avatar, nome e valor
-- do 1º lugar (o degrau mais alto): altura da área = HEADROOM × altura da imagem.
local HEADROOM = 1.75
local AVATAR = 0.2 -- largura do avatar, fração da largura da imagem
local MEDAL = 0.42 -- largura da medalha, fração do avatar

local RankingPodium = {}

local function entryAt(place: number): RankingState.Entry?
	local data = RankingState.data()
	return data and data.Entries[place]
end

local function outlined(props: { [any]: any }): TextLabel
	table.insert(props, create("UIStroke")({ Color = R.outline, Thickness = 2 }))
	return Rustic.label(props)
end

local function spot(place: number): Instance
	local fractions = RankingImages.PODIUM_SPOTS[place]
	local function present(): boolean
		return entryAt(place) ~= nil
	end
	return create("Frame")({
		Name = "Place" .. place,
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(fractions.x, fractions.top + RankingLayout.SEAT),
		Size = UDim2.fromScale(AVATAR, AVATAR * RankingImages.PODIUM_RATIO), -- quadrado
		BackgroundTransparency = 1,
		ZIndex = 3,
		create("ImageLabel")({
			Name = "Headshot",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.74, 0.74),
			BackgroundColor3 = R.paperShadow,
			Image = function()
				local entry = entryAt(place)
				return if entry then RankingState.headshot(entry.UserId) else ""
			end,
			Visible = present,
			ZIndex = 3,
			create("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
		}),
		create("ImageLabel")({
			Name = "Ring",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = RankingImages.AVATAR_RING,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 4,
		}),
		create("ImageLabel")({
			Name = "Medal",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.fromScale(1.08, 1.08),
			Size = UDim2.fromScale(MEDAL, MEDAL / RankingImages.MEDAL_RATIO),
			BackgroundTransparency = 1,
			Image = RankingImages.MEDAL[place],
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 5,
		}),
		outlined({
			Name = "Value",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, -0.02),
			Size = UDim2.fromScale(1.7, 0.3),
			FontFace = Theme.font.number,
			TextColor3 = R.emberLight,
			Text = function()
				local entry = entryAt(place)
				return if entry then RankingState.valueText(RankingState.category(), entry.Value) else ""
			end,
			maxSize = 26,
			ZIndex = 5,
		}),
		outlined({
			Name = "PlayerName",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, -0.32),
			Size = UDim2.fromScale(1.7, 0.28),
			Text = function()
				local entry = entryAt(place)
				return if entry then entry.Name else ""
			end,
			maxSize = 22,
			ZIndex = 5,
		}),
	}) :: Frame
end

local function plaque(place: number): Instance
	local fractions = RankingImages.PODIUM_SPOTS[place]
	return Rustic.label({
		Name = "Plaque" .. place,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(fractions.x, fractions.plaqueY),
		Size = UDim2.fromScale(0.16, 0.12),
		FontFace = Theme.font.title,
		Text = Strings.format("rank.position", { position = place }),
		dark = true,
		maxSize = 40,
		ZIndex = 3,
	})
end

-- Área do pódio: ocupa a largura do pai e mantém a proporção (com o espaço de
-- cima para o 1º lugar). Quem chama decide a largura.
function RankingPodium.build(): Frame
	local podium = create("ImageLabel")({
		Name = "Podium",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(1, 1 / HEADROOM),
		BackgroundTransparency = if RankingImages.has(RankingImages.PODIUM) then 1 else 0,
		BackgroundColor3 = R.walnut, -- reserva sem a arte
		Image = RankingImages.PODIUM,
		ScaleType = Enum.ScaleType.Stretch,
		ZIndex = 2,
		plaque(1),
		plaque(2),
		plaque(3),
		spot(2),
		spot(3),
		spot(1),
	})
	return create("Frame")({
		Name = "PodiumArea",
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		create("UIAspectRatioConstraint")({
			AspectRatio = RankingImages.PODIUM_RATIO / HEADROOM,
			DominantAxis = Enum.DominantAxis.Width,
		}),
		podium,
	}) :: Frame
end

return RankingPodium
