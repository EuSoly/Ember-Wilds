--!strict
-- Check-in de 7 dias (UI): botão de calendário abaixo do saldo, com bolinha
-- quando há prêmio, e a janela com 7 cartões (o dia 7 maior). Estados do
-- cartão (CheckInRules.stateOf): resgatado, hoje (com RESGATAR), trancado
-- (já resgatou hoje) e futuro. Tudo é lido da pasta Player.Shop (CheckInDay,
-- CheckInReady, escritos pelo servidor); RESGATAR só pede (Net.CheckInClaim).
-- Abre sozinha ao entrar no menu com prêmio, uma vez por sessão.
-- Artes em MonetizationImages (id vazio = desenho por código).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local MenuLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("MenuLayout"))
local CheckInRules = require(Shared:WaitForChild("Shop"):WaitForChild("CheckInRules"))
local ShopConfig = require(Shared:WaitForChild("Shop"):WaitForChild("ShopConfig"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local ScreenState = require(Client:WaitForChild("ScreenState"))
local TutorialState = require(Client:WaitForChild("TutorialState"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local PopIn = require(Client:WaitForChild("UI"):WaitForChild("PopIn"))
local ScreenMetrics = require(Client:WaitForChild("UI"):WaitForChild("ScreenMetrics"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local RewardView = require(script.Parent:WaitForChild("Shop"):WaitForChild("RewardView"))

local create = vide.create
local R = Theme.rustic

type Source<T> = (() -> T) & ((T) -> T)
type CardState = CheckInRules.CardState

local WINDOW_MAX = Vector2.new(720, 440)
local TITLE_HEIGHT = 52
local CLOSE_HEIGHT = 46
local GOT_SECONDS = 4
local DAYS = #ShopConfig.CHECKIN

local BODY = Color3.fromHex("#2B2018")
local FACE: { [CardState]: Color3 } = {
	future = Color3.fromHex("#3A2B20"),
	locked = Color3.fromHex("#241A13"),
	today = R.paper,
	claimed = Color3.fromHex("#33402A"),
}

local CheckInPanel = {}

local open: Source<boolean> = vide.source(false) :: any
CheckInPanel.open = open
local pending: Source<boolean> = vide.source(false) :: any -- pedido enviado, sem resposta
local gotText: Source<string> = vide.source("") :: any -- "Dia 1 resgatado: 100 Golden Ember"
local gotGeneration = 0
local autoOpened = false -- já abriu sozinha nesta sessão

-- Resposta do servidor: destrava o botão e mostra o prêmio por um instante.
Net.CheckInResult.On(function(result: { Ok: boolean, Day: number })
	pending(false)
	local reward = ShopConfig.CHECKIN[result.Day]
	local text = if result.Ok and reward
		then Strings.format("checkin.got", { day = result.Day, reward = RewardView.text(reward) })
		else Strings.get("checkin.error")
	gotGeneration += 1
	local mine = gotGeneration
	gotText(text)
	task.delay(GOT_SECONDS, function()
		if mine == gotGeneration then
			gotText("")
		end
	end)
end)

-- Dia atual e "há prêmio hoje", da pasta Shop do jogador (precisa de root Vide).
local function readState(): (() -> number, () -> boolean)
	local day = Sources.childAttribute(Players.LocalPlayer, StatNames.ShopFolder, StatNames.CheckInDay, 1)
	local ready = Sources.childAttribute(Players.LocalPlayer, StatNames.ShopFolder, StatNames.CheckInReady, false)
	return function()
		local v = day()
		return if type(v) == "number" then v else 1
	end, function()
		return ready() == true
	end
end

local function claim()
	if vide.untrack(pending) then
		return
	end
	pending(true)
	Net.CheckInClaim.Fire()
end

-- Imagem 9-slice da arte (some se o id está vazio).
local function sliced(image: () -> string, slice: Rect, props: { [any]: any }): ImageLabel
	props.BackgroundTransparency = 1
	props.Image = image
	props.Visible = function()
		return MonetizationImages.has(image())
	end
	props.ScaleType = Enum.ScaleType.Slice
	props.SliceCenter = slice
	return create("ImageLabel")(props) :: ImageLabel
end

-- Um cartão de dia (o 7 usa a arte e a letra maiores).
local function dayCard(day: number, currentDay: () -> number, ready: () -> boolean): Frame
	local big = day == DAYS
	local function state(): CardState
		return CheckInRules.stateOf(day, currentDay(), ready())
	end
	local function art(): string
		local set = if big then MonetizationImages.CHECKIN_DAY7 else MonetizationImages.CHECKIN_DAY
		return set[state()] or ""
	end
	local slice = if big then MonetizationImages.CHECKIN_DAY7_SLICE else MonetizationImages.CHECKIN_DAY_SLICE
	local rewardText = RewardView.text(ShopConfig.CHECKIN[day])
	local function textColor(): Color3
		return if state() == "today" then R.charcoal else R.cream
	end
	return create("Frame")({
		Name = "Day" .. day,
		LayoutOrder = day,
		BackgroundColor3 = function()
			return FACE[state()]
		end,
		BackgroundTransparency = function()
			return if MonetizationImages.has(art()) then 1 else 0
		end,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0, 10) }),
		create("UIStroke")({
			Enabled = function()
				return not MonetizationImages.has(art())
			end,
			Color = function()
				return if state() == "today" then R.emberLight else R.outline
			end,
			Thickness = function()
				return if state() == "today" then 3 else 2
			end,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		sliced(art, slice, { Name = "Art", Size = UDim2.fromScale(1, 1), ZIndex = 1 }),
		Rustic.label({
			Name = "DayLabel",
			Position = UDim2.fromScale(0.06, 0.04),
			Size = UDim2.fromScale(0.88, 0.2),
			FontFace = Theme.font.number,
			TextColor3 = textColor,
			Text = Strings.format("checkin.day", { day = day }),
			maxSize = if big then 26 else 20,
			ZIndex = 2,
		}),
		Rustic.label({
			Name = "Reward",
			Position = UDim2.fromScale(0.06, 0.26),
			Size = UDim2.fromScale(0.88, 0.34),
			TextColor3 = textColor,
			TextTransparency = function()
				local s = state()
				return if s == "future" or s == "locked" then 0.25 else 0
			end,
			Text = rewardText,
			maxSize = if big then 24 else 17,
			ZIndex = 2,
		}),
		Rustic.button({
			Name = "Claim",
			Visible = function()
				return state() == "today"
			end,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.94),
			Size = UDim2.fromScale(0.84, 0.28),
			kind = function()
				return if pending() then "disabled" else "ember"
			end,
			text = Strings.get("checkin.claim"),
			maxSize = 18,
			ZIndex = 3,
			Activated = claim,
		}),
		Rustic.label({
			Name = "Locked",
			Visible = function()
				return state() == "locked"
			end,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 0.92),
			Size = UDim2.fromScale(0.88, 0.22),
			TextColor3 = R.emberLight,
			Text = Strings.get("checkin.locked"),
			maxSize = 15,
			ZIndex = 3,
		}),
		-- Carimbo "resgatado" por cima do cartão: a arte, ou o texto girado.
		create("ImageLabel")({
			Name = "StampArt",
			Visible = function()
				return state() == "claimed" and MonetizationImages.has(MonetizationImages.CLAIMED_STAMP)
			end,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.7),
			Size = UDim2.fromScale(0.8, 0.4),
			BackgroundTransparency = 1,
			Image = MonetizationImages.CLAIMED_STAMP,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 4,
		}),
		Rustic.label({
			Name = "Stamp",
			Visible = function()
				return state() == "claimed" and not MonetizationImages.has(MonetizationImages.CLAIMED_STAMP)
			end,
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.74),
			Size = UDim2.fromScale(0.84, 0.24),
			Rotation = -10,
			FontFace = Theme.font.title,
			TextColor3 = R.emberLight,
			Text = string.upper(Strings.get("checkin.claimed")),
			maxSize = 22,
			ZIndex = 4,
		}),
	}) :: Frame
end

-- A janela: fundo escurecido (tocar fora fecha), placa de título, 6 cartões
-- em grade 3x2 à esquerda, o dia 7 maior à direita, aviso do prêmio e Fechar.
function CheckInPanel.build(): Frame
	local currentDay, ready = readState()

	-- Abre sozinha ao entrar no menu com prêmio pronto (uma vez por sessão), no
	-- menu "limpo" e sem o pop-up da roleta do tutorial na frente: só marca
	-- como aberta quando abre de fato, e roda de novo quando o pop-up some.
	vide.effect(function()
		local inMenu = ScreenState.current() == "menu"
		if
			inMenu
			and ready()
			and not autoOpened
			and MenuState.panel() == "play"
			and not TutorialState.popupPending()
		then
			autoOpened = true
			open(true)
		end
		-- Saiu do menu: a janela não fica aberta para a próxima volta.
		if not inMenu then
			open(false)
		end
	end)

	local grid = create("Frame")({
		Name = "Grid",
		Size = UDim2.new(0.62, -6, 1, 0),
		BackgroundTransparency = 1,
		create("UIGridLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			CellPadding = UDim2.fromOffset(8, 8),
			CellSize = UDim2.new(1 / 3, -6, 0.5, -4),
		}),
	}) :: Frame
	for day = 1, DAYS - 1 do
		dayCard(day, currentDay, ready).Parent = grid
	end
	local bigCard = dayCard(DAYS, currentDay, ready)
	bigCard.AnchorPoint = Vector2.new(1, 0)
	bigCard.Position = UDim2.fromScale(1, 0)
	bigCard.Size = UDim2.new(0.38, -6, 1, 0)

	local window = create("Frame")({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, TITLE_HEIGHT / 4),
		Size = function()
			return UDim2.new(0.94, 0, ScreenMetrics.windowShare(), -TITLE_HEIGHT / 2)
		end,
		BackgroundColor3 = BODY,
		BackgroundTransparency = if MonetizationImages.has(MonetizationImages.CHECKIN_WINDOW) then 1 else 0,
		BorderSizePixel = 0,
		Active = true,
		create("UISizeConstraint")({ MaxSize = WINDOW_MAX }),
		PopIn.scale(open) :: Instance,
		create("UICorner")({ CornerRadius = UDim.new(0, 12) }),
		create("UIStroke")({
			Enabled = not MonetizationImages.has(MonetizationImages.CHECKIN_WINDOW),
			Color = R.woodShadow,
			Thickness = 4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		sliced(function()
			return MonetizationImages.CHECKIN_WINDOW
		end, MonetizationImages.CHECKIN_WINDOW_SLICE, { Name = "Art", Size = UDim2.fromScale(1, 1), ZIndex = 0 }),
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
				Text = string.upper(Strings.get("checkin.title")),
				maxSize = 28,
				ZIndex = 4,
				create("UIStroke")({ Color = R.outline, Thickness = 1.5 }),
			}),
		}),
		-- Cartões entre o título e a faixa de baixo (aviso + Fechar).
		create("Frame")({
			Name = "Cards",
			Position = UDim2.fromOffset(16, TITLE_HEIGHT / 2 + 12),
			Size = UDim2.new(1, -32, 1, -(TITLE_HEIGHT / 2 + 12 + CLOSE_HEIGHT + 24)),
			BackgroundTransparency = 1,
			grid,
			bigCard,
		}),
		Rustic.label({
			Name = "Got",
			Visible = function()
				return gotText() ~= ""
			end,
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 16, 1, -12),
			Size = UDim2.new(1, -200, 0, CLOSE_HEIGHT),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = R.emberLight,
			Text = gotText,
			maxSize = 20,
			ZIndex = 3,
		}),
		Rustic.button({
			Name = "Close",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -16, 1, -12),
			Size = UDim2.fromOffset(150, CLOSE_HEIGHT),
			kind = "wood",
			text = Strings.get("checkin.close"),
			maxSize = 20,
			ZIndex = 3,
			Activated = function()
				open(false)
			end,
		}),
	}) :: Frame

	return create("Frame")({
		Name = "CheckIn",
		Visible = open,
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.45,
		BorderSizePixel = 0,
		ZIndex = 11, -- acima do aviso do menu (10)
		-- Tocar fora da janela fecha.
		create("TextButton")({
			Name = "Outside",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			Activated = function()
				open(false)
			end,
		}),
		window,
	}) :: Frame
end

-- Botão do calendário abaixo do saldo, com a bolinha quando há prêmio.
function CheckInPanel.button(layout: () -> MenuLayout.Layout, visible: () -> boolean): TextButton
	local currentDay, ready = readState()
	local function hasArt(): boolean
		return MonetizationImages.has(MonetizationImages.CHECKIN_CALENDAR)
	end
	return Rustic.button({
		Name = "CheckInButton",
		Visible = function()
			return visible() and not open()
		end,
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.calendarX, l.calendarY)
		end,
		Size = function()
			local side = layout().calendarSize
			return UDim2.fromOffset(side, side)
		end,
		ZIndex = 7,
		kind = function()
			return if ready() then "ember" else "wood"
		end,
		text = function()
			return if hasArt() then "" else Strings.format("checkin.day", { day = currentDay() })
		end,
		maxSize = 14,
		Activated = function()
			open(true)
		end,
		create("ImageLabel")({
			Name = "Calendar",
			Visible = hasArt,
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = MonetizationImages.CHECKIN_CALENDAR,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 8,
		}),
		-- Bolinha de aviso no canto: a arte, se houver, senão um círculo.
		create("ImageLabel")({
			Name = "DotArt",
			Visible = function()
				return ready() and MonetizationImages.has(MonetizationImages.NOTICE_DOT)
			end,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 4, 0, -4),
			Size = UDim2.fromOffset(18, 18),
			BackgroundTransparency = 1,
			Image = MonetizationImages.NOTICE_DOT,
			ZIndex = 9,
		}),
		create("Frame")({
			Name = "Dot",
			Visible = function()
				return ready() and not MonetizationImages.has(MonetizationImages.NOTICE_DOT)
			end,
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 4, 0, -4),
			Size = UDim2.fromOffset(16, 16),
			BackgroundColor3 = Theme.ui.danger,
			BorderSizePixel = 0,
			ZIndex = 9,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			create("UIStroke")({ Color = R.outline, Thickness = 2 }),
		}),
	}) :: TextButton
end

return CheckInPanel
