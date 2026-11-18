--!strict
-- Pacotes de Golden Ember (ShopConfig.EMBER_PACKS) no estilo dos cartões de dinheiro:
-- fileira de cima com cartões menores e a de baixo com cartões largos (com a
-- frase "Receba na hora"). Número grande, moeda e fita da oferta. Comprar =
-- pedido ao servidor (produto pack_<quantidade>; Robux ainda não é cobrado).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local ShopConfig = require(Shared:WaitForChild("Shop"):WaitForChild("ShopConfig"))
local ShopLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("ShopLayout"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local UiImages = require(Shared:WaitForChild("UiImages"))
local ShopImages = require(Shared:WaitForChild("ShopImages"))
local Purchase = require(script.Parent.Parent:WaitForChild("Purchase"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))

local create = vide.create

local GOLD = Color3.fromHex("#F0A12A")
local TAGGED_AMOUNT_TOP = 40 -- px: logo abaixo da fita
local TAGGED_COIN_SHARE = 0.7
local TAGGED_COIN_Y = 0.57

local EmberPacks = {}

local function buy(pack: ShopConfig.EmberPack)
	Purchase.buy(`pack_{pack.amount}`)
end

-- Moeda dos pacotes (índice 1..5): uma moeda, depois duas, depois a pilha,
-- cada vez maior (como na referência).
local function coinArt(index: number): (string, number)
	if index >= 3 and ShopImages.has(ShopImages.COIN_STACK_3) then
		return ShopImages.COIN_STACK_3, 1.45 -- pilha: mais larga que alta
	elseif index == 2 and ShopImages.has(ShopImages.COIN_STACK_2) then
		return ShopImages.COIN_STACK_2, 1.45
	end
	return UiImages.COIN, 1
end

local function coin(index: number, props: { [any]: any }): ImageLabel
	local image, aspect = coinArt(index)
	local label = create("ImageLabel")({
		Name = "Coin",
		Visible = image ~= "",
		BackgroundTransparency = 1,
		Image = image,
		ScaleType = Enum.ScaleType.Fit,
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		ZIndex = 3,
	}) :: ImageLabel
	local side = 0.32 + index * 0.05
	local shrink = props.shrink
	props.shrink = nil
	props.Size = function()
		local share = if shrink and shrink() then side * TAGGED_COIN_SHARE else side
		return UDim2.fromScale(share * aspect, share)
	end
	return vide.apply(label)(props) :: ImageLabel
end

local function ribbon(pack: ShopConfig.EmberPack): Instance?
	return if pack.tag then ShopParts.ribbon(string.upper(Strings.get("mock.tag." .. pack.tag))) else nil
end

local function amountText(amount: number): string
	return Strings.format("shop.ember.amount", { amount = ShopParts.thousands(amount) })
end

-- `paged`: página do celular. Lá o cartão é estreito e a fita (POPULAR...)
-- cobria o número: com fita, o número desce para baixo dela e a moeda encolhe.
local function smallCard(pack: ShopConfig.EmberPack, index: number, paged: () -> boolean): Frame
	local function tagged(): boolean
		return pack.tag ~= nil and paged()
	end
	return ShopParts.vividCard(GOLD, {
		art = "orange",
		fxCenter = UDim2.fromScale(0.5, 0.5), -- raios atrás da moeda
		Name = "Pack" .. index,
		LayoutOrder = index,
		ribbon(pack),
		ShopParts.outlined({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = function()
				return if tagged() then UDim2.new(0.5, 0, 0, TAGGED_AMOUNT_TOP) else UDim2.fromScale(0.5, 0.06)
			end,
			Size = function()
				return if tagged() then UDim2.fromScale(0.9, 0.17) else UDim2.fromScale(0.9, 0.2)
			end,
			FontFace = Theme.font.title,
			Text = amountText(pack.amount),
			maxSize = 34,
		}),
		coin(index, {
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = function()
				return UDim2.fromScale(0.5, if tagged() then TAGGED_COIN_Y else 0.5)
			end,
			shrink = tagged,
		}),
		ShopParts.priceButton({
			robux = pack.robux,
			onClick = function()
				buy(pack)
			end,
			anchor = Vector2.new(0.5, 1),
			position = UDim2.new(0.5, 0, 1, -10),
			size = UDim2.new(0.86, 0, 0, 46),
		}),
	})
end

local function wideCard(pack: ShopConfig.EmberPack, index: number): Frame
	return ShopParts.vividCard(GOLD, {
		art = "orange",
		-- Raios atrás da pilha de moedas, que fica à direita (presa em 0,94 e
		-- com ~0,8 da altura do cartão de largura: o meio cai perto de 0,82).
		fxCenter = UDim2.fromScale(0.82, 0.52),
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
			onClick = function()
				buy(pack)
			end,
			anchor = Vector2.new(0, 1),
			position = UDim2.new(0.05, 0, 1, -12),
			size = UDim2.new(0.4, 0, 0, 46),
		}),
		coin(index, { AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.fromScale(0.94, 0.52) }),
	})
end

local function row(columns: () -> number, height: number | () -> number, cards: { Frame }, order: number): Frame
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
	local packs = ShopConfig.EMBER_PACKS
	local bottomCount = 2
	local function paged(): boolean
		return layout().paged
	end
	local top: { Frame } = {}
	local bottom: { Frame } = {}
	for i, pack in packs do
		if i <= #packs - bottomCount then
			table.insert(top, smallCard(pack, i, paged))
		else
			table.insert(bottom, wideCard(pack, i))
		end
	end
	-- Alturas: as de sempre no PC; na página do celular a fileira de cima
	-- ocupa a página e a de baixo aparece um pouco (ShopLayout.emberHeights).
	local function topHeight(): number
		return (ShopLayout.emberHeights(layout()))
	end
	local function bottomHeight(): number
		local _, height = ShopLayout.emberHeights(layout())
		return height
	end
	return create("Frame")({
		Name = "EmberPacks",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, ShopLayout.GAP) }),
		row(function()
			return layout().emberTop
		end, topHeight, top, 1),
		row(function()
			return layout().emberBottom
		end, bottomHeight, bottom, 2),
	}) :: Frame
end

return EmberPacks
