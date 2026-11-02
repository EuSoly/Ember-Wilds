--!strict
-- Conteúdo do painel Comprar Golden Ember (mockup G7a): cinco pacotes com
-- preço em Robux. Comprar só mostra o aviso de compra simulada; nunca chama
-- MarketplaceService nem mexe no saldo.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Kit = require(Client:WaitForChild("UI"):WaitForChild("Kit"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))

local create = vide.create

local function packCard(pack: MockStore.Pack): Frame
	local children: { Instance } = {
		create("UICorner")({ CornerRadius = Theme.corner }) :: Instance,
		Kit.text({
			Name = "Amount",
			Position = UDim2.fromScale(0.5, 0.3),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.92, 0.22),
			FontFace = Theme.font.number,
			Text = Strings.format("mock.pack.amount", { amount = pack.amount }),
			maxSize = 22,
		}),
		Kit.text({
			Name = "Robux",
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0.16),
			FontFace = Theme.font.body,
			Text = Strings.format("mock.pack.robux", { robux = pack.robux }),
			maxSize = 18,
		}),
		create("TextButton")({
			Name = "Buy",
			Text = "",
			AutoButtonColor = true,
			Position = UDim2.fromScale(0.5, 0.97),
			AnchorPoint = Vector2.new(0.5, 1),
			Size = UDim2.fromScale(0.86, 0.26),
			BackgroundColor3 = Theme.ui.action,
			BorderSizePixel = 0,
			create("UISizeConstraint")({ MinSize = Theme.touchMinSize }),
			create("UICorner")({ CornerRadius = Theme.corner }),
			Activated = function()
				MenuState.notify(Strings.get("mock.simulated"))
			end,
			Kit.text({
				Size = UDim2.fromScale(0.9, 0.6),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Theme.font.number,
				Text = Strings.get("mock.buy"),
				maxSize = 20,
			}),
		}),
	}
	if pack.tag ~= nil then
		table.insert(
			children,
			Kit.pill({
				Name = "Tag",
				Position = UDim2.fromScale(0.5, 0.08),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Size = UDim2.fromScale(0.7, 0.14),
				BackgroundColor3 = Theme.ui.warning,
				text = Strings.get("mock.tag." .. pack.tag),
			})
		)
	end
	return create("Frame")({
		Name = "Pack_" .. pack.amount,
		BackgroundColor3 = Theme.ui.panelRaised,
		BorderSizePixel = 0,
		children,
	}) :: Frame
end

local BuyPanel = {}

function BuyPanel.build(): Frame
	local cards: { Instance } = {
		create("UIGridLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			CellSize = UDim2.fromScale(0.31, 0.46),
			CellPadding = UDim2.fromScale(0.025, 0.04),
		}) :: Instance,
	}
	for _, pack in MockStore.PACKS do
		table.insert(cards, packCard(pack))
	end
	return create("Frame")({
		Name = "Buy",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.02, 0.15),
		Size = UDim2.fromScale(0.96, 0.82),
		create("ScrollingFrame")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 6,
			CanvasSize = UDim2.fromScale(0, 0),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			cards,
		}),
	}) :: Frame
end

return BuyPanel
