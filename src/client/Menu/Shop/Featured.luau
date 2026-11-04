--!strict
-- Pacotes em destaque: um banner grande por vez (MockStore.BUNDLES), com
-- setas e bolinhas para trocar, contador de tempo, raridade, lista do que vem
-- e preço em Robux. Troca sozinho a cada AUTO_SECONDS enquanto a loja está
-- aberta e sem a tela do giro por cima. Compra = aviso de simulação.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local ShopLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("ShopLayout"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local MenuState = require(script.Parent.Parent:WaitForChild("MenuState"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))
local ShopState = require(script.Parent:WaitForChild("ShopState"))
local SpinTile = require(script.Parent:WaitForChild("SpinTile"))

local create = vide.create
local R = Theme.rustic

local AUTO_SECONDS = 6
-- Fundo (ShopImages.CARD) de cada pacote, pela cor do tema.
local BUNDLE_ART: { [string]: string } = { brasa = "red", geada = "blue", musgo = "green" }
local ARROW = 44
local RIGHT_EDGE = -(ARROW + 22) -- a coluna da direita fica longe da seta

local Featured = {}

local function rarityColor(rarity: number): Color3
	return Theme.tier[MockStore.RARITIES[rarity]]
end

local function rarityName(rarity: number): string
	return Strings.get(Defs.Tiers[MockStore.RARITIES[rarity]].rarityKey)
end

-- "2D 10H 7M" a partir de segundos.
local function timerText(seconds: number): string
	local s = math.max(math.floor(seconds), 0)
	return Strings.format("shop.timer", { d = s // 86400, h = (s % 86400) // 3600, m = (s % 3600) // 60 })
end

local function slide(bundle: MockStore.Bundle, index: number, current: () -> number, remaining: () -> number): Frame
	local theme = Color3.fromHex(bundle.theme)
	local preview: { Instance } = {
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 8),
		}) :: Instance,
	}
	-- Prévia: o corpo grande e as outras peças menores, como no carrossel.
	for i, item in bundle.items do
		local size = if i == 1 then 0.62 else 0.36
		local tile = SpinTile.preview(item.type, bundle.theme, bundle.rarity, size)
		tile.LayoutOrder = i
		table.insert(preview, tile)
	end
	local list: { Instance } = {
		create("UIListLayout")({ HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 2) }) :: Instance,
	}
	for i, item in bundle.items do
		table.insert(
			list,
			ShopParts.outlined({
				LayoutOrder = i,
				Size = UDim2.fromScale(1, 0.22),
				FontFace = Theme.font.number,
				Text = Strings.get(item.nameKey),
				TextXAlignment = Enum.TextXAlignment.Right,
				maxSize = 22,
			})
		)
	end

	return ShopParts.vividCard(theme, {
		art = BUNDLE_ART[bundle.id],
		Name = "Slide_" .. bundle.id,
		Visible = function()
			return current() == index
		end,
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
			Text = string.upper(Strings.get(bundle.nameKey)),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 48,
		}),
		Rustic.label({
			Name = "Rarity",
			Position = UDim2.new(0, ARROW + 22, 0.85, 0),
			Size = UDim2.fromScale(0.16, 0.1),
			BackgroundTransparency = 0,
			BackgroundColor3 = rarityColor(bundle.rarity),
			dark = true,
			FontFace = Theme.font.number,
			Text = rarityName(bundle.rarity), -- sem upper: string.upper não sabe acentos
			maxSize = 18,
			create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
			create("UIStroke")({ Color = R.outline, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		}),
		ShopParts.outlined({
			Name = "Timer",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, RIGHT_EDGE, 0.07, 0),
			Size = UDim2.fromScale(0.26, 0.13),
			BackgroundTransparency = 0.3,
			BackgroundColor3 = R.outline,
			FontFace = Theme.font.number,
			Text = function()
				return "⏰ " .. timerText(remaining())
			end,
			maxSize = 24,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		}),
		create("Frame")({
			Name = "Items",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, RIGHT_EDGE, 0.25, 0),
			Size = UDim2.fromScale(0.34, 0.42),
			BackgroundTransparency = 1,
			list,
		}),
		ShopParts.priceButton({
			robux = bundle.robux,
			onClick = function()
				MenuState.notify(Strings.get("mock.simulated"))
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
	local bundles = MockStore.BUNDLES
	local current = vide.source(1)
	local elapsed = vide.source(0) -- segundos desde que o menu montou (contador dos pacotes)

	local function go(step: number)
		current((vide.untrack(current) - 1 + step) % #bundles + 1)
	end

	-- Um relógio só: atualiza o contador e troca o destaque a cada AUTO_SECONDS.
	local alive = true
	vide.cleanup(function()
		alive = false
	end)
	task.spawn(function()
		local sinceSwap = 0
		while alive do
			task.wait(1)
			elapsed(vide.untrack(elapsed) + 1)
			if vide.untrack(open) and vide.untrack(ShopState.spinType) == nil then
				sinceSwap += 1
				if sinceSwap >= AUTO_SECONDS and #bundles > 1 then
					sinceSwap = 0
					go(1)
				end
			else
				sinceSwap = 0
			end
		end
	end)

	local children: { Instance } = {}
	for i, bundle in bundles do
		table.insert(
			children,
			slide(bundle, i, current, function()
				return bundle.endsIn - elapsed()
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
	for i in bundles do
		table.insert(
			dots,
			create("Frame")({
				LayoutOrder = i,
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
			Visible = #bundles > 1,
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
