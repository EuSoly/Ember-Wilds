--!strict
-- Gamepasses (provisórias): os kits para sempre e o VIP. Os kits usam o mesmo
-- estado do painel de kits (KitShop): comprar aqui libera o "Usar" lá; kit já
-- possuído mostra "Adquirido". Tudo simulado.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local ShopLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("ShopLayout"))
local ShopImages = require(Shared:WaitForChild("ShopImages"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local ItemIcon = require(Client:WaitForChild("UI"):WaitForChild("ItemIcon"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local MenuState = require(script.Parent.Parent:WaitForChild("MenuState"))
local KitShop = require(script.Parent.Parent:WaitForChild("KitShop"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))

local create = vide.create
local R = Theme.rustic

local CARD_HEIGHT = 236
local GOLD = Color3.fromHex("#E8AE2A")

local Passes = {}

-- Ícone do cartão: o último item do kit (a ferramenta ou a mochila); o VIP
-- ganha uma estrela desenhada.
local function icon(pass: MockStore.Pass): GuiObject
	local box = create("Frame")({
		Name = "Icon",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.12),
		Size = UDim2.fromScale(0.42, 0.42),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		ZIndex = 3,
	}) :: Frame
	local art = ShopImages.PASS[pass.id]
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

local function card(pass: MockStore.Pass, order: number): Frame
	local function owned(): boolean
		return pass.kitId ~= nil and KitShop.state().owned[pass.kitId] == true
	end
	return ShopParts.vividCard(GOLD, {
		art = "orange",
		Name = pass.id,
		LayoutOrder = order,
		ShopParts.badge(Strings.get("shop.provisional")),
		icon(pass),
		ShopParts.outlined({
			Name = "PassName",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.56),
			Size = UDim2.fromScale(0.92, 0.12),
			FontFace = Theme.font.number,
			Text = Strings.get(pass.nameKey),
			maxSize = 22,
		}),
		ShopParts.outlined({
			Name = "Desc",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.fromScale(0.5, 0.68),
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
				robux = pass.robux,
				onClick = function()
					if pass.kitId then
						KitShop.buyForever(pass.kitId) -- mostra o aviso e libera o "Usar"
					else
						MenuState.notify(Strings.get("mock.simulated"))
					end
				end,
				size = UDim2.fromScale(1, 1),
			}),
			-- Kit já possuído: cobre o preço com "Adquirido".
			Rustic.button({
				Name = "Owned",
				Visible = owned,
				Size = UDim2.fromScale(1, 1),
				ZIndex = 5,
				kind = "disabled",
				text = Strings.get("shop.owned"),
			}),
		}),
	})
end

function Passes.build(layout: () -> ShopLayout.Layout): Frame
	local children: { Instance } = {
		ShopParts.grid(function()
			return layout().passColumns
		end, CARD_HEIGHT, ShopLayout.GAP),
	}
	for i, pass in MockStore.PASSES do
		table.insert(children, card(pass, i))
	end
	return create("Frame")({
		Name = "Passes",
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		children,
	}) :: Frame
end

return Passes
