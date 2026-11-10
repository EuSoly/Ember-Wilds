--!strict
-- Pacotes em destaque (Shop/Bundles): um banner grande por vez, com setas e
-- bolinhas para trocar, contador até o fim da oferta, raridade, prévia das
-- skins, lista do que vem e preço. Só aparecem os pacotes dentro da data (a
-- lista é refeita a cada segundo). Troca sozinho a cada AUTO_SECONDS enquanto
-- a loja está aberta e sem a tela do giro por cima. Comprar = pedido ao
-- servidor (Robux ainda não é cobrado); comprado mostra "Comprado".
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local Products = require(Shared:WaitForChild("Shop"):WaitForChild("Products"))
local ShopLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("ShopLayout"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local ShopData = require(Client:WaitForChild("ShopData"))
local Purchase = require(script.Parent.Parent:WaitForChild("Purchase"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))
local ShopState = require(script.Parent:WaitForChild("ShopState"))
local RewardView = require(script.Parent:WaitForChild("RewardView"))

local create = vide.create
local R = Theme.rustic

local AUTO_SECONDS = 6
-- Fundo (ShopImages.CARD) de cada pacote, pela cor do tema (sem entrada = degradê).
local BUNDLE_ART: { [string]: string } = { brasa = "red", geada = "blue", musgo = "green" }
local ARROW = 44
local RIGHT_EDGE = -(ARROW + 22) -- a coluna da direita fica longe da seta
local MAX_PREVIEW = 4 -- skins na prévia (a primeira maior)

local Featured = {}

local function rarityColor(rarity: number): Color3
	return Color3.fromHex(MockStore.RARITIES[rarity].color)
end

local function rarityName(rarity: number): string
	return Strings.get(MockStore.RARITIES[rarity].nameKey)
end

-- "2D 10H 7M" a partir de segundos.
local function timerText(seconds: number): string
	local s = math.max(math.floor(seconds), 0)
	return Strings.format("shop.timer", { d = s // 86400, h = (s % 86400) // 3600, m = (s % 3600) // 60 })
end

local function slide(product: Products.Product, visible: () -> boolean, now: () -> number): Frame
	local bundleId = string.sub(product.id, #"bundle_" + 1)
	local def = Products.bundleDef(bundleId) :: Products.BundleDef
	local theme = Color3.fromHex(def.theme)
	local preview: { Instance } = {
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 8),
		}) :: Instance,
	}
	-- Prévia: as skins do pacote, a primeira grande e as outras menores.
	local shown = 0
	for _, reward in product.rewards do
		if shown < MAX_PREVIEW then
			local tile = RewardView.tile(reward, if shown == 0 then 0.62 else 0.36)
			if tile then
				shown += 1
				tile.LayoutOrder = shown
				table.insert(preview, tile)
			end
		end
	end
	local list: { Instance } = {
		create("UIListLayout")({ HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 2) }) :: Instance,
	}
	local lineHeight = 1 / math.max(#product.rewards, 4) - 0.02
	for i, reward in product.rewards do
		table.insert(
			list,
			ShopParts.outlined({
				LayoutOrder = i,
				Size = UDim2.fromScale(1, lineHeight),
				FontFace = Theme.font.number,
				Text = RewardView.text(reward),
				TextXAlignment = Enum.TextXAlignment.Right,
				maxSize = 22,
			})
		)
	end

	return ShopParts.vividCard(theme, {
		art = BUNDLE_ART[bundleId],
		Name = "Slide_" .. bundleId,
		Visible = visible,
		Size = UDim2.fromScale(1, 1),
		create("Frame")({
			Name = "Preview",
			Position = UDim2.new(0, ARROW + 22, 0.08, 0),
			Size = UDim2.fromScale(0.42, 0.6),
			BackgroundTransparency = 1,
			preview,
		}),
		ShopParts.outlined({
			Name = "BundleName",
			Position = UDim2.new(0, ARROW + 22, 0.66, 0),
			Size = UDim2.fromScale(0.5, 0.18),
			FontFace = Theme.font.title,
			Text = string.upper(Strings.get(def.nameKey)),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 48,
		}),
		Rustic.label({
			Name = "Rarity",
			Position = UDim2.new(0, ARROW + 22, 0.85, 0),
			Size = UDim2.fromScale(0.16, 0.1),
			BackgroundTransparency = 0,
			BackgroundColor3 = rarityColor(def.rarity),
			dark = true,
			FontFace = Theme.font.number,
			Text = rarityName(def.rarity), -- sem upper: string.upper não sabe acentos
			maxSize = 18,
			create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
			create("UIStroke")({ Color = R.outline, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		}),
		ShopParts.outlined({
			Name = "Timer",
			Visible = product.endsAt ~= nil,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, RIGHT_EDGE, 0.07, 0),
			Size = UDim2.fromScale(0.26, 0.13),
			BackgroundTransparency = 0.3,
			BackgroundColor3 = R.outline,
			FontFace = Theme.font.number,
			Text = function()
				local endsAt = product.endsAt
				return if endsAt then "⏰ " .. timerText(endsAt - now()) else ""
			end,
			maxSize = 24,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		}),
		create("Frame")({
			Name = "Items",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, RIGHT_EDGE, 0.24, 0),
			Size = UDim2.fromScale(0.34, 0.44),
			BackgroundTransparency = 1,
			list,
		}),
		ShopParts.priceButton({
			robux = product.price.amount,
			owned = function()
				return ShopData.purchased(product.id)
			end,
			onClick = function()
				Purchase.buy(product.id)
			end,
			anchor = Vector2.new(1, 1),
			position = UDim2.new(1, RIGHT_EDGE, 0.9, 0),
			size = UDim2.fromScale(0.22, 0.2),
			textSize = 28,
		}),
	})
end

-- Monta a seção (chamar dentro do root Vide). `open` = loja aberta.
function Featured.build(layout: () -> ShopLayout.Layout, open: () -> boolean): Frame
	local all: { Products.Product } = {}
	for _, product in Products.all() do
		if product.kind == "bundle" then
			table.insert(all, product)
		end
	end
	local now = vide.source(os.time())
	-- Ids dos pacotes abertos agora, na ordem de Shop/Bundles.
	local openIds = vide.derive(function(): { string }
		local ids: { string } = {}
		for _, product in Products.bundles(now()) do
			table.insert(ids, product.id)
		end
		return ids
	end)
	local current = vide.source(1)
	local sinceSwap = 0 -- segundos desde a última troca (as setas zeram)

	local function count(): number
		return #openIds()
	end

	local function go(step: number)
		sinceSwap = 0
		local n = vide.untrack(count)
		if n > 0 then
			current((vide.untrack(current) - 1 + step) % n + 1)
		end
	end

	-- Um relógio só: atualiza o contador, a lista de abertos e troca o destaque.
	local alive = true
	vide.cleanup(function()
		alive = false
	end)
	task.spawn(function()
		while alive do
			task.wait(1)
			now(os.time())
			local n = vide.untrack(count)
			if vide.untrack(current) > n then
				current(1)
			end
			if vide.untrack(open) and vide.untrack(ShopState.spinType) == nil then
				sinceSwap += 1
				if sinceSwap >= AUTO_SECONDS and n > 1 then
					go(1)
				end
			else
				sinceSwap = 0
			end
		end
	end)

	local children: { Instance } = {}
	for _, product in all do
		table.insert(
			children,
			slide(product, function()
				return openIds()[current()] == product.id
			end, function()
				return now()
			end)
		)
	end

	local dots: { Instance } = {
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 8),
		}) :: Instance,
	}
	for i in all do
		table.insert(
			dots,
			create("Frame")({
				LayoutOrder = i,
				Visible = function()
					return i <= count()
				end,
				Size = UDim2.fromOffset(12, 12),
				BackgroundColor3 = R.cream,
				BackgroundTransparency = function()
					return if current() == i then 0 else 0.6
				end,
				BorderSizePixel = 0,
				create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			})
		)
	end

	local function arrow(name: string, text: string, x: number, anchorX: number, step: number): TextButton
		return Rustic.button({
			Name = name,
			Visible = function()
				return count() > 1
			end,
			AnchorPoint = Vector2.new(anchorX, 0.5),
			Position = UDim2.new(x, if anchorX == 0 then 10 else -10, 0.5, 0),
			Size = UDim2.fromOffset(ARROW, ARROW),
			ZIndex = 5,
			kind = "wood",
			text = text,
			Activated = function()
				go(step)
			end,
		})
	end

	return create("Frame")({
		Name = "Featured",
		Size = function()
			return UDim2.new(1, 0, 0, layout().bannerHeight)
		end,
		BackgroundTransparency = 1,
		create("UIStroke")({ Color = R.emberLight, Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		create("UICorner")({ CornerRadius = UDim.new(0, 12) }),
		children,
		-- Nenhum pacote dentro da data agora.
		ShopParts.outlined({
			Name = "Empty",
			Visible = function()
				return count() == 0
			end,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.8, 0.2),
			FontFace = Theme.font.number,
			Text = Strings.get("shop.bundle.none"),
			maxSize = 28,
		}),
		arrow("Prev", "◀", 0, 0, -1),
		arrow("Next", "▶", 1, 1, 1),
		create("Frame")({
			Name = "Dots",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.fromOffset(120, 12),
			BackgroundTransparency = 1,
			ZIndex = 5,
			dots,
		}),
	}) :: Frame
end

return Featured
