--!strict
-- Tela do Ranking semanal (UI 6), no painel "ranking" do menu (à direita da
-- coluna). Quadro de papel com moldura, taça + título, "termina em…", as 5
-- abas e o corpo: pódio (top 3) e lista (4º em diante + a sua linha), lado a
-- lado ou empilhados conforme o espaço (RankingLayout).
-- Spec: docs/superpowers/specs/2026-11-09-ranking-semanal-design.md.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MenuLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("MenuLayout"))
local RankConfig = require(Shared:WaitForChild("Data"):WaitForChild("RankConfig"))
local RankRules = require(Shared:WaitForChild("Data"):WaitForChild("RankRules"))
local RankingImages = require(Shared:WaitForChild("RankingImages"))
local RankingLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("RankingLayout"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local MenuState = require(script.Parent.Parent:WaitForChild("MenuState"))
local RankingList = require(script.Parent:WaitForChild("RankingList"))
local RankingPodium = require(script.Parent:WaitForChild("RankingPodium"))
local RankingState = require(script.Parent:WaitForChild("RankingState"))

local create = vide.create
local R = Theme.rustic

local BORDER = 40 -- px lógicos da moldura do quadro (a arte é esticada em 9 partes)
local INSET = 30 -- conteúdo para dentro da moldura
local HEADER = 58
local TROPHY = 64
local CLOSE = 44
local TICK = 20 -- segundos entre atualizações do "termina em…"

local RankingScreen = {}

local function uiScale(instance: Instance): number
	local gui = instance:FindFirstAncestorOfClass("ScreenGui")
	local scale = gui and gui:FindFirstChildOfClass("UIScale")
	return if scale and scale.Scale > 0 then scale.Scale else 1
end

local function outlined(props: { [any]: any }): TextLabel
	table.insert(props, create("UIStroke")({ Color = R.outline, Thickness = 2 }))
	return Rustic.label(props)
end

local function tab(index: number, height: () -> number): TextButton
	local id = RankConfig.CATEGORIES[index]
	local function selected(): boolean
		return RankingState.category() == index
	end
	return create("TextButton")({
		Name = "Tab_" .. id,
		LayoutOrder = index,
		Text = "",
		AutoButtonColor = true,
		-- Escolhida: laranja com borda clara; as outras: madeira.
		BackgroundColor3 = function()
			return if selected() then R.ember else R.walnut
		end,
		Size = function()
			return UDim2.new(1 / #RankConfig.CATEGORIES, -6, 0, height())
		end,
		create("UICorner")({ CornerRadius = UDim.new(0, 10) }),
		create("UIStroke")({
			Color = function()
				return if selected() then R.emberLight else R.woodShadow
			end,
			Thickness = 3,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		create("ImageLabel")({
			Name = "Icon",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 4, 0.5, 0),
			Size = UDim2.fromScale(0, 0.86),
			BackgroundTransparency = 1,
			Image = RankingImages.TAB[id] or "",
			ScaleType = Enum.ScaleType.Fit,
			create("UIAspectRatioConstraint")({
				AspectRatio = 1,
				DominantAxis = Enum.DominantAxis.Height,
				AspectType = Enum.AspectType.ScaleWithParentSize,
			}),
		}),
		outlined({
			Name = "Label",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = function()
				return UDim2.new(1, -(height() * 0.86 + 12), 0.6, 0)
			end,
			Text = Strings.get("rank.tab." .. id),
			maxSize = 20,
		}),
		Activated = function()
			if not selected() then
				RankingState.select(index)
			end
		end,
	}) :: TextButton
end

function RankingScreen.build(layout: () -> MenuLayout.Layout): Frame
	-- Tamanho do corpo (px lógicos) e a conta do layout a partir dele.
	local bodySize = vide.source(Vector2.new(1000, 500))
	local scale = vide.source(1)
	local sizes = vide.derive(function()
		local size = bodySize()
		return RankingLayout.compute(size.X, size.Y, scale())
	end)
	local function rowHeight(): number
		return sizes().rowHeight
	end
	local function tabHeight(): number
		return sizes().tabHeight
	end

	-- "termina em…": relógio do servidor, atualizado de tempos em tempos.
	local now = vide.source(Workspace:GetServerTimeNow())
	task.spawn(function()
		while true do
			task.wait(TICK)
			now(Workspace:GetServerTimeNow())
		end
	end)
	local function countdown(): string
		local data = RankingState.data()
		local endsAt = if data then data.EndsAt else RankRules.weekEnd(RankRules.weekIndex(os.time()))
		local key, vars = RankRules.countdown(endsAt - now())
		return Strings.format(key, vars)
	end

	local tabs: { Instance } = {
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for index in RankConfig.CATEGORIES do
		table.insert(tabs, tab(index, tabHeight))
	end

	local podiumHolder = create("Frame")({
		Name = "PodiumHolder",
		BackgroundTransparency = 1,
		AnchorPoint = function()
			return if sizes().stacked then Vector2.new(0.5, 0) else Vector2.new(0, 0)
		end,
		Position = function()
			return if sizes().stacked then UDim2.fromScale(0.5, 0) else UDim2.fromScale(0, 0)
		end,
		Size = function()
			local s = sizes()
			if s.stacked then
				-- Empilhado: o pódio fica com até 42% da altura do corpo.
				return UDim2.new(0, s.podiumWidth, 0.42, 0)
			end
			-- Lado a lado: termina na altura do fim da lista (embaixo fica a linha
			-- "você", com a seta à esquerda dela).
			return UDim2.new(0, s.podiumWidth, 1, -RankingList.meSpace(s.rowHeight))
		end,
		create("Frame")({
			Name = "Bottom",
			BackgroundTransparency = 1,
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.fromScale(0.5, 1),
			Size = UDim2.fromScale(1, 1),
			create("UIListLayout")({
				VerticalAlignment = Enum.VerticalAlignment.Bottom,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
			}),
			RankingPodium.build(),
		}),
	})

	local listHolder = create("Frame")({
		Name = "ListHolder",
		BackgroundTransparency = 1,
		AnchorPoint = function()
			return if sizes().stacked then Vector2.new(0, 1) else Vector2.new(1, 0)
		end,
		Position = function()
			return if sizes().stacked then UDim2.fromScale(0, 1) else UDim2.fromScale(1, 0)
		end,
		Size = function()
			local s = sizes()
			if s.stacked then
				return UDim2.new(1, 0, 0.58, -s.gap)
			end
			return UDim2.new(0, s.listWidth, 1, 0)
		end,
		RankingList.build({
			rowHeight = rowHeight,
			showArrow = function()
				return not sizes().stacked
			end,
		}),
	})

	local body = create("Frame")({
		Name = "Body",
		BackgroundTransparency = 1,
		Position = function()
			return UDim2.fromOffset(INSET, HEADER + tabHeight() + 14)
		end,
		Size = function()
			return UDim2.new(1, -2 * INSET, 1, -(HEADER + tabHeight() + 14 + INSET))
		end,
		podiumHolder,
		listHolder,
	}) :: Frame

	local function measure()
		local s = uiScale(body)
		scale(s)
		bodySize(body.AbsoluteSize / s)
	end
	body:GetPropertyChangedSignal("AbsoluteSize"):Connect(measure)
	body.AncestryChanged:Connect(measure)

	-- Ao abrir a tela: pede a aba atual (o servidor guarda em cache).
	vide.effect(function()
		if MenuState.panel() == "ranking" then
			RankingState.select(vide.untrack(RankingState.category))
			task.defer(measure)
		end
	end)

	local frameArt = RankingImages.has(RankingImages.FRAME)
	return create("Frame")({
		Name = "Ranking",
		Visible = function()
			return MenuState.panel() == "ranking"
		end,
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.panelX, l.bodyTop)
		end,
		Size = function()
			local l = layout()
			return UDim2.fromOffset(l.panelWidth, l.panelBottom - l.bodyTop)
		end,
		BackgroundTransparency = if frameArt then 1 else 0,
		BackgroundColor3 = R.paper,
		Active = true,
		ZIndex = 2,
		create("ImageLabel")({
			Name = "Frame",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = RankingImages.FRAME,
			ScaleType = Enum.ScaleType.Slice,
			SliceCenter = RankingImages.FRAME_SLICE,
			SliceScale = BORDER / RankingImages.FRAME_SLICE.Min.X,
			Visible = frameArt,
			ZIndex = 0,
		}),
		create("Frame")({
			Name = "Header",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(INSET, 14),
			Size = UDim2.new(1, -2 * INSET, 0, HEADER),
			create("ImageLabel")({
				Name = "Trophy",
				AnchorPoint = Vector2.new(0, 0.5),
				Position = UDim2.fromScale(0, 0.5),
				Size = UDim2.fromOffset(TROPHY, TROPHY),
				BackgroundTransparency = 1,
				Image = RankingImages.TROPHY,
				ScaleType = Enum.ScaleType.Fit,
			}),
			outlined({
				Name = "Title",
				Position = UDim2.fromOffset(TROPHY + 8, 6),
				Size = UDim2.new(0.55, -TROPHY, 1, -12),
				FontFace = Theme.font.title,
				TextColor3 = R.emberLight,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = string.upper(Strings.get("rank.title")),
				maxSize = 34,
			}),
			Rustic.label({
				Name = "EndsIn",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -(CLOSE + 10), 0.5, 0),
				Size = UDim2.new(0.32, 0, 0, 30),
				FontFace = Theme.font.number,
				dark = true,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = countdown,
				maxSize = 20,
			}),
			Rustic.button({
				Name = "Close",
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.fromScale(1, 0.5),
				Size = UDim2.fromOffset(CLOSE, CLOSE),
				kind = "ember",
				text = "X",
				maxSize = 24,
				Activated = function()
					MenuState.open("play")
				end,
			}),
		}),
		create("Frame")({
			Name = "Tabs",
			BackgroundTransparency = 1,
			Position = UDim2.fromOffset(INSET, HEADER + 10),
			Size = function()
				return UDim2.new(1, -2 * INSET, 0, tabHeight())
			end,
			tabs,
		}),
		body,
	}) :: Frame
end

return RankingScreen
