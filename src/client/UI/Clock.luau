--!strict
-- Relógio do ciclo (topo, centro), como o rascunho aprovado em 09/11: placa
-- de madeira com uma janelinha de céu à esquerda e "Dia N · 14:30" à direita.
-- O céu muda de cor com a hora (amanhecer, dia, entardecer, noite: ClockFace),
-- o sol atravessa a janelinha de dia e a lua de noite, e as estrelas acendem
-- à noite. Com o Roblox em inglês, mostra "Day N · 2:30 PM".
-- Nos 30 s antes da noite a placa ganha o brilho de alerta e dispara o aviso
-- "A noite está chegando".
local LocalizationService = game:GetService("LocalizationService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local ClockFace = require(Shared:WaitForChild("UIFlow"):WaitForChild("ClockFace"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local UiImages = require(Shared:WaitForChild("UiImages"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Notifications = require(script.Parent:WaitForChild("Notifications"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))
local Sources = require(script.Parent:WaitForChild("Sources"))

local create = vide.create
local R = Theme.rustic

local BODY_SIZE = 0.62 -- sol/lua: fração da altura da janelinha
local ARC = 0.42 -- quanto o sol sobe no meio do caminho (fração da altura)
-- Estrelas da janelinha (posição em fração): sempre as mesmas.
local STARS =
	{ { 0.12, 0.2 }, { 0.3, 0.12 }, { 0.48, 0.3 }, { 0.66, 0.16 }, { 0.82, 0.32 }, { 0.22, 0.42 }, { 0.9, 0.1 } }

local function english(): boolean
	local ok, locale = pcall(function()
		return LocalizationService.RobloxLocaleId
	end)
	return ok and type(locale) == "string" and ClockFace.isEnglish(locale)
end

local function Clock(): Frame
	local cycle = Sources.cycle()
	local twelveHour = english()
	local nightSoon = vide.derive(function()
		return cycle().nightSoon
	end)

	-- Avisa uma vez quando a noite começa a chegar. O aviso é disparado fora do
	-- efeito (task.defer) para não mexer em outra fonte reativa no meio dele.
	local warned = false
	vide.effect(function()
		local soon = nightSoon()
		if soon and not warned then
			warned = true
			task.defer(Notifications.push, "hud.nightComing")
		elseif not soon then
			warned = false
		end
	end)

	local function skyColor(index: number): Color3
		local top, bottom = ClockFace.sky(cycle().hours)
		return Color3.fromHex(if index == 1 then top else bottom)
	end

	-- Sol ou lua: entra pela esquerda, sobe no meio e sai pela direita.
	local function body(isSun: boolean): ImageLabel
		return create("ImageLabel")({
			Name = if isSun then "Sun" else "Moon",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(BODY_SIZE, BODY_SIZE),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
			BackgroundTransparency = 1,
			Image = if isSun then UiImages.SUN else UiImages.MOON,
			ScaleType = Enum.ScaleType.Fit,
			ZIndex = 3,
			Visible = function()
				local isDay = ClockFace.body(cycle().hours)
				return isDay == isSun
			end,
			Position = function()
				local _, p = ClockFace.body(cycle().hours)
				local y = 0.72 - math.sin(p * math.pi) * ARC
				return UDim2.fromScale(0.08 + p * 0.84, y)
			end,
		}) :: ImageLabel
	end

	local stars: { Instance } = {}
	for i, at in STARS do
		table.insert(
			stars,
			create("Frame")({
				Name = "Star" .. i,
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(at[1], at[2]),
				Size = UDim2.fromOffset(3, 3),
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				BackgroundTransparency = function()
					return 1 - ClockFace.stars(cycle().hours)
				end,
				ZIndex = 2,
				create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			})
		)
	end

	return Rustic.plate({
		Name = "Clock",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.02),
		Size = UDim2.fromScale(0.24, 0.075),
		create("UIAspectRatioConstraint")({ AspectRatio = 4.6 }),
		-- Janelinha do céu.
		create("Frame")({
			Name = "Sky",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.1, 0.5),
			Size = UDim2.fromScale(0.3, 0.58),
			BackgroundColor3 = Color3.new(1, 1, 1),
			BorderSizePixel = 0,
			ClipsDescendants = true,
			ZIndex = 2,
			create("UICorner")({ CornerRadius = UDim.new(0.25, 0) }),
			create("UIStroke")({
				Color = function()
					return if nightSoon() then R.emberLight else R.outline
				end,
				Thickness = function()
					return if nightSoon() then 3 else 2
				end,
				ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			}),
			create("UIGradient")({
				Rotation = 90,
				Color = function()
					return ColorSequence.new(skyColor(1), skyColor(2))
				end,
			}),
			stars,
			body(true),
			body(false),
		}),
		Kit.text({
			Name = "Label",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0.44, 0.5),
			Size = UDim2.fromScale(0.5, 0.5),
			FontFace = Theme.font.number,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = function()
				return if nightSoon() then R.emberLight else R.cream
			end,
			ZIndex = 2,
			Text = function()
				local state = cycle()
				local dayKey = if twelveHour then "hud.dayEnglish" else "hud.day"
				return `{Strings.format(dayKey, { day = state.day })} · {ClockFace.timeText(state.hours, twelveHour)}`
			end,
		}),
	}) :: Frame
end

return Clock
