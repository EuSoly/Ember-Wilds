--!strict
-- Pacotes de Golden Ember (MockStore.PACKS) no estilo dos cartões de dinheiro:
-- fileira de cima com cartões menores e a de baixo com cartões largos (com a
-- frase "Receba na hora"). Número grande, moeda e fita da oferta. Simulado.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local ShopLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("ShopLayout"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local UiImages = require(Shared:WaitForChild("UiImages"))
local MenuState = require(script.Parent.Parent:WaitForChild("MenuState"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))

local create = vide.create

local TOP_HEIGHT = 200
local BOTTOM_HEIGHT = 170
local GOLD = Color3.fromHex("#F0A12A")

local EmberPacks = {}

local function buy()
	MenuState.notify(Strings.get("mock.simulated"))
end

-- Moeda maior nos pacotes maiores (índice 1..5).
local function coin(index: number, props: { [any]: any }): ImageLabel
	local image = create("ImageLabel")({
		Name = "Coin",
		Visible = UiImages.has(UiImages.COIN),
		BackgroundTransparency = 1,
		Image = UiImages.COIN,
		ScaleType = Enum.ScaleType.Fit,
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		ZIndex = 3,
	}) :: ImageLabel
	props.Size = UDim2.fromScale(0.3 + index * 0.05, 0.3 + index * 0.05)
	return vide.apply(image)(props) :: ImageLabel
end

local function ribbon(pack: MockStore.Pack): Instance?
	return if pack.tag then ShopParts.ribbon(string.upper(Strings.get("mock.tag." .. pack.tag))) else nil
end

local function amountText(amount: number): string
	return Strings.format("shop.ember.amount", { amount = ShopParts.thousands(amount) })
end

local function smallCard(pack: MockStore.Pack, index: number): Frame
	return ShopParts.vividCard(GOLD, {
		Name = "Pack" .. index,
		LayoutOrder = index,
		ribbon(pack),
		ShopParts.outlined({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.06),
			Size = UDim2.fromScale(0.9, 0.2),
			FontFace = Theme.font.title,
			Text = amountText(pack.amount),
			maxSize = 34,
		}),
		coin(index, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }),
		ShopParts.priceButton({
			robux = pack.robux,
			onClick = buy,
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -10),
			size = UDim2.new(0.86, 0, 0, 46),
		}),
	})
end

local function wideCard(pack: MockStore.Pack, index: number): Frame
	return ShopParts.vividCard(GOLD, {
		Name = "Pack" .. index,
		LayoutOrder = index,
		ribbon(pack),
		ShopParts.outlined({
			Position = UDim2.fromScale(0.05, 0.1),
			Size = UDim2.fromScale(0.55, 0.26),
			FontFace = Theme.font.title,
			Text = amountText(pack.amount),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 40,
		}),
		ShopParts.outlined({
			Position = UDim2.fromScale(0.05, 0.38),
			Size = UDim2.fromScale(0.55, 0.16),
			Text = Strings.format("shop.ember.instant", { amount = ShopParts.thousands(pack.amount) }),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 18,
		}),
		ShopParts.priceButton({
			robux = pack.robux,
			onClick = buy,
			anchor = Vector2.new(0, 1),
			position = UDim2.new(0.05, 0, 1, -12),
			size = UDim2.new(0.4, 0, 0, 46),
		}),
		coin(index, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.94, 0.52) }),
	})
end

local function row(columns: () -> number, height: number, cards: { Frame }, order: number): Frame
	local children: { Instance } = { ShopParts.grid(columns, height, ShopLayout.GAP) }
	for _, c in cards do
		table.insert(children, c)
	end
	return create("Frame")({
		LayoutOrder = order,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		children,
	}) :: Frame
end

function EmberPacks.build(layout: () -> ShopLayout.Layout): Frame
	-- Os últimos `emberBottom` pacotes vão na fileira de baixo (cartões largos).
	local packs = MockStore.PACKS
	local bottomCount = 2
	local top: { Frame } = {}
	local bottom: { Frame } = {}
	for i, pack in packs do
		if i <= #packs - bottomCount then
			table.insert(top, smallCard(pack, i))
		else
			table.insert(bottom, wideCard(pack, i))
		end
	end
	return create("Frame")({
		Name = "EmberPacks",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, ShopLayout.GAP) }),
		row(function()
			return layout().emberTop
		end, TOP_HEIGHT, top, 1),
		row(function()
			return layout().emberBottom
		end, BOTTOM_HEIGHT, bottom, 2),
	}) :: Frame
end

return EmberPacks
