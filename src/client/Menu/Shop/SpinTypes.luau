--!strict
-- "GIROS · ESCOLHA O TIPO": um cartão por tipo de skin (MockStore.SPIN_TYPES)
-- com uma roleta girando devagar e o botão Escolher, que abre a tela do giro.
-- A roleta é um placeholder (disco com as cores das raridades) até chegar a
-- arte; ela só gira com a loja aberta.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local ShopLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("ShopLayout"))
local ShopImages = require(Shared:WaitForChild("ShopImages"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))
local ShopState = require(script.Parent:WaitForChild("ShopState"))
local SpinTile = require(script.Parent:WaitForChild("SpinTile"))

local create = vide.create
local R = Theme.rustic

local CARD_HEIGHT = 360 -- alto: abaixo do título fica a faixa das skins de amostra
local CARD_HEIGHT_COMPACT = 250 -- no celular o cartão alto passaria da tela
-- Fundo de cartão (ShopImages.CARD) de cada tipo, na mesma ordem de cores da referência.
local CARD_ART: { [string]: string } = {
	body = "red",
	accessory = "purple",
	bag = "green",
	book = "blue",
	crate = "orange",
}
local SAMPLE_COUNT = 3 -- skins de amostra por cartão
local SAMPLE_TILE = 70 -- só dimensiona o nome (o tamanho real vem da faixa)
local WHEEL_SPEED = 40 -- graus por segundo

local SpinTypes = {}

-- Disco com faixas nas cores das raridades (girando parece uma roleta).
local function wheel(): Frame
	local keys: { ColorSequenceKeypoint } = {}
	local n = #MockStore.RARITIES
	for i, rarity in MockStore.RARITIES do
		local color = Color3.fromHex(rarity.color)
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / n, color))
		table.insert(keys, ColorSequenceKeypoint.new(i / n - (if i < n then 0.001 else 0), color))
	end
	return create("Frame")({
		Name = "Wheel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.9, 0.9),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		ZIndex = 3,
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		create("UIStroke")({ Color = R.outline, Thickness = 4, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		create("UIGradient")({ Color = ColorSequence.new(keys) }),
		create("Frame")({
			Name = "Hub",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.3, 0.3),
			BackgroundColor3 = R.outline,
			BorderSizePixel = 0,
			ZIndex = 4,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			create("UIStroke")({ Color = R.emberLight, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		}),
	}) :: Frame
end

-- Uma camada da roleta desenhada (todas no mesmo quadro, por cima uma da outra).
local function layer(name: string, image: string, zIndex: number): ImageLabel
	return create("ImageLabel")({
		Name = name,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		Image = image,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = zIndex,
	}) :: ImageLabel
end

-- Roleta: com a arte, disco (gira) + moldura + ponteiro; sem ela, o desenho
-- feito por código com um pino de texto. Devolve a roleta e o que gira.
local function roulette(): (Frame, GuiObject)
	if ShopImages.has(ShopImages.WHEEL_DISC) then
		local disc = layer("Disc", ShopImages.WHEEL_DISC, 3)
		local box = create("Frame")({
			Name = "WheelBox",
			-- Embaixo, logo acima do botão: em cima ficam as skins de amostra.
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -62),
			-- Cabe no menor lado: até 78% da largura e até 40% da altura do
			-- cartão (em tela larga, só pela largura ela cobria o título).
			Size = UDim2.fromScale(0.78, 0.4),
			BackgroundTransparency = 1,
			ZIndex = 3,
			create("UIAspectRatioConstraint")({
				AspectRatio = 1,
				AspectType = Enum.AspectType.FitWithinMaxSize,
			}),
			disc,
			layer("Frame", ShopImages.WHEEL_FRAME, 4),
			layer("Pointer", ShopImages.WHEEL_POINTER, 5),
		}) :: Frame
		return box, disc
	end
	local disc = wheel()
	local box = create("Frame")({
		Name = "WheelBox",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.2),
		Size = UDim2.fromScale(0.52, 0.52),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		ZIndex = 3,
		disc :: Instance,
		ShopParts.outlined({
			Name = "Pin",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.02),
			Size = UDim2.fromScale(0.3, 0.3),
			FontFace = Theme.font.title,
			Text = "▼",
			TextColor3 = R.cream,
			maxSize = 40,
			ZIndex = 6,
		}),
	}) :: Frame
	return box, disc
end

-- Faixa de amostras abaixo do título: as skins mais raras do tipo em 3D, paradas
-- (sem trabalho por quadro). Tipo sem skins ("Em breve") fica com a faixa vazia.
local function samples(spinType: MockStore.SpinType): Frame
	local picked: { MockStore.SpinItem } = {}
	for i = #spinType.items, math.max(#spinType.items - SAMPLE_COUNT + 1, 1), -1 do
		table.insert(picked, 1, spinType.items[i])
	end
	local strip = create("Frame")({
		Name = "Samples",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.17),
		Size = UDim2.fromScale(0.9, 0.17),
		BackgroundTransparency = 1,
		ZIndex = 3,
	}) :: Frame
	-- Caixa com a proporção de N quadradinhos lado a lado: ela encolhe para caber
	-- na faixa (na largura ou na altura, o que apertar primeiro) e os
	-- quadradinhos têm a altura dela, então nunca passam da faixa.
	local gap = 0.08
	local ratio = SAMPLE_COUNT + (SAMPLE_COUNT - 1) * gap
	local row = create("Frame")({
		Name = "Row",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 3,
		create("UIAspectRatioConstraint")({
			AspectRatio = ratio,
			AspectType = Enum.AspectType.FitWithinMaxSize,
		}),
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(gap / ratio, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}) :: Frame
	row.Parent = strip
	for i, item in picked do
		local tile = SpinTile.build(item, SAMPLE_TILE)
		tile.Size = UDim2.fromScale(1, 1)
		tile.SizeConstraint = Enum.SizeConstraint.RelativeYY
		tile.LayoutOrder = i
		tile.Parent = row
	end
	return strip
end

-- Botão de baixo do cartão: "Escolher", ou "Em breve" (apagado) se o tipo ainda
-- não tem skins.
local function bottomButton(spinType: MockStore.SpinType): Instance
	local soon = #spinType.items == 0
	return Rustic.button({
		Name = if soon then "Soon" else "Choose",
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -10),
		Size = UDim2.new(0.86, 0, 0, 46),
		ZIndex = 4,
		kind = if soon then "disabled" else "ember",
		text = Strings.get(if soon then "cosmetics.soon" else "shop.choose"),
		Activated = function()
			ShopState.openSpin(spinType.id)
		end,
	})
end

local function card(spinType: MockStore.SpinType, order: number, wheels: { GuiObject }): Frame
	local wheelBox, disc = roulette()
	table.insert(wheels, disc)
	return ShopParts.vividCard(Color3.fromHex(spinType.theme), {
		art = CARD_ART[spinType.id],
		Name = spinType.id,
		LayoutOrder = order,
		ShopParts.outlined({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.05),
			Size = UDim2.fromScale(0.9, 0.12),
			FontFace = Theme.font.title,
			Text = Strings.get(spinType.nameKey),
			maxSize = 28,
		}),
		wheelBox,
		samples(spinType),
		bottomButton(spinType),
	})
end

-- Monta a seção. `open` = loja aberta (as roletas só giram nela).
function SpinTypes.build(layout: () -> ShopLayout.Layout, open: () -> boolean): Frame
	local wheels: { GuiObject } = {}
	local children: { Instance } = {
		ShopParts.grid(function()
			return layout().spinColumns
		end, function()
			return if layout().compact then CARD_HEIGHT_COMPACT else CARD_HEIGHT
		end, ShopLayout.GAP),
	}
	for i, spinType in MockStore.SPIN_TYPES do
		table.insert(children, card(spinType, i, wheels))
	end

	-- Uma conexão só gira todas as roletas, e só enquanto a loja está aberta.
	local connection: RBXScriptConnection? = nil
	vide.effect(function()
		local shouldSpin = open()
		if shouldSpin and not connection then
			connection = RunService.RenderStepped:Connect(function(dt)
				for _, disc in wheels do
					disc.Rotation = (disc.Rotation + WHEEL_SPEED * dt) % 360
				end
			end)
		elseif not shouldSpin and connection then
			connection:Disconnect()
			connection = nil
		end
	end)
	vide.cleanup(function()
		if connection then
			connection:Disconnect()
		end
	end)

	return create("Frame")({
		Name = "SpinTypes",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		children,
	}) :: Frame
end

return SpinTypes
