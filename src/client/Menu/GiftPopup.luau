--!strict
-- Presente recebido (spec 2026-11-18-presentes-design). O servidor manda a
-- fila dos presentes ainda não abertos (Net.GiftInbox, guardada no perfil).
-- - Jogando (fora do menu): cada presente novo vira só um aviso na tela
--   (Notifications, sem janela: janela no meio da luta mata o jogador).
-- - No menu, com fila, sem o check-in nem o pop-up do tutorial na frente:
--   painel (53) com a caixa fechada (51); um toque abre: caixa aberta (52),
--   raios (54) girando atrás, o item subindo, "Fulano te deu de presente" e o
--   nome do item. "Obrigado!" → RequestOpenGift e o próximo da fila.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local GiftImages = require(Shared:WaitForChild("GiftImages"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local ScreenState = require(Client:WaitForChild("ScreenState"))
local TutorialState = require(Client:WaitForChild("TutorialState"))
local Notifications = require(Client:WaitForChild("UI"):WaitForChild("Notifications"))
local PopIn = require(Client:WaitForChild("UI"):WaitForChild("PopIn"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local ScreenMetrics = require(Client:WaitForChild("UI"):WaitForChild("ScreenMetrics"))
local CheckInPanel = require(script.Parent:WaitForChild("CheckInPanel"))
local GiftItem = require(script.Parent:WaitForChild("Shop"):WaitForChild("GiftItem"))
local ShopParts = require(script.Parent:WaitForChild("Shop"):WaitForChild("ShopParts"))

local create = vide.create

type Source<T> = (() -> T) & ((T) -> T)
type Gift = { From: string, ProductId: string }

local PANEL_MAX = Vector2.new(460, 380)
local PANEL_SHARE = 0.86 -- da altura da tela (celular baixo)
local DIM_BLEED = 200
local RAYS_SPEED = 25 -- graus por segundo
local RAYS_COLOR = Color3.fromHex("#FFD45A")

local GiftPopup = {}

local inbox: Source<{ Gift }> = vide.source({}) :: any
local opened: Source<boolean> = vide.source(false) :: any
local sending: Source<boolean> = vide.source(false) :: any
local seen = 0 -- quantos presentes da fila já viraram aviso

Net.GiftInbox.On(function(data: { Gifts: { Gift } })
	local gifts = data.Gifts
	-- Presentes novos fora do menu: só o aviso.
	if vide.untrack(ScreenState.current) ~= "menu" then
		for i = seen + 1, #gifts do
			local gift = gifts[i]
			local vars: { [string]: string | number } = { name = gift.From, item = GiftItem.name(gift.ProductId) }
			Notifications.push("gift.toast", vars, "success")
		end
	end
	seen = #gifts
	local first = vide.untrack(inbox)[1]
	local newFirst = gifts[1]
	-- O primeiro da fila mudou (abriu o anterior): a caixa volta fechada.
	if first == nil or newFirst == nil or first.ProductId ~= newFirst.ProductId or first.From ~= newFirst.From then
		opened(false)
	end
	sending(false)
	inbox(gifts)
end)

local function current(): Gift?
	return inbox()[1]
end

local function thanks()
	local gift = vide.untrack(current)
	if gift == nil or vide.untrack(sending) then
		return
	end
	sending(true)
	Net.RequestOpenGift.Fire({ ProductId = gift.ProductId })
end

function GiftPopup.build(): Frame
	local function shown(): boolean
		return ScreenState.current() == "menu"
			and current() ~= nil
			and not CheckInPanel.open()
			and not TutorialState.popupPending()
	end

	-- Raios girando só com a caixa aberta e o painel na tela.
	local rays = create("ImageLabel")({
		Name = "Rays",
		Visible = opened,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.8, 0.8),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = GiftImages.RAYS,
		ImageColor3 = RAYS_COLOR,
		ImageTransparency = 0.2,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 1,
	}) :: ImageLabel
	RunService.Heartbeat:Connect(function(dt)
		if rays.Visible and rays.Parent ~= nil then
			rays.Rotation = (rays.Rotation + RAYS_SPEED * dt) % 360
		end
	end)

	-- O item sobe de dentro da caixa ao abrir.
	local item = create("ImageLabel")({
		Name = "Item",
		Visible = opened,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.3, 0.3),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = function()
			local gift = current()
			return if gift then GiftItem.icon(gift.ProductId) else ""
		end,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 4,
	}) :: ImageLabel
	vide.effect(function()
		if opened() then
			item.Position = UDim2.fromScale(0.5, 0.5)
			TweenService:Create(
				item,
				TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
				{ Position = UDim2.fromScale(0.5, 0.36) }
			):Play()
		end
	end)

	local box = create("ImageButton")({
		Name = "Box",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.42, 0.42),
		SizeConstraint = Enum.SizeConstraint.RelativeYY,
		BackgroundTransparency = 1,
		Image = function()
			return if opened() then GiftImages.BOX_OPEN else GiftImages.BOX_CLOSED
		end,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 3,
		Activated = function()
			opened(true)
		end,
	})

	local panel = create("ImageLabel")({
		Name = "Panel",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = function()
			return ScreenMetrics.modalPosition(0)
		end,
		Size = function()
			return if ScreenMetrics.short() then ScreenMetrics.modalSize(0.9, 0) else UDim2.fromScale(0.9, PANEL_SHARE)
		end,
		BackgroundTransparency = 1,
		Image = GiftImages.PANEL,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = GiftImages.PANEL_SLICE,
		create("UISizeConstraint")({ MaxSize = PANEL_MAX }),
		PopIn.scale(shown) :: Instance,
		ShopParts.outlined({
			Name = "From",
			Position = UDim2.fromScale(0.06, 0.05),
			Size = UDim2.fromScale(0.88, 0.12),
			FontFace = Theme.font.title,
			Text = function()
				local gift = current()
				return if gift then Strings.format("gift.from", { name = gift.From }) else ""
			end,
			maxSize = 26,
			minSize = 14,
			ZIndex = 4,
		}),
		rays,
		box,
		item,
		ShopParts.outlined({
			Name = "Hint",
			Visible = function()
				return not opened()
			end,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.95),
			Size = UDim2.fromScale(0.8, 0.12),
			FontFace = Theme.font.title,
			Text = Strings.get("gift.tapToOpen"),
			maxSize = 20,
			minSize = 12,
			ZIndex = 4,
		}),
		ShopParts.outlined({
			Name = "ItemName",
			Visible = opened,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.8),
			Size = UDim2.fromScale(0.88, 0.12),
			FontFace = Theme.font.title,
			Text = function()
				local gift = current()
				return if gift then GiftItem.name(gift.ProductId) else ""
			end,
			maxSize = 26,
			minSize = 14,
			ZIndex = 4,
		}),
		Rustic.button({
			Name = "Thanks",
			Visible = opened,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.95),
			Size = UDim2.fromScale(0.5, 0.13),
			kind = function()
				return if sending() then "disabled" else "ember"
			end,
			text = Strings.get("gift.thanks"),
			maxSize = 22,
			ZIndex = 5,
			Activated = thanks,
		}),
	})

	return create("Frame")({
		Name = "GiftPopup",
		Visible = shown,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 13, -- acima da janela Presentear (12)
		create("Frame")({
			Name = "Dim",
			Position = UDim2.fromOffset(-DIM_BLEED, -DIM_BLEED),
			Size = UDim2.new(1, 2 * DIM_BLEED, 1, 2 * DIM_BLEED),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.4,
			BorderSizePixel = 0,
			ZIndex = 0,
		}),
		create("TextButton")({
			Name = "Outside",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
		}),
		panel,
	}) :: Frame
end

return GiftPopup
