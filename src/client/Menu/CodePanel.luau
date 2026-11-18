--!strict
-- Códigos de resgate no menu (spec 2026-11-18-codigos-design): o botão
-- embaixo do calendário do check-in (só no menu "limpo", como o calendário) e
-- a janela com o campo de texto, Resgatar e Fechar. O servidor (CodeService)
-- confere; a resposta mostra os prêmios (lista de Shop/Codes) ou o motivo.
-- Na partida não existe: o menu some quando o jogador nasce.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local CodeRules = require(Shared:WaitForChild("Shop"):WaitForChild("CodeRules"))
local Codes = require(Shared:WaitForChild("Shop"):WaitForChild("Codes"))
local GiftImages = require(Shared:WaitForChild("GiftImages"))
local MenuLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("MenuLayout"))
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local PopIn = require(Client:WaitForChild("UI"):WaitForChild("PopIn"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local ScreenMetrics = require(Client:WaitForChild("UI"):WaitForChild("ScreenMetrics"))
local RewardView = require(script.Parent:WaitForChild("Shop"):WaitForChild("RewardView"))

local create = vide.create
local R = Theme.rustic

type Source<T> = (() -> T) & ((T) -> T)

local WINDOW_MAX = Vector2.new(460, 250)
local TITLE_HEIGHT = 52
local BUTTON_HEIGHT = 46
local DIM_BLEED = 200
local OK_COLOR = Color3.fromRGB(46, 140, 52)

local CodePanel = {}

local open: Source<boolean> = vide.source(false) :: any
CodePanel.open = open
local sending: Source<boolean> = vide.source(false) :: any
local result: Source<string> = vide.source("") :: any
local resultOk: Source<boolean> = vide.source(false) :: any

-- Ícone do botão: a arte dos códigos quando chegar; até lá, o de presente.
local function icon(): string
	return if MonetizationImages.has(MonetizationImages.CODES_ICON)
		then MonetizationImages.CODES_ICON
		else GiftImages.ICON
end

Net.CodeResult.On(function(data: { Ok: boolean, Reason: string?, Code: string? })
	sending(false)
	resultOk(data.Ok)
	if data.Ok then
		local def = if data.Code then CodeRules.find(Codes, data.Code) else nil
		local names = {}
		if def then
			for _, reward in def.rewards do
				table.insert(names, RewardView.text(reward))
			end
		end
		result(Strings.format("codes.result.ok", { rewards = table.concat(names, ", ") }))
		return
	end
	local key = `codes.result.{data.Reason or "error"}`
	result(Strings.get(if Strings.has(key) then key else "codes.result.error"))
end)

-- Botão quadrado embaixo do calendário do check-in.
function CodePanel.button(layout: () -> MenuLayout.Layout, visible: () -> boolean): TextButton
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
	}) :: TextButton
end

function CodePanel.build(): Frame
	local box = create("TextBox")({
		Name = "Input",
		Position = UDim2.new(0, 0, 0, 0),
		Size = UDim2.new(1, 0, 0, BUTTON_HEIGHT),
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
			PaddingLeft = UDim.new(0, 12),
			PaddingRight = UDim.new(0, 12),
			PaddingTop = UDim.new(0, 8),
			PaddingBottom = UDim.new(0, 8),
		}),
		create("UITextSizeConstraint")({ MaxTextSize = 24, MinTextSize = 12 }),
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

	local window = create("Frame")({
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = function()
			return ScreenMetrics.modalPosition(TITLE_HEIGHT / 2)
		end,
		Size = function()
			return ScreenMetrics.modalSize(0.6, TITLE_HEIGHT / 2)
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
			Size = UDim2.new(0.6, 0, 0, TITLE_HEIGHT),
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
		create("Frame")({
			Name = "Body",
			Position = UDim2.fromOffset(20, TITLE_HEIGHT / 2 + 12),
			Size = UDim2.new(1, -40, 1, -(TITLE_HEIGHT / 2 + 12 + BUTTON_HEIGHT + 24)),
			BackgroundTransparency = 1,
			ZIndex = 2,
			box :: Instance,
			Rustic.label({
				Name = "Result",
				Position = UDim2.fromOffset(0, BUTTON_HEIGHT + 6),
				Size = UDim2.new(1, 0, 1, -(BUTTON_HEIGHT + 6)),
				dark = true,
				TextWrapped = true,
				TextColor3 = function()
					return if resultOk() then OK_COLOR else R.emberShadow
				end,
				Text = function()
					return if sending() then Strings.get("codes.sending") else result()
				end,
				maxSize = 18,
				minSize = 11,
				ZIndex = 3,
			}),
		}),
		Rustic.button({
			Name = "Close",
			AnchorPoint = Vector2.new(0, 1),
			Position = UDim2.new(0, 16, 1, -12),
			Size = UDim2.fromOffset(130, BUTTON_HEIGHT),
			kind = "wood",
			text = Strings.get("codes.close"),
			maxSize = 20,
			ZIndex = 3,
			Activated = function()
				open(false)
			end,
		}),
		Rustic.button({
			Name = "Redeem",
			AnchorPoint = Vector2.new(1, 1),
			Position = UDim2.new(1, -16, 1, -12),
			Size = UDim2.fromOffset(160, BUTTON_HEIGHT),
			kind = function()
				return if sending() then "disabled" else "ember"
			end,
			text = Strings.get("codes.redeem"),
			maxSize = 20,
			ZIndex = 3,
			Activated = redeem,
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
