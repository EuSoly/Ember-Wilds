--!strict
-- Placar da partida (estilo Starve.io): lista de jogadores ordenada por pontos
-- (LeaderboardRules.top). Fica no canto direito, abaixo dos botões do minimapa
-- (e abaixo do tutorial / receita fixada quando eles estão na coluna da direita).
-- No PC aparece sempre; no celular (tela baixa) fica atrás de um botão redondo
-- ao lado do botão das Missões, para caber em 749×330.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local LeaderboardRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("LeaderboardRules"))
local RankingImages = require(Shared:WaitForChild("RankingImages"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local CornerLayout = require(script.Parent:WaitForChild("CornerLayout"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local HudColumnState = require(script.Parent:WaitForChild("HudColumnState"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))
local ScreenMetrics = require(script.Parent:WaitForChild("ScreenMetrics"))

local create = vide.create
local R = Theme.rustic

local PANEL_WIDTH = 210
local TITLE_HEIGHT = 22
local ROW_HEIGHT = 18
local GAP = 4
local REBUILD_EVERY = 0.5 -- segundos: no máximo 2 atualizações da lista por segundo

local function formatScore(n: number): string
	local s = tostring(math.floor(math.max(n, 0)))
	local out = string.gsub(string.reverse(s), "(%d%d%d)", "%1.")
	out = string.reverse(out)
	if string.sub(out, 1, 1) == "." then
		out = string.sub(out, 2)
	end
	return out
end

local function RowView(row: () -> LeaderboardRules.Row, index: number): Frame
	local color = function(): Color3
		return if row().isMe then R.emberLight else R.cream
	end
	return create("Frame")({
		Name = `Row{index}`,
		LayoutOrder = index,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundTransparency = 1,
		Rustic.label({
			Name = "Rank",
			Size = UDim2.fromOffset(30, ROW_HEIGHT),
			FontFace = Theme.font.number,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = color,
			Text = function()
				return `#{row().rank}`
			end,
			maxSize = 14,
		}),
		Rustic.label({
			Name = "Name",
			Position = UDim2.fromOffset(32, 0),
			Size = UDim2.new(1, -92, 0, ROW_HEIGHT),
			FontFace = Theme.font.label,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = color,
			Text = function()
				return row().name
			end,
			maxSize = 14,
		}),
		Rustic.label({
			Name = "Score",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromOffset(58, ROW_HEIGHT),
			FontFace = Theme.font.number,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = color,
			Text = function()
				return formatScore(row().score)
			end,
			maxSize = 14,
		}),
	}) :: Frame
end

local function Leaderboard(): Frame
	local rows = vide.source({} :: { LeaderboardRules.Row })
	local mobileOpen = vide.source(false)
	local me = Players.LocalPlayer
	local myId = if me then me.UserId else 0

	local playerConns: { [Player]: RBXScriptConnection } = {}

	local function rebuild()
		local entries: { LeaderboardRules.InputEntry } = {}
		for _, p in Players:GetPlayers() do
			local raw = p:GetAttribute(StatNames.Score)
			local score = if type(raw) == "number" and raw == raw and raw > 0 then math.floor(raw) else 0
			table.insert(entries, {
				name = p.DisplayName,
				score = score,
				userId = p.UserId,
			})
		end
		rows(LeaderboardRules.top(entries, LeaderboardRules.LIMIT, myId))
	end

	-- Os pontos mudam a cada golpe de coleta de qualquer jogador: junta as
	-- mudanças e refaz a lista no máximo a cada REBUILD_EVERY.
	local pending = false
	local function scheduleRebuild()
		if pending then
			return
		end
		pending = true
		task.delay(REBUILD_EVERY, function()
			pending = false
			rebuild()
		end)
	end

	local function watchPlayer(p: Player)
		if playerConns[p] then
			playerConns[p]:Disconnect()
		end
		playerConns[p] = p:GetAttributeChangedSignal(StatNames.Score):Connect(scheduleRebuild)
	end

	for _, p in Players:GetPlayers() do
		watchPlayer(p)
	end
	vide.cleanup(Players.PlayerAdded:Connect(function(p)
		watchPlayer(p)
		rebuild()
	end))
	vide.cleanup(Players.PlayerRemoving:Connect(function(p)
		local conn = playerConns[p]
		if conn then
			conn:Disconnect()
			playerConns[p] = nil
		end
		task.defer(rebuild)
	end))
	vide.cleanup(function()
		for _, conn in playerConns do
			conn:Disconnect()
		end
		table.clear(playerConns)
	end)
	rebuild()

	local button = HudArt.roundButton({
		Name = "LeaderboardButton",
		icon = RankingImages.TROPHY,
		fallback = "#",
		Visible = ScreenMetrics.short,
		AnchorPoint = Vector2.new(1, 0),
		Position = function()
			return CornerLayout.secondRowLeftPosition()
		end,
		Size = CornerLayout.buttonSize,
		SizeConstraint = Enum.SizeConstraint.RelativeXY,
		minSize = Theme.touchMinSize,
		maxSize = Vector2.new(68, 68),
		Activated = function()
			mobileOpen(not vide.untrack(mobileOpen))
		end,
	})

	local pad = Kit.panelPadding(10)
	local panel = Kit.panel({
		Name = "LeaderboardPanel",
		Active = true,
		AnchorPoint = Vector2.new(1, 0),
		Visible = function()
			if #rows() == 0 then
				return false
			end
			if ScreenMetrics.short() then
				return mobileOpen()
			end
			return not HudColumnState.yieldsToPanel()
		end,
		Position = function()
			local layout = CornerLayout.get()
			local gap = math.max(math.round(layout.buttonSize * 0.15), 4)
			local belowButtons = layout.buttonTop + 2 * layout.buttonSize + gap + 10
			if ScreenMetrics.short() then
				return UDim2.new(1, -layout.margin, 0, belowButtons)
			end
			local height = ScreenMetrics.guiHeight()
			local col = HudColumnState.column()
			local topPx = belowButtons
			local th = HudColumnState.tutorialHeight()
			local ph = HudColumnState.pinnedHeight()
			if ph > 0 then
				topPx = math.max(topPx, math.round((col.pinnedY + ph + 0.01) * height))
			elseif th > 0 then
				topPx = math.max(topPx, math.round((col.tutorialY + th + 0.01) * height))
			end
			return UDim2.new(1, -layout.margin, 0, topPx)
		end,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.fromOffset(PANEL_WIDTH, 0),
		create("UIPadding")({
			PaddingTop = UDim.new(0, pad),
			PaddingBottom = UDim.new(0, pad),
			PaddingLeft = UDim.new(0, pad),
			PaddingRight = UDim.new(0, pad),
		}),
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			Padding = UDim.new(0, GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Kit.text({
			Name = "Title",
			LayoutOrder = 0,
			Size = UDim2.new(1, 0, 0, TITLE_HEIGHT),
			FontFace = Theme.font.number,
			Text = Strings.get("hud.players"),
			maxSize = 16,
		}),
		create("Frame")({
			Name = "Rows",
			LayoutOrder = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromScale(1, 0),
			BackgroundTransparency = 1,
			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, 2),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			vide.indexes(rows, RowView),
		}),
	})

	return create("Frame")({
		Name = "Leaderboard",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		{ button :: Instance, panel :: Instance },
	}) :: Frame
end

return Leaderboard
