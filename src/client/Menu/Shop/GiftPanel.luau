--!strict
-- Janela "Presentear" (spec 2026-11-18-presentes-design): o item no topo
-- (ícone com o laço), a lista dos jogadores do servidor menos você e o botão
-- verde de pagar. Quem já tem o item (de uma vez) aparece apagado com "Já
-- tem"; quem não pode receber giros pagos, com "Indisponível". Escolher →
-- RequestGift (o servidor confere de novo e abre a compra do "Presente: X").
-- Fecha só nos botões (como o check-in). Artes em GiftImages (45–50, 55).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local GiftImages = require(Shared:WaitForChild("GiftImages"))
local GiftRules = require(Shared:WaitForChild("Shop"):WaitForChild("GiftRules"))
local Products = require(Shared:WaitForChild("Shop"):WaitForChild("Products"))
local ShopData = require(Shared:WaitForChild("Shop"):WaitForChild("ShopData"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local ClientShop = require(Client:WaitForChild("ShopData"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local PopIn = require(Client:WaitForChild("UI"):WaitForChild("PopIn"))
local ScreenMetrics = require(Client:WaitForChild("UI"):WaitForChild("ScreenMetrics"))
local GiftItem = require(script.Parent:WaitForChild("GiftItem"))
local ShopParts = require(script.Parent:WaitForChild("ShopParts"))

local create = vide.create
local R = Theme.rustic

type Source<T> = (() -> T) & ((T) -> T)

local WINDOW_MAX = Vector2.new(640, 460)
local DIM_BLEED = 200
local TITLE_HEIGHT = 52
local HEADER_HEIGHT = 56
local FOOTER_HEIGHT = 46
local ROW_HEIGHT = 56
-- Foto na linha: dentro da borda da arte 48 (26 px de 110 na altura).
local AVATAR_SIDE = ROW_HEIGHT - 18
local AVATAR_LEFT = 12
local ROW_GAP = 6
local BODY = Color3.fromHex("#2B2018")

local GiftPanel = {}

local current: Source<string?> = vide.source(nil :: string?) :: any
GiftPanel.current = current
local chosen: Source<number?> = vide.source(nil :: number?) :: any -- UserId escolhido
local roster: Source<{ Player }> = vide.source({}) :: any
-- Muda quando alguma pasta Shop dos outros pode ter mudado (reabre a conta).
local stamp: Source<number> = vide.source(0) :: any

function GiftPanel.open(productId: string)
	chosen(nil)
	stamp(stamp() + 1)
	current(productId)
end

local function close()
	current(nil)
	chosen(nil)
end

local function refreshRoster()
	local list = {}
	for _, player in Players:GetPlayers() do
		if player ~= Players.LocalPlayer then
			table.insert(list, player)
		end
	end
	table.sort(list, function(a, b)
		return a.DisplayName:lower() < b.DisplayName:lower()
	end)
	roster(list)
end

-- O que o outro jogador já tem, lido da pasta Player.Shop dele (replica para todos).
local function shopOfOther(player: Player): (ShopData.ShopData, boolean)
	local d = ShopData.empty()
	local root = player:FindFirstChild(StatNames.ShopFolder)
	if root == nil then
		return d, true
	end
	for folderName, set in
		{
			[StatNames.KitsOwnedFolder] = d.KitsOwned,
			[StatNames.PassesFolder] = d.Passes,
			[StatNames.PurchasedFolder] = d.Purchased,
		} :: { [string]: { [string]: boolean } }
	do
		local folder = root:FindFirstChild(folderName)
		if folder then
			for _, child in folder:GetChildren() do
				set[child.Name] = true
			end
		end
	end
	return d, root:GetAttribute(StatNames.PaidRandomBlocked) ~= false
end

-- Motivo de a pessoa não poder receber o item atual (nil = pode).
local function refusalFor(player: Player): string?
	stamp()
	local productId = current()
	local product = if productId then Products.get(productId) else nil
	if product == nil then
		return "unknown"
	end
	local d, blocked = shopOfOther(player)
	return GiftRules.check(product, d, os.time(), false, blocked, false)
end

local function sliced(image: string, size: Vector2, slice: Rect, props: { [any]: any }): ImageLabel
	props.BackgroundTransparency = 1
	props.ScaleType = Enum.ScaleType.Slice
	props.SliceCenter = slice
	props.Image = props.Image or image
	local label = create("ImageLabel")(props) :: ImageLabel
	Rustic.fitSlice(label, size, 0.5)
	return label
end

local function row(player: Player): TextButton
	local headshot: Source<string> = vide.source("") :: any
	task.spawn(function()
		local ok, url = pcall(function()
			return Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
		end)
		if ok then
			headshot(url)
		end
	end)
	local function refusal(): string?
		return refusalFor(player)
	end
	local function selected(): boolean
		return chosen() == player.UserId and refusal() == nil
	end
	local function state(): string
		return if refusal() ~= nil then "off" elseif selected() then "selected" else "normal"
	end
	return create("TextButton")({
		Name = player.Name,
		Size = UDim2.new(1, -10, 0, ROW_HEIGHT),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Activated = function()
			if refusal() == nil then
				chosen(player.UserId)
			end
		end,
		sliced(GiftImages.ROW.normal, GiftImages.ROW_SIZE, GiftImages.ROW_SLICE, {
			Name = "Art",
			Size = UDim2.fromScale(1, 1),
			Image = function()
				return GiftImages.ROW[state()]
			end,
			ZIndex = 1,
		}) :: Instance,
		-- Foto dentro da moldura redonda, as duas dentro da linha.
		create("ImageLabel")({
			Name = "AvatarFrame",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, AVATAR_LEFT, 0.5, 0),
			Size = UDim2.fromOffset(AVATAR_SIDE, AVATAR_SIDE),
			BackgroundTransparency = 1,
			Image = GiftImages.AVATAR_FRAME,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 3,
			create("ImageLabel")({
				Name = "Avatar",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.8, 0.8),
				BackgroundTransparency = 1,
				Image = headshot,
				ImageTransparency = function()
					return if refusal() ~= nil then 0.4 else 0
				end,
				ZIndex = 2,
				create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			}),
		}),
		ShopParts.outlined({
			Name = "PlayerName",
			Position = UDim2.fromOffset(AVATAR_LEFT + AVATAR_SIDE + 10, 0),
			Size = UDim2.new(1, -(AVATAR_LEFT + AVATAR_SIDE + 10 + 120), 1, 0),
			FontFace = Theme.font.title,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = function()
				return if refusal() ~= nil then 0.45 else 0
			end,
			Text = player.DisplayName,
			maxSize = 20,
			minSize = 12,
			ZIndex = 2,
		}),
		Rustic.label({
			Name = "Status",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -14, 0.5, 0),
			Size = UDim2.new(0, 110, 0.5, 0),
			TextXAlignment = Enum.TextXAlignment.Right,
			Visible = function()
				return refusal() ~= nil
			end,
			Text = function()
				local reason = refusal()
				return if reason == "bought" then Strings.get("gift.has") else Strings.get("gift.unavailable")
			end,
			maxSize = 16,
			minSize = 11,
			ZIndex = 2,
		}),
		create("ImageLabel")({
			Name = "Check",
			Visible = selected,
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(ROW_HEIGHT - 18, ROW_HEIGHT - 18),
			BackgroundTransparency = 1,
			Image = GiftImages.CHECK,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 3,
		}),
	}) :: TextButton
end

local function send()
	local productId = vide.untrack(current)
	local userId = vide.untrack(chosen)
	if productId == nil or userId == nil then
		return
	end
	Net.RequestGift.Fire({ ProductId = productId, RecipientUserId = userId })
	close()
end

function GiftPanel.build(): Frame
	refreshRoster()
	Players.PlayerAdded:Connect(refreshRoster)
	Players.PlayerRemoving:Connect(function(player)
		if vide.untrack(chosen) == player.UserId then
			chosen(nil)
		end
		task.defer(refreshRoster)
	end)

	local function price(): number
		local productId = current()
		local product = if productId then Products.get(productId) else nil
		return if product then product.price.amount else 0
	end
	local function canSend(): boolean
		local userId = chosen()
		if userId == nil then
			return false
		end
		local player = Players:GetPlayerByUserId(userId)
		return player ~= nil and refusalFor(player) == nil
	end

	local list = create("ScrollingFrame")({
		Name = "List",
		Position = UDim2.fromOffset(16, TITLE_HEIGHT / 2 + 12 + HEADER_HEIGHT + 8),
		Size = UDim2.new(1, -32, 1, -(TITLE_HEIGHT / 2 + 12 + HEADER_HEIGHT + 8 + FOOTER_HEIGHT + 24)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = R.emberLight,
		CanvasSize = UDim2.new(),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ZIndex = 2,
		create("UIListLayout")({ Padding = UDim.new(0, ROW_GAP), SortOrder = Enum.SortOrder.Name }),
		vide.values(roster, row),
	})

	local window = create("Frame")({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, TITLE_HEIGHT / 4),
		Size = function()
			return UDim2.new(0.94, 0, ScreenMetrics.windowShare(), -TITLE_HEIGHT / 2)
		end,
		BackgroundColor3 = BODY,
		BackgroundTransparency = 1,
		Active = true,
		create("UISizeConstraint")({ MaxSize = WINDOW_MAX }),
		PopIn.scale(function()
			return current() ~= nil
		end) :: Instance,
		sliced(GiftImages.WINDOW, GiftImages.WINDOW_SIZE, GiftImages.WINDOW_SLICE, {
			Name = "Art",
			Size = UDim2.fromScale(1, 1),
			ZIndex = 0,
		}),
		Rustic.plate({
			Name = "TitlePlate",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.new(0.5, 0, 0, TITLE_HEIGHT),
			ZIndex = 3,
			Rustic.label({
				Name = "Title",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.86, 0.6),
				FontFace = Theme.font.title,
				Text = string.upper(Strings.get("gift.title")),
				maxSize = 28,
				ZIndex = 4,
				create("UIStroke")({ Color = R.outline, Thickness = 1.5 }),
			}),
		}),
		-- O item: ícone com o laço no canto e o nome; "Para quem?" embaixo.
		create("Frame")({
			Name = "Header",
			Position = UDim2.fromOffset(16, TITLE_HEIGHT / 2 + 12),
			Size = UDim2.new(1, -32, 0, HEADER_HEIGHT),
			BackgroundTransparency = 1,
			ZIndex = 2,
			create("ImageLabel")({
				Name = "Icon",
				Size = UDim2.fromOffset(HEADER_HEIGHT, HEADER_HEIGHT),
				BackgroundTransparency = 1,
				Image = function()
					local productId = current()
					return if productId then GiftItem.icon(productId) else ""
				end,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 2,
				create("ImageLabel")({
					Name = "Bow",
					AnchorPoint = Vector2.new(1, 0),
					Position = UDim2.new(1, 10, 0, -10),
					Size = UDim2.fromScale(0.85, 0.85),
					BackgroundTransparency = 1,
					Image = GiftImages.BOW,
					ScaleType = Enum.ScaleType.Fit,
					ZIndex = 3,
				}),
			}),
			ShopParts.outlined({
				Name = "ItemName",
				Position = UDim2.fromOffset(HEADER_HEIGHT + 12, 0),
				Size = UDim2.new(1, -(HEADER_HEIGHT + 12), 0.56, 0),
				FontFace = Theme.font.title,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = function()
					local productId = current()
					return if productId then GiftItem.name(productId) else ""
				end,
				maxSize = 24,
				minSize = 14,
				ZIndex = 2,
			}),
			Rustic.label({
				Name = "Ask",
				Position = UDim2.new(0, HEADER_HEIGHT + 12, 0.58, 0),
				Size = UDim2.new(1, -(HEADER_HEIGHT + 12), 0.38, 0),
				TextXAlignment = Enum.TextXAlignment.Left,
				dark = true,
				Text = Strings.get("gift.ask"),
				maxSize = 16,
				minSize = 11,
				ZIndex = 2,
			}),
		}),
		list,
		-- Sozinho no servidor.
		create("Frame")({
			Name = "Empty",
			Visible = function()
				return #roster() == 0
			end,
			Position = list.Position,
			Size = list.Size,
			BackgroundTransparency = 1,
			ZIndex = 2,
			create("ImageLabel")({
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, 0.04),
				Size = UDim2.fromScale(0.6, 0.62),
				SizeConstraint = Enum.SizeConstraint.RelativeYY,
				BackgroundTransparency = 1,
				Image = GiftImages.EMPTY,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 2,
			}),
			Rustic.label({
				AnchorPoint = Vector2.new(0.5, 1),
				Position = UDim2.fromScale(0.5, 1),
				Size = UDim2.fromScale(1, 0.26),
				dark = true,
				Text = Strings.get("gift.empty"),
				maxSize = 18,
				ZIndex = 2,
			}),
		}),
		Rustic.button({
			Name = "Cancel",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 16, 1, -12),
			Size = UDim2.fromOffset(140, FOOTER_HEIGHT),
			kind = "wood",
			text = Strings.get("gift.cancel"),
			maxSize = 20,
			ZIndex = 3,
			Activated = close,
		}),
		-- O mesmo botão verde de Robux da loja; apagado até escolher alguém.
		vide.apply(ShopParts.priceButton({
			robux = price,
			disabled = function()
				return not canSend()
			end,
			onClick = send,
			anchor = Vector2.new(1, 1),
			position = UDim2.new(1, -16, 1, -12),
			size = UDim2.fromOffset(170, FOOTER_HEIGHT),
		}))({ Name = "Send", ZIndex = 3 }),
	}) :: Frame

	return create("Frame")({
		Name = "GiftPanel",
		Visible = function()
			return current() ~= nil
		end,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 12, -- acima do check-in (11)
		create("Frame")({
			Name = "Dim",
			Position = UDim2.fromOffset(-DIM_BLEED, -DIM_BLEED),
			Size = UDim2.new(1, 2 * DIM_BLEED, 1, 2 * DIM_BLEED),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			ZIndex = 0,
		}),
		-- Segura os cliques por trás; fecha só nos botões.
		create("TextButton")({
			Name = "Outside",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
		}),
		window,
	}) :: Frame
end

-- Põe o botãozinho de presente (ícone 45) no canto de cima à direita de
-- `host` (o botão de preço de um item) e devolve `host`. Some se o item não tem
-- presente, ou se é giro pago e você não pode comprar giros.
function GiftPanel.attach<T>(productId: string, host: T): T
	local product = Products.get(productId)
	local random = product ~= nil and Products.hasRandom(product)
	create("ImageButton")({
		Name = "Gift",
		Visible = function()
			return GiftRules.giftable(productId) and not (random and ClientShop.paidRandomBlocked())
		end,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.fromScale(0.85, 0.85),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = GiftImages.ICON,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 6,
		Activated = function()
			GiftPanel.open(productId)
		end,
		Parent = host :: any,
	})
	return host
end

return GiftPanel
