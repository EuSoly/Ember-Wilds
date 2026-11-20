--!strict
-- Códigos de resgate no menu (spec 2026-11-18-codigos-design): o botão
-- embaixo do calendário do check-in (só no menu "limpo", como o calendário) e
-- a janela. O servidor (CodeService) confere; a resposta mostra os prêmios
-- (lista de Shop/Codes) ou o motivo. Na partida não existe: o menu some quando
-- o jogador nasce.
--
-- A janela tem duas colunas (cabe no celular deitado, 749×330):
--   esquerda: "NOVO CÓDIGO: X" (o código em destaque, Shop/Codes `news`) e o
--             aviso de que vêm mais códigos no Discord; campo, Resgatar e a
--             resposta.
--   direita:  o grupo do Roblox (Shop/GroupReward): Entrar no grupo abre a
--             janela do Roblox; entrou, o cliente pede o prêmio e o servidor
--             confere. Some com GROUP_ID = 0.
-- O botão acende a bolinha vermelha enquanto há algo para pegar (código em
-- destaque não usado ou prêmio do grupo) e o jogador ainda não abriu a
-- janela nesta sessão.
local GroupService = game:GetService("GroupService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local CodeRules = require(Shared:WaitForChild("Shop"):WaitForChild("CodeRules"))
local Codes = require(Shared:WaitForChild("Shop"):WaitForChild("Codes"))
local GroupReward = require(Shared:WaitForChild("Shop"):WaitForChild("GroupReward"))
local GiftImages = require(Shared:WaitForChild("GiftImages"))
local MenuLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("MenuLayout"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local PopIn = require(Client:WaitForChild("UI"):WaitForChild("PopIn"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local ScreenMetrics = require(Client:WaitForChild("UI"):WaitForChild("ScreenMetrics"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local RewardView = require(script.Parent:WaitForChild("Shop"):WaitForChild("RewardView"))

local create = vide.create
local R = Theme.rustic

type Source<T> = (() -> T) & ((T) -> T)

local WINDOW_MAX = Vector2.new(660, 330)
local TITLE_HEIGHT = 52
local BUTTON_HEIGHT = 44
local PAD = 16
local DIM_BLEED = 200
local OK_COLOR = Color3.fromRGB(46, 140, 52)
local GROUP_ID = GroupReward.GROUP_ID
local HAS_GROUP = GROUP_ID > 0

local CodePanel = {}

local open: Source<boolean> = vide.source(false) :: any
CodePanel.open = open
local sending: Source<boolean> = vide.source(false) :: any
local result: Source<string> = vide.source("") :: any
local resultOk: Source<boolean> = vide.source(false) :: any
local groupSending: Source<boolean> = vide.source(false) :: any
local groupResult: Source<string> = vide.source("") :: any
local groupOk: Source<boolean> = vide.source(false) :: any
-- Já abriu a janela nesta sessão (a bolinha apaga).
local seen: Source<boolean> = vide.source(false) :: any

-- Ícone do botão: o passarinho; sem ele, a arte dos códigos; sem ela, o presente.
local function icon(): string
	if MonetizationImages.has(MonetizationImages.CODES_BIRD) then
		return MonetizationImages.CODES_BIRD
	end
	return if MonetizationImages.has(MonetizationImages.CODES_ICON)
		then MonetizationImages.CODES_ICON
		else GiftImages.ICON
end

local function rewardsText(rewards: { any }): string
	local names = {}
	for _, reward in rewards do
		table.insert(names, RewardView.text(reward))
	end
	return table.concat(names, ", ")
end

-- "skin LIMITADA Gaio-azul + 200 Golden Ember": a skin do prêmio e o resto.
local function groupRewardText(): string
	local skin = ""
	local extra = {}
	for _, reward in GroupReward.rewards do
		if reward.kind == "cosmetic" and skin == "" then
			skin = RewardView.text(reward)
		else
			table.insert(extra, RewardView.text(reward))
		end
	end
	return Strings.format("codes.group.reward", { skin = skin, extra = table.concat(extra, " + ") })
end

local function refusalText(prefix: string, reason: string?): string
	for _, key in { `{prefix}.{reason or "error"}`, `codes.result.{reason or "error"}` } do
		if Strings.has(key) then
			return Strings.get(key)
		end
	end
	return Strings.get("codes.result.error")
end

Net.CodeResult.On(function(data: { Ok: boolean, Reason: string?, Code: string? })
	sending(false)
	resultOk(data.Ok)
	if data.Ok then
		local def = if data.Code then CodeRules.find(Codes, data.Code) else nil
		result(Strings.format("codes.result.ok", { rewards = if def then rewardsText(def.rewards) else "" }))
		return
	end
	result(refusalText("codes.result", data.Reason))
end)

Net.GroupRewardResult.On(function(data: { Ok: boolean, Reason: string? })
	groupSending(false)
	groupOk(data.Ok)
	if data.Ok then
		groupResult(Strings.format("codes.group.result.ok", { rewards = rewardsText(GroupReward.rewards) }))
		return
	end
	groupResult(refusalText("codes.group.result", data.Reason))
end)

-- Estado da pasta Shop (precisa de root Vide): código em destaque não usado e
-- prêmio do grupo já pego.
local function readState(): (() -> boolean, () -> boolean)
	local notice = Sources.childAttribute(Players.LocalPlayer, StatNames.ShopFolder, StatNames.CodeNotice, false)
	local claimed = Sources.childAttribute(Players.LocalPlayer, StatNames.ShopFolder, StatNames.GroupClaimed, false)
	return function()
		return notice() == true
	end, function()
		return claimed() == true
	end
end

-- Entrar no grupo: a janela do Roblox; entrou (ou já era), pede o prêmio. Se
-- a janela falhar, pede assim mesmo: o servidor confere a entrada.
local function joinGroup()
	if vide.untrack(groupSending) then
		return
	end
	groupSending(true)
	groupResult("")
	task.spawn(function()
		local called, status = pcall(function()
			return GroupService:PromptJoinAsync(GROUP_ID)
		end)
		if called and status == Enum.GroupMembershipStatus.JoinRequestPending then
			groupSending(false)
			groupOk(false)
			groupResult(Strings.get("codes.group.result.pending"))
			return
		end
		if called and status == Enum.GroupMembershipStatus.None then
			groupSending(false)
			groupOk(false)
			groupResult(Strings.get("codes.group.result.notMember"))
			return
		end
		Net.RequestGroupReward.Fire()
	end)
end

-- Botão quadrado embaixo do calendário do check-in.
function CodePanel.button(layout: () -> MenuLayout.Layout, visible: () -> boolean): TextButton
	local notice, claimed = readState()
	local function dot(): boolean
		local pending = notice() or (HAS_GROUP and not claimed())
		return pending and not seen()
	end
	return Rustic.button({
		Name = "CodesButton",
		Visible = function()
			return visible() and not open()
		end,
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.calendarX, l.calendarY + l.calendarSize + MenuLayout.CALENDAR_GAP * 2)
		end,
		Size = function()
			local side = layout().calendarSize
			return UDim2.fromOffset(side, side)
		end,
		ZIndex = 7,
		kind = "wood",
		Activated = function()
			result("")
			groupResult("")
			seen(true)
			open(true)
		end,
		create("ImageLabel")({
			Name = "Icon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			Size = UDim2.fromScale(0.82, 0.82),
			BackgroundTransparency = 1,
			Image = icon(),
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 8,
		}),
		-- Bolinha de aviso no canto (a mesma do calendário): a arte, se houver, senão um círculo.
		create("ImageLabel")({
			Name = "DotArt",
			Visible = function()
				return dot() and MonetizationImages.has(MonetizationImages.NOTICE_DOT)
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
				return dot() and not MonetizationImages.has(MonetizationImages.NOTICE_DOT)
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

-- Coluna da esquerda: destaque, campo + Resgatar, resposta.
local function codeColumn(): Frame
	local box = create("TextBox")({
		Name = "Input",
		Size = UDim2.new(0.62, -4, 1, 0),
		BackgroundColor3 = R.paper,
		BorderSizePixel = 0,
		ClearTextOnFocus = false,
		PlaceholderText = Strings.get("codes.placeholder"),
		PlaceholderColor3 = R.textSecondaryLight,
		Text = "",
		TextColor3 = R.charcoal,
		FontFace = Theme.font.number,
		TextScaled = true,
		ZIndex = 3,
		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		create("UIStroke")({ Color = R.outline, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		create("UIPadding")({
			PaddingLeft = UDim.new(0, 10),
			PaddingRight = UDim.new(0, 10),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
		create("UITextSizeConstraint")({ MaxTextSize = 22, MinTextSize = 12 }),
	}) :: TextBox

	local function redeem()
		local text = box.Text
		if vide.untrack(sending) or CodeRules.normalize(text) == "" then
			return
		end
		sending(true)
		result("")
		Net.RequestCode.Fire({ Code = string.sub(text, 1, 32) })
	end
	box.FocusLost:Connect(function(enterPressed: boolean)
		if enterPressed then
			redeem()
		end
	end)

	-- O código em destaque é lido ao abrir (a data pode virar com o jogo aberto).
	local news = vide.derive(function(): CodeRules.CodeDef?
		return if open() then CodeRules.news(Codes, os.time()) else nil
	end)

	return create("Frame")({
		Name = "CodeColumn",
		Size = if HAS_GROUP then UDim2.fromScale(0.56, 1) else UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 2,
		Rustic.label({
			Name = "NewsTitle",
			Visible = function()
				return news() ~= nil
			end,
			Size = UDim2.fromScale(1, 0.2),
			FontFace = Theme.font.title,
			TextColor3 = R.emberLight,
			Text = function()
				local def = news()
				return if def then Strings.format("codes.news.title", { code = def.code }) else ""
			end,
			maxSize = 26,
			minSize = 12,
			ZIndex = 3,
			create("UIStroke")({ Color = R.outline, Thickness = 2 }),
		}),
		Rustic.label({
			Name = "NewsHint",
			Position = function()
				return if news() ~= nil then UDim2.fromScale(0, 0.21) else UDim2.fromScale(0, 0)
			end,
			Size = function()
				return if news() ~= nil then UDim2.fromScale(1, 0.15) else UDim2.fromScale(1, 0.36)
			end,
			dark = true,
			TextWrapped = true,
			Text = Strings.get("codes.news.hint"),
			maxSize = 16,
			minSize = 10,
			ZIndex = 3,
		}),
		create("Frame")({
			Name = "Row",
			Position = UDim2.fromScale(0, 0.4),
			Size = UDim2.fromScale(1, 0.3),
			BackgroundTransparency = 1,
			ZIndex = 2,
			create("UISizeConstraint")({ MaxSize = Vector2.new(math.huge, BUTTON_HEIGHT) }),
			box :: Instance,
			Rustic.button({
				Name = "Redeem",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.new(0.38, -4, 1, 0),
				kind = function()
					return if sending() then "disabled" else "ember"
				end,
				text = Strings.get("codes.redeem"),
				maxSize = 20,
				ZIndex = 3,
				Activated = redeem,
			}),
		}),
		Rustic.label({
			Name = "Result",
			Position = UDim2.fromScale(0, 0.74),
			Size = UDim2.fromScale(1, 0.26),
			dark = true,
			TextWrapped = true,
			TextColor3 = function()
				return if resultOk() then OK_COLOR else R.emberShadow
			end,
			Text = function()
				return if sending() then Strings.get("codes.sending") else result()
			end,
			maxSize = 16,
			minSize = 10,
			ZIndex = 3,
		}),
	}) :: Frame
end

-- Coluna da direita: o grupo do Roblox.
local function groupColumn(): Frame
	local _, claimed = readState()
	return Rustic.paper({
		Name = "GroupCard",
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = UDim2.fromScale(0.41, 1),
		ZIndex = 2,
		create("Frame")({
			Name = "Content",
			Position = UDim2.fromOffset(8, 6),
			Size = UDim2.new(1, -16, 1, -12),
			BackgroundTransparency = 1,
			ZIndex = 2,
			Rustic.label({
				Name = "Title",
				Size = UDim2.fromScale(1, 0.18),
				FontFace = Theme.font.title,
				dark = true,
				Text = string.upper(Strings.get("codes.group.title")),
				maxSize = 20,
				minSize = 10,
				ZIndex = 3,
			}) :: Instance,
			Rustic.label({
				Name = "Reward",
				Position = UDim2.fromScale(0, 0.19),
				Size = UDim2.fromScale(1, 0.33),
				dark = true,
				TextWrapped = true,
				Text = groupRewardText(),
				maxSize = 16,
				minSize = 9,
				ZIndex = 3,
			}) :: Instance,
			Rustic.button({
				Name = "Join",
				Position = UDim2.fromScale(0, 0.55),
				Size = UDim2.fromScale(1, 0.27),
				kind = function()
					return if claimed() then "owned" elseif groupSending() then "disabled" else "green"
				end,
				text = function()
					if claimed() then
						return Strings.get("codes.group.claimed")
					end
					return Strings.get(if groupSending() then "codes.group.sending" else "codes.group.join")
				end,
				maxSize = 18,
				ZIndex = 3,
				Activated = function()
					if not vide.untrack(claimed) then
						joinGroup()
					end
				end,
				create("UISizeConstraint")({ MaxSize = Vector2.new(math.huge, BUTTON_HEIGHT) }),
			}) :: Instance,
			Rustic.label({
				Name = "Status",
				Position = UDim2.fromScale(0, 0.84),
				Size = UDim2.fromScale(1, 0.16),
				dark = true,
				TextWrapped = true,
				TextColor3 = function()
					return if groupOk() then OK_COLOR else R.emberShadow
				end,
				Text = groupResult,
				maxSize = 14,
				minSize = 9,
				ZIndex = 3,
			}) :: Instance,
		}),
	}) :: Frame
end

function CodePanel.build(): Frame
	local body = create("Frame")({
		Name = "Body",
		Position = UDim2.fromOffset(PAD + 4, TITLE_HEIGHT / 2 + 10),
		Size = UDim2.new(1, -2 * (PAD + 4), 1, -(TITLE_HEIGHT / 2 + 10 + BUTTON_HEIGHT + 22)),
		BackgroundTransparency = 1,
		ZIndex = 2,
		codeColumn() :: Instance,
	}) :: Frame
	if HAS_GROUP then
		groupColumn().Parent = body
	end

	local window = create("Frame")({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = function()
			return ScreenMetrics.modalPosition(TITLE_HEIGHT / 2)
		end,
		Size = function()
			return ScreenMetrics.modalSize(0.8, TITLE_HEIGHT / 2)
		end,
		BackgroundColor3 = R.paper,
		BackgroundTransparency = if MonetizationImages.has(MonetizationImages.CHECKIN_WINDOW) then 1 else 0,
		BorderSizePixel = 0,
		Active = true,
		create("UISizeConstraint")({ MaxSize = WINDOW_MAX }),
		PopIn.scale(open) :: Instance,
		create("ImageLabel")({
			Name = "Art",
			Visible = MonetizationImages.has(MonetizationImages.CHECKIN_WINDOW),
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = MonetizationImages.CHECKIN_WINDOW,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = MonetizationImages.CHECKIN_WINDOW_SLICE,
			SliceScale = 0.4,
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
				Text = string.upper(Strings.get("codes.title")),
				maxSize = 28,
				ZIndex = 4,
				create("UIStroke")({ Color = R.outline, Thickness = 1.5 }),
			}),
		}),
		body,
		Rustic.button({
			Name = "Close",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -12),
			Size = UDim2.fromOffset(140, BUTTON_HEIGHT),
			kind = "wood",
			text = Strings.get("codes.close"),
			maxSize = 20,
			ZIndex = 3,
			Activated = function()
				open(false)
			end,
		}),
	}) :: Frame

	return create("Frame")({
		Name = "Codes",
		Visible = open,
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 11,
		create("Frame")({
			Name = "Dim",
			Position = UDim2.fromOffset(-DIM_BLEED, -DIM_BLEED),
			Size = UDim2.new(1, 2 * DIM_BLEED, 1, 2 * DIM_BLEED),
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 0.45,
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
		window,
	}) :: Frame
end

return CodePanel
