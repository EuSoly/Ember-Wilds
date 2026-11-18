--!strict
-- Check-in de 7 dias (UI): botão de calendário abaixo do saldo, com bolinha
-- quando há prêmio, e a janela com 7 cartões (o dia 7 maior). Estados do
-- cartão (CheckInRules.stateOf): resgatado, hoje (com RESGATAR), trancado
-- (já resgatou hoje) e futuro. Tudo é lido da pasta Player.Shop (CheckInDay,
-- CheckInReady, escritos pelo servidor); RESGATAR só pede (Net.CheckInClaim).
-- Abre sozinha ao entrar no menu com prêmio, uma vez por sessão.
-- Artes em MonetizationImages (id vazio = desenho por código): janela 11,
-- cartões 12/13 nos 4 estados, carimbo 14, calendário 15 e bolinha 16. O dia 7,
-- enquanto ainda vale (hoje ou futuro), usa as camadas 43 com os efeitos
-- dourados (UI/CardFx, canal "checkin", só com a janela aberta).
-- Cada cartão mostra o prêmio em selo (Shop/RewardBadge): o ícone (moeda,
-- roleta, giro especial, kit) e a quantidade, na letra de título com contorno
-- (lê sobre o papel claro e sobre o cartão escuro).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local MenuLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("MenuLayout"))
local CheckInRules = require(Shared:WaitForChild("Shop"):WaitForChild("CheckInRules"))
local RewardBadge = require(Shared:WaitForChild("Shop"):WaitForChild("RewardBadge"))
local MissionImages = require(Shared:WaitForChild("MissionImages"))
local ShopImages = require(Shared:WaitForChild("ShopImages"))
local UiImages = require(Shared:WaitForChild("UiImages"))
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
local CardFx = require(Client:WaitForChild("UI"):WaitForChild("CardFx"))
local ScreenMetrics = require(Client:WaitForChild("UI"):WaitForChild("ScreenMetrics"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local RewardView = require(script.Parent:WaitForChild("Shop"):WaitForChild("RewardView"))
local ShopParts = require(script.Parent:WaitForChild("Shop"):WaitForChild("ShopParts"))

local create = vide.create
local R = Theme.rustic

type Source<T> = (() -> T) & ((T) -> T)
type CardState = CheckInRules.CardState

local WINDOW_MAX = Vector2.new(720, 440)
local DIM_BLEED = 200 -- px que o escurecido passa da área segura para cada lado
local TITLE_HEIGHT = 52
local CLOSE_HEIGHT = 46
local GOT_SECONDS = 4
local DAYS = #ShopConfig.CHECKIN

local BODY = Color3.fromHex("#2B2018")
local DAY7_GLOW = Color3.fromHex("#FFD45A") -- efeitos do dia 7: dourado
local WINDOW_SLICE_SHARE = 0.5 -- borda da janela e dos cartões mais fina que a proporcional
local CARD_SLICE_SHARE = 0.6
-- Recuo do conteúdo no cartão (fração do lado): o texto não encosta na borda
-- desenhada da arte (~34 px de 240 na arte 12). Em cima é maior: com 0,07 o
-- contorno do "DIA 3" encostava na moldura (teste de 18/11/2026).
local CARD_INSET_X = 0.09
local CARD_INSET_TOP = 0.1
local CARD_INSET_BOTTOM = 0.07
-- Faixas do conteúdo (fração da altura útil do cartão): título do dia, ícone,
-- quantidade, nome do prêmio e o rodapé do estado (RESGATAR, "Volte amanhã"
-- ou o selo de resgatado). O rodapé tem lugar próprio: o selo não cobre mais
-- o ícone do prêmio.
type Bands = { day: number, icon: number, amount: number, label: number, footer: number }
local SMALL_BANDS: Bands = { day = 0.16, icon = 0.36, amount = 0.14, label = 0.11, footer = 0.21 }
local BIG_BANDS: Bands = { day = 0.12, icon = 0.44, amount = 0.12, label = 0.09, footer = 0.17 }
-- Menor letra no PC (no celular baixo, ScreenMetrics.short, vale 10).
local DAY_TITLE_MIN = 18
local AMOUNT_MIN = 16
local LABEL_MIN = 12
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

-- Imagem 9-slice da arte (some se o id está vazio), com o SliceScale
-- acompanhando o tamanho da peça (arte de `size` px, fração `share`).
local function sliced(image: () -> string, slice: Rect, size: Vector2, share: number, props: { [any]: any }): ImageLabel
	props.BackgroundTransparency = 1
	props.Image = image
	local visible = props.Visible
	props.Visible = function()
		return MonetizationImages.has(image()) and (visible == nil or visible())
	end
	props.ScaleType = Enum.ScaleType.Slice
	props.SliceCenter = slice
	local label = create("ImageLabel")(props) :: ImageLabel
	Rustic.fitSlice(label, size, share)
	return label
end

-- Imagem do ícone de um selo de prêmio ("" = sem ícone: vale o texto inteiro).
local function badgeImage(badge: RewardBadge.Badge): string
	local icon = badge.icon
	if icon == "coin" then
		return UiImages.COIN
	elseif icon == "spinNormal" then
		return ShopImages.TAB.spins or ""
	elseif icon == "spinPaid" then
		return MissionImages.ICON.premio_giro_especial or ""
	elseif icon == "kit" and badge.kitId then
		return MonetizationImages.KIT[badge.kitId] or ""
	end
	return ""
end

-- Menor letra: a do PC, ou 10 no celular baixo (os cartões ficam com ~85 px).
local function minSize(pc: number): () -> number
	return function()
		return if ScreenMetrics.short() then 10 else pc
	end
end

-- Um cartão de dia (o 7 usa a arte e a letra maiores).
local function dayCard(day: number, currentDay: () -> number, ready: () -> boolean): Frame
	local big = day == DAYS
	local function state(): CardState
		return CheckInRules.stateOf(day, currentDay(), ready())
	end
	-- Dia 7 hoje ou no futuro: as camadas 43 com os efeitos (se enviadas).
	local function layered(): boolean
		local s = state()
		return big and (s == "today" or s == "future") and MonetizationImages.hasLayers(MonetizationImages.DAY7_LAYERS)
	end
	local function art(): string
		if layered() then
			return MonetizationImages.DAY7_LAYERS.base
		end
		local set = if big then MonetizationImages.CHECKIN_DAY7 else MonetizationImages.CHECKIN_DAY
		return set[state()] or ""
	end
	local slice = if big then MonetizationImages.CHECKIN_DAY7_SLICE else MonetizationImages.CHECKIN_DAY_SLICE
	local artSize = if big then MonetizationImages.CHECKIN_DAY7_SIZE else MonetizationImages.CHECKIN_DAY_SIZE
	local reward = ShopConfig.CHECKIN[day]
	local rewardText = RewardView.text(reward)
	local badge = RewardBadge.of(reward)
	local icon = badgeImage(badge)
	local hasIcon = icon ~= ""
	-- Futuro e trancado ficam um pouco apagados.
	local function dimmed(): number
		local s = state()
		return if s == "future" or s == "locked" then 0.2 else 0
	end
	-- Posição vertical de cada faixa (fração da altura útil).
	local bands = if big then BIG_BANDS else SMALL_BANDS
	local iconY = bands.day + 0.02
	local amountY = iconY + bands.icon
	local labelY = amountY + bands.amount
	local footerY = 1 - bands.footer
	local layers: Instance? = nil
	if big and MonetizationImages.hasLayers(MonetizationImages.DAY7_LAYERS) then
		layers = CardFx.layers({
			key = "checkin",
			base = MonetizationImages.DAY7_LAYERS.base,
			frame = MonetizationImages.DAY7_LAYERS.frame,
			size = MonetizationImages.DAY7_LAYERS_SIZE,
			slice = MonetizationImages.DAY7_LAYERS_SLICE,
			fx = DAY7_GLOW,
			center = UDim2.fromScale(0.5, 0.42),
			visible = layered,
			sliceShare = CARD_SLICE_SHARE,
		})
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
		sliced(art, slice, artSize, CARD_SLICE_SHARE, {
			Name = "Art",
			Visible = function()
				return not layered()
			end,
			Size = UDim2.fromScale(1, 1),
			ZIndex = 1,
		}),
		layers,
		-- Conteúdo dentro da borda da arte, de cima para baixo: dia, ícone,
		-- quantidade, nome do prêmio e o rodapé do estado.
		create("Frame")({
			Name = "Content",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			ZIndex = 2,
			create("UIPadding")({
				PaddingLeft = UDim.new(CARD_INSET_X, 0),
				PaddingRight = UDim.new(CARD_INSET_X, 0),
				PaddingTop = UDim.new(CARD_INSET_TOP, 0),
				PaddingBottom = UDim.new(CARD_INSET_BOTTOM, 0),
			}),
			ShopParts.outlined({
				Name = "DayLabel",
				Size = UDim2.fromScale(1, bands.day),
				FontFace = Theme.font.title,
				Text = Strings.format("checkin.day", { day = day }),
				maxSize = if big then 30 else 22,
				minSize = minSize(DAY_TITLE_MIN),
				ZIndex = 2,
			}),
			create("ImageLabel")({
				Name = "RewardIcon",
				Visible = hasIcon,
				AnchorPoint = Vector2.new(0.5, 0),
				Position = UDim2.fromScale(0.5, iconY),
				Size = UDim2.fromScale(1, bands.icon),
				BackgroundTransparency = 1,
				Image = icon,
				ImageTransparency = dimmed,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 2,
			}),
			ShopParts.outlined({
				Name = "Amount",
				Visible = hasIcon,
				Position = UDim2.fromScale(0, amountY),
				Size = UDim2.fromScale(1, bands.amount),
				FontFace = Theme.font.title,
				Text = badge.amount,
				TextTransparency = dimmed,
				maxSize = if big then 36 else 24,
				minSize = minSize(AMOUNT_MIN),
				ZIndex = 2,
			}),
			-- O que é o prêmio ("Golden Ember", "Giros especiais", "Kit Explorador").
			ShopParts.outlined({
				Name = "RewardName",
				Visible = hasIcon,
				Position = UDim2.fromScale(0, labelY),
				Size = UDim2.fromScale(1, bands.label),
				FontFace = Theme.font.title,
				Text = badge.label,
				TextTransparency = dimmed,
				maxSize = if big then 24 else 16,
				minSize = minSize(LABEL_MIN),
				ZIndex = 2,
			}),
			-- Prêmio sem ícone: o texto inteiro.
			ShopParts.outlined({
				Name = "Reward",
				Visible = not hasIcon,
				Position = UDim2.fromScale(0, iconY),
				Size = UDim2.fromScale(1, footerY - iconY - 0.02),
				FontFace = Theme.font.title,
				TextWrapped = true,
				TextTransparency = dimmed,
				Text = rewardText,
				maxSize = if big then 26 else 18,
				ZIndex = 2,
			}),
			-- Rodapé: um por estado (futuro fica vazio). Antes o selo de
			-- resgatado ficava por cima do ícone do prêmio (teste de 18/11/2026).
			Rustic.button({
				Name = "Claim",
				-- No celular baixo o RESGATAR fica embaixo da janela, no meio
				-- (o cartão estreito espremia o conteúdo; 18/11/2026).
				Visible = function()
					return state() == "today" and not ScreenMetrics.short()
				end,
				Position = UDim2.fromScale(0, footerY),
				Size = UDim2.fromScale(1, bands.footer),
				kind = function()
					return if pending() then "disabled" else "ember"
				end,
				text = Strings.get("checkin.claim"),
				maxSize = 18,
				ZIndex = 3,
				Activated = claim,
			}),
			-- "Volte amanhã" na letra de título com contorno, como o resto do cartão.
			ShopParts.outlined({
				Name = "Locked",
				Visible = function()
					return state() == "locked"
				end,
				Position = UDim2.fromScale(0, footerY),
				Size = UDim2.fromScale(1, bands.footer),
				FontFace = Theme.font.title,
				Text = Strings.get("checkin.locked"),
				maxSize = if big then 22 else 16,
				minSize = minSize(LABEL_MIN),
				ZIndex = 3,
			}),
			-- Resgatado: o selo (arte 14) pequeno no rodapé, ou o texto.
			create("ImageLabel")({
				Name = "StampArt",
				Visible = function()
					return state() == "claimed" and MonetizationImages.has(MonetizationImages.CLAIMED_STAMP)
				end,
				Position = UDim2.fromScale(0, footerY),
				Size = UDim2.fromScale(1, bands.footer),
				BackgroundTransparency = 1,
				Image = MonetizationImages.CLAIMED_STAMP,
				ScaleType = Enum.ScaleType.Fit,
				ZIndex = 3,
			}),
			ShopParts.outlined({
				Name = "Stamp",
				Visible = function()
					return state() == "claimed" and not MonetizationImages.has(MonetizationImages.CLAIMED_STAMP)
				end,
				Position = UDim2.fromScale(0, footerY),
				Size = UDim2.fromScale(1, bands.footer),
				FontFace = Theme.font.title,
				Text = Strings.get("checkin.claimed"),
				maxSize = if big then 22 else 16,
				minSize = minSize(LABEL_MIN),
				ZIndex = 3,
			}),
		}),
	}) :: Frame
end

-- A janela: fundo escurecido (segura os cliques; fecha só no Fechar), placa de título, 6 cartões
-- em grade 3x2 à esquerda, o dia 7 maior à direita, aviso do prêmio e Fechar.
function CheckInPanel.build(): Frame
	local currentDay, ready = readState()
	-- Efeitos do dia 7 só com a janela aberta.
	CardFx.run("checkin", open)

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

	-- PC: os dias 1–6 em 3x2 e o 7 à direita. Celular baixo: a janela é baixa
	-- e as duas fileiras espremiam os cartões (teste de 18/11/2026); os 6 vão
	-- numa fileira só, cada um alto e estreito como a arte, e o 7 ao lado.
	local short = ScreenMetrics.short
	local grid = create("Frame")({
		Name = "Grid",
		Size = function()
			return if short() then UDim2.new(0.76, -6, 1, 0) else UDim2.new(0.62, -6, 1, 0)
		end,
		BackgroundTransparency = 1,
		create("UIGridLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			CellPadding = UDim2.fromOffset(8, 8),
			CellSize = function()
				return if short() then UDim2.new(1 / 6, -7, 1, 0) else UDim2.new(1 / 3, -6, 0.5, -4)
			end,
		}),
	}) :: Frame
	for day = 1, DAYS - 1 do
		dayCard(day, currentDay, ready).Parent = grid
	end
	local bigCard = dayCard(DAYS, currentDay, ready)
	bigCard.AnchorPoint = Vector2.new(1, 0)
	bigCard.Position = UDim2.fromScale(1, 0)
	vide.apply(bigCard)({
		Size = function()
			return if short() then UDim2.new(0.24, -6, 1, 0) else UDim2.new(0.38, -6, 1, 0)
		end,
	})

	local window = create("Frame")({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = function()
			return ScreenMetrics.modalPosition(TITLE_HEIGHT / 2)
		end,
		Size = function()
			return ScreenMetrics.modalSize(0.94, TITLE_HEIGHT / 2)
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
		sliced(
			function()
				return MonetizationImages.CHECKIN_WINDOW
			end,
			MonetizationImages.CHECKIN_WINDOW_SLICE,
			MonetizationImages.CHECKIN_WINDOW_SIZE,
			WINDOW_SLICE_SHARE,
			{
				Name = "Art",
				Size = UDim2.fromScale(1, 1),
				ZIndex = 0,
			}
		),
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
			-- Sobre o papel da janela (arte 11) o aviso vai escuro.
			TextColor3 = if MonetizationImages.has(MonetizationImages.CHECKIN_WINDOW) then R.charcoal else R.emberLight,
			Text = gotText,
			maxSize = 20,
			ZIndex = 3,
		}),
		-- Celular baixo: o RESGATAR do dia, embaixo no meio (no PC fica no cartão).
		Rustic.button({
			Name = "ClaimBottom",
			Visible = function()
				return ScreenMetrics.short() and ready()
			end,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -12),
			Size = UDim2.fromOffset(180, CLOSE_HEIGHT),
			kind = function()
				return if pending() then "disabled" else "ember"
			end,
			text = Strings.get("checkin.claim"),
			maxSize = 20,
			ZIndex = 3,
			Activated = claim,
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
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ZIndex = 11, -- acima do aviso do menu (10)
		-- Escurecido da tela inteira: o menu respeita a área segura (barra do
		-- Roblox em cima, entalhe dos lados), então o fundo passa dela para
		-- cobrir também atrás da barra (teste de 18/11/2026: sobrava uma faixa
		-- clara em cima). A ScreenGui não recorta o que sai dela.
		create("Frame")({
			Name = "Dim",
			Position = UDim2.fromOffset(-DIM_BLEED, -DIM_BLEED),
			Size = UDim2.new(1, 2 * DIM_BLEED, 1, 2 * DIM_BLEED),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			ZIndex = 0,
		}),
		-- Segura os cliques por trás da janela (o menu não reage), mas não
		-- fecha: fechar é só no Fechar. Antes tocar fora fechava, e o clique
		-- dentro da janela também chegava aqui (teste de 18/11/2026).
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
