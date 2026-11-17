--!strict
-- Gamepasses: no topo a fileira do VIP, do boost de XP e do Premium; embaixo
-- os kits para sempre e as passes 2x e livro (produtos kit_<kit> e pass_<passe>
-- de Shop/Products). Comprar = pedido ao servidor (Robux ainda não é
-- cobrado); o kit comprado aqui é o mesmo do painel de kits (libera o "Usar").
-- Já comprado mostra "Comprado".
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local Products = require(Shared:WaitForChild("Shop"):WaitForChild("Products"))
local ShopConfig = require(Shared:WaitForChild("Shop"):WaitForChild("ShopConfig"))
local ShopLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("ShopLayout"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local ShopImages = require(Shared:WaitForChild("ShopImages"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local ItemIcon = require(Client:WaitForChild("UI"):WaitForChild("ItemIcon"))
local ShopData = require(Client:WaitForChild("ShopData"))
local Purchase = require(script.Parent.Parent:WaitForChild("Purchase"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))
local BoostCard = require(script.Parent:WaitForChild("BoostCard"))
local PremiumCard = require(script.Parent:WaitForChild("PremiumCard"))
local VipCard = require(script.Parent:WaitForChild("VipCard"))

local create = vide.create
local R = Theme.rustic

local GOLD = Color3.fromHex("#E8AE2A")

local Passes = {}

-- Um cartão: o produto e o que a tela precisa dele.
type Pass = { product: Products.Product, artId: string, kitId: string?, nameKey: string, descKey: string }

local function passOf(product: Products.Product): Pass?
	local reward = product.rewards[1]
	if product.kind == "kit" and reward and reward.id then
		return {
			product = product,
			artId = reward.id,
			kitId = reward.id,
			nameKey = product.nameKey or reward.id,
			descKey = "shop.pass.forever",
		}
	elseif product.kind == "pass" and reward and reward.id then
		local def = ShopConfig.PASSES[reward.id]
		return {
			product = product,
			artId = reward.id,
			kitId = nil,
			nameKey = def.nameKey,
			descKey = def.descKey,
		}
	end
	return nil
end

-- Arte das passes novas (MonetizationImages; "" = ainda sem arte).
local PASS_ART: { [string]: string } = {
	ember2x = MonetizationImages.EMBER_2X,
	book = MonetizationImages.BOOK,
}

-- Ícone do cartão: o último item do kit (a ferramenta ou a mochila); as passes
-- sem arte ganham uma estrela desenhada.
local function icon(pass: Pass, short: () -> boolean): GuiObject
	local box = create("Frame")({
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = function()
			return UDim2.fromScale(0.5, if short() then 0.08 else 0.12)
		end,
		Size = function()
			local share = if short() then 0.38 else 0.42
			return UDim2.fromScale(share, share)
		end,
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		ZIndex = 3,
	}) :: Frame
	local art = ShopImages.PASS[pass.artId]
	if not ShopImages.has(art) and MonetizationImages.has(PASS_ART[pass.artId]) then
		art = PASS_ART[pass.artId]
	end
	local kit = if pass.kitId then Defs.Kits[pass.kitId] else nil
	if ShopImages.has(art) then
		create("ImageLabel")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = art,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 3,
			Parent = box,
		})
	elseif kit then
		local itemId = kit.items[#kit.items].id
		ItemIcon({
			item = function()
				return { id = itemId, count = 1 }
			end,
		}).Parent = box
	else
		ShopParts.outlined({
			Size = UDim2.fromScale(1, 1),
			FontFace = Theme.font.title,
			TextColor3 = R.emberLight,
			Text = "★",
			maxSize = 80,
			Parent = box,
		})
	end
	return box
end

-- `short`: cartão mais baixo que o normal (página do celular): arte menor e
-- textos mais acima, para não encostarem no botão de preço.
local function card(pass: Pass, order: number, short: () -> boolean): Frame
	-- Comprado aqui ou ganho por outro caminho (ex. o kit veio num pacote).
	local function owned(): boolean
		if ShopData.purchased(pass.product.id) then
			return true
		end
		return if pass.kitId then ShopData.kitOwned(pass.kitId) else ShopData.hasPass(pass.artId)
	end
	return ShopParts.vividCard(GOLD, {
		art = "orange",
		Name = pass.artId,
		LayoutOrder = order,
		icon(pass, short),
		ShopParts.outlined({
			Name = "PassName",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = function()
				return UDim2.fromScale(0.5, if short() then 0.49 else 0.56)
			end,
			Size = UDim2.fromScale(0.92, 0.12),
			FontFace = Theme.font.number,
			Text = Strings.get(pass.nameKey),
			maxSize = 22,
		}),
		ShopParts.outlined({
			Name = "Desc",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = function()
				return UDim2.fromScale(0.5, if short() then 0.61 else 0.68)
			end,
			Size = UDim2.fromScale(0.92, 0.08),
			Text = Strings.get(pass.descKey),
			maxSize = 15,
		}),
		create("Frame")({
			Name = "Buy",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -10),
			Size = UDim2.new(0.86, 0, 0, 44),
			BackgroundTransparency = 1,
			ZIndex = 3,
			ShopParts.priceButton({
				robux = pass.product.price.amount,
				owned = owned,
				onClick = function()
					Purchase.buy(pass.product.id)
				end,
				size = UDim2.fromScale(1, 1),
			}),
		}),
	})
end

-- Fileira de cima: VIP (peso 2), boost e, para quem não é Premium, o Premium.
local function topRow(layout: () -> ShopLayout.Layout): Frame
	local gap = ShopLayout.GAP
	-- Largura de cada cartão: a sua parte do que sobra depois dos espaços.
	local function width(slot: number): () -> UDim2
		return function()
			local shown = PremiumCard.shown()
			local weights = { ShopLayout.topRowWeights(shown) }
			local total = weights[1] + weights[2] + weights[3]
			local count = if shown then 3 else 2
			local share = weights[slot] / total
			return UDim2.new(share, -math.ceil(gap * (count - 1) * share) - 1, 1, 0)
		end
	end
	return create("Frame")({
		Name = "TopRow",
		LayoutOrder = 1,
		Size = function()
			return UDim2.new(1, 0, 0, ShopLayout.topRowHeight(layout()))
		end,
		BackgroundTransparency = 1,
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, gap),
		}),
		VipCard.build({ LayoutOrder = 1, Size = width(1) }),
		BoostCard.build({ LayoutOrder = 2, Size = width(2) }),
		PremiumCard.build({ LayoutOrder = 3, Size = width(3) }),
	}) :: Frame
end

function Passes.build(layout: () -> ShopLayout.Layout): Frame
	local passes: { Pass } = {}
	for _, product in Products.all() do
		local pass = if product.hidden then nil else passOf(product)
		if pass then
			table.insert(passes, pass)
		end
	end
	-- Colunas e altura: no celular saem da página, já descontada a fileira de cima.
	local grid = vide.derive(function()
		local l = layout()
		local columns, height = ShopLayout.passGrid(l, #passes, ShopLayout.topRowHeight(l))
		return { columns = columns, height = height }
	end)
	local function short(): boolean
		return grid().height < ShopLayout.PASS_CARD_HEIGHT
	end
	local cards: { Instance } = {
		ShopParts.grid(function()
			return grid().columns
		end, function()
			return grid().height
		end, ShopLayout.GAP),
	}
	for order, pass in passes do
		table.insert(cards, card(pass, order, short))
	end
	return create("Frame")({
		Name = "Passes",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, ShopLayout.GAP) }),
		topRow(layout),
		create("Frame")({
			Name = "Cards",
			LayoutOrder = 2,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			cards,
		}),
	}) :: Frame
end

return Passes
