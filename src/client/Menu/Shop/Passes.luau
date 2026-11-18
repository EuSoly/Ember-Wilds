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
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local ItemIcon = require(Client:WaitForChild("UI"):WaitForChild("ItemIcon"))
local ShopData = require(Client:WaitForChild("ShopData"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local Purchase = require(script.Parent.Parent:WaitForChild("Purchase"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))
local BoostCard = require(script.Parent:WaitForChild("BoostCard"))
local PremiumCard = require(script.Parent:WaitForChild("PremiumCard"))
local VipCard = require(script.Parent:WaitForChild("VipCard"))

local create = vide.create
local R = Theme.rustic

local GOLD = Color3.fromHex("#E8AE2A")

type Source<T> = (() -> T) & ((T) -> T)

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

-- Arte do cartão: o ícone do kit (30–36) ou o da passe; "" = sem arte.
local function artOf(pass: Pass): string
	if pass.kitId then
		return MonetizationImages.KIT[pass.kitId] or ""
	end
	return PASS_ART[pass.artId] or ""
end

-- Descrição curta do cartão (cabe em duas linhas); sem entrada, a do passe.
local CARD_DESC: { [string]: string } = {
	ember2x = "shop.pass.ember2x.card",
	book = "shop.pass.book.card",
}

-- Ícone do cartão: a arte; sem ela, o último item do kit (a ferramenta ou a
-- mochila) e, nas passes, uma estrela desenhada. Posição e tamanho vêm do card.
local function icon(pass: Pass): Frame
	local box = create("Frame")({
		Name = "Icon",
		BackgroundTransparency = 1,
		ZIndex = 3,
	}) :: Frame
	local art = artOf(pass)
	local kit = if pass.kitId then Defs.Kits[pass.kitId] else nil
	if MonetizationImages.has(art) then
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

local function place(box: () -> ShopLayout.Box?): { [any]: any }
	return {
		Visible = function()
			return box() ~= nil
		end,
		Position = function()
			local b = box()
			return if b then UDim2.fromOffset(b.x, b.y) else UDim2.new()
		end,
		Size = function()
			local b = box()
			return if b then UDim2.fromOffset(b.w, b.h) else UDim2.new()
		end,
	}
end

-- Um cartão. As caixas (ícone, nome, descrição, botão) saem de
-- ShopLayout.passCardParts no tamanho real do cartão: os textos ficam
-- recuados da moldura, o nome pode quebrar em duas linhas e a descrição
-- aparece em duas linhas ou some (celular baixo).
local function card(pass: Pass, order: number, compact: () -> boolean): Frame
	-- Comprado aqui ou ganho por outro caminho (ex. o kit veio num pacote).
	local function owned(): boolean
		if ShopData.purchased(pass.product.id) then
			return true
		end
		return if pass.kitId then ShopData.kitOwned(pass.kitId) else ShopData.hasPass(pass.artId)
	end
	local size: Source<Vector2> = vide.source(Vector2.zero) :: any
	local parts = vide.derive(function()
		local s = size()
		return ShopLayout.passCardParts(s.X, s.Y)
	end)
	local iconBox = vide.apply(icon(pass))(place(function()
		return parts().icon
	end))
	local nameProps = place(function()
		return parts().name
	end)
	nameProps.Name = "PassName"
	nameProps.FontFace = Theme.font.number
	nameProps.Text = Strings.get(pass.nameKey)
	nameProps.TextWrapped = true -- "Kit Sobrevivente" em duas linhas no cartão estreito
	nameProps.maxSize = 22
	nameProps.minSize = function()
		return if compact() then 9 else 12
	end
	nameProps.ZIndex = 3
	local descProps = place(function()
		return parts().desc
	end)
	descProps.Name = "Desc"
	descProps.Text = Strings.get(CARD_DESC[pass.artId] or pass.descKey)
	descProps.TextWrapped = true
	descProps.maxSize = 15
	descProps.minSize = function()
		return if compact() then 10 else ShopLayout.PASS_TEXT_MIN_PC
	end
	descProps.ZIndex = 3
	local buyProps = place(function()
		return parts().button
	end)
	buyProps.Name = "Buy"
	buyProps.BackgroundTransparency = 1
	buyProps.ZIndex = 3
	table.insert(
		buyProps,
		ShopParts.priceButton({
			robux = pass.product.price.amount,
			owned = owned,
			onClick = function()
				Purchase.buy(pass.product.id)
			end,
			size = UDim2.fromScale(1, 1),
		})
	)

	local cardFrame = ShopParts.vividCard(GOLD, {
		art = "orange",
		-- Raios atrás do ícone (ou no alto, no cartão sem ícone).
		fxCenter = function()
			local b = parts().icon
			if b then
				return UDim2.fromOffset(b.x + b.w / 2, b.y + b.h / 2)
			end
			return UDim2.fromScale(0.5, 0.33)
		end,
		-- Kit com o ícone novo: o brilho na cor do tier (MonetizationImages.KIT_GLOW).
		fxColor = if pass.kitId and MonetizationImages.has(artOf(pass))
			then MonetizationImages.KIT_GLOW[pass.kitId]
			else nil,
		Name = pass.artId,
		LayoutOrder = order,
		iconBox,
		ShopParts.outlined(nameProps),
		ShopParts.outlined(descProps),
		create("Frame")(buyProps),
	})
	-- Tamanho do cartão em pixels lógicos (sem os UIScale do caminho).
	local function read()
		size(cardFrame.AbsoluteSize / Rustic.uiScaleOf(cardFrame))
	end
	cardFrame:GetPropertyChangedSignal("AbsoluteSize"):Connect(read)
	cardFrame.AncestryChanged:Connect(read)
	read()
	return cardFrame
end

-- Fileira de cima: VIP (peso 2), boost e, para quem não é Premium, o Premium
-- (as larguras são as de ShopLayout.topRowWidths, em fração da lista).
local function topRow(layout: () -> ShopLayout.Layout): Frame
	local gap = ShopLayout.GAP
	local function compact(): boolean
		return layout().paged
	end
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
		VipCard.build({ LayoutOrder = 1, Size = width(1) }, compact),
		BoostCard.build({ LayoutOrder = 2, Size = width(2) }, compact),
		PremiumCard.build({ LayoutOrder = 3, Size = width(3) }, compact),
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
	local cards: { Instance } = {
		ShopParts.grid(function()
			return grid().columns
		end, function()
			return grid().height
		end, ShopLayout.GAP),
	}
	for order, pass in passes do
		table.insert(
			cards,
			card(pass, order, function()
				return layout().paged
			end)
		)
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
