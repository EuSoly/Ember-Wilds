--!strict
-- Placar da partida (estilo Starve.io), no lugar do antigo selo de pontos
-- (pedido do Elizeu, 19/11):
-- - canto de cima à esquerda: uma placa de madeira só com a linha do jogador
--   ("#3 Nome 1.240", LeaderboardRules.mine), do tamanho do selo antigo. A
--   altura vem do HudColumn.pillBottom, a mesma conta que a coluna de receitas
--   e o boost de XP usam para começar abaixo;
-- - clicar/tocar na placa abre a lista completa (até LeaderboardRules.LIMIT)
--   numa janela no meio da tela (sem escurecer o fundo); clicar fora fecha.
-- Pontos = atributo Score de cada Player. A lista é refeita no máximo a cada
-- REBUILD_EVERY (os pontos mudam a cada golpe de coleta de qualquer um).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local HudColumn = require(Shared:WaitForChild("UIFlow"):WaitForChild("HudColumn"))
local LeaderboardRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("LeaderboardRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))
local ScreenMetrics = require(script.Parent:WaitForChild("ScreenMetrics"))

local create = vide.create
local R = Theme.rustic

local REBUILD_EVERY = 0.5 -- segundos: no máximo 2 atualizações da lista por segundo
-- Janela da lista completa.
local WINDOW_WIDTH = 360
local WINDOW_MAX_SHARE = 0.8 -- da altura da tela
local TITLE_HEIGHT = 28
local ROW_HEIGHT = 24
local ROW_GAP = 2
-- Ouro, prata e bronze no número do pódio.
local MEDAL = {
	Color3.fromHex("#FFD24A"),
	Color3.fromHex("#E2E6EA"),
	Color3.fromHex("#E39B5B"),
}

local function formatScore(n: number): string
	local s = tostring(math.floor(math.max(n, 0)))
	local out = string.gsub(string.reverse(s), "(%d%d%d)", "%1.")
	out = string.reverse(out)
	if string.sub(out, 1, 1) == "." then
		out = string.sub(out, 2)
	end
	return out
end

-- Uma linha "#1  Nome  1.240". `size` = tamanho da linha; `maxText` = teto
-- da fonte. O jogador local fica na cor de brasa.
local function RowView(row: () -> LeaderboardRules.Row, index: number, size: UDim2, maxText: number): Frame
	local nameColor = function(): Color3
		return if row().isMe then R.emberLight else R.cream
	end
	local rankColor = function(): Color3
		return MEDAL[row().rank] or nameColor()
	end
	return create("Frame")({
		Name = `Row{index}`,
		LayoutOrder = index,
		Size = size,
		BackgroundTransparency = 1,
		Rustic.label({
			Name = "Rank",
			Size = UDim2.fromScale(0.2, 1),
			FontFace = Theme.font.number,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = rankColor,
			Text = function()
				return `#{row().rank}`
			end,
			maxSize = maxText,
		}),
		Rustic.label({
			Name = "Name",
			Position = UDim2.fromScale(0.2, 0),
			Size = UDim2.fromScale(0.52, 1),
			FontFace = Theme.font.label,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			TextColor3 = nameColor,
			Text = function()
				return row().name
			end,
			maxSize = maxText,
		}),
		Rustic.label({
			Name = "Score",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.fromScale(0.28, 1),
			FontFace = Theme.font.number,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextColor3 = nameColor,
			Text = function()
				return formatScore(row().score)
			end,
			maxSize = maxText,
		}),
	}) :: Frame
end

local function Leaderboard(): Frame
	local all = vide.source({} :: { LeaderboardRules.Row })
	local mine = vide.source({} :: { LeaderboardRules.Row }) -- 0 ou 1 linha
	local open = vide.source(false)
	local me = Players.LocalPlayer
	local myId = if me then me.UserId else 0

	local function rebuild()
		local entries: { LeaderboardRules.InputEntry } = {}
		for _, p in Players:GetPlayers() do
			local raw = p:GetAttribute(StatNames.Score)
			local score = if type(raw) == "number" and raw == raw and raw > 0 then math.floor(raw) else 0
			table.insert(entries, { name = p.DisplayName, score = score, userId = p.UserId })
		end
		all(LeaderboardRules.top(entries, LeaderboardRules.LIMIT, myId))
		local row = LeaderboardRules.mine(entries, myId)
		mine(if row then { row } else {})
	end

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

	local playerConns: { [Player]: RBXScriptConnection } = {}
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
		scheduleRebuild()
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

	-- Placa do canto (a linha do jogador). Altura em px da conta compartilhada.
	local plate = Rustic.plate({
		Name = "MyRank",
		Active = true,
		Position = UDim2.fromScale(HudColumn.PILL_LEFT, HudColumn.PILL_TOP),
		Size = function()
			local h = ScreenMetrics.guiHeight()
			return UDim2.new(HudColumn.PILL_WIDTH, 0, 0, HudColumn.pillBottom(h) - HudColumn.PILL_TOP * h)
		end,
		create("UISizeConstraint")({ MinSize = Vector2.new(150, 0) }),
		-- Margem só nas linhas (um UIPadding na placa encolheria a própria arte
		-- da madeira): o texto não encosta na borda nem nos pregos dos cantos.
		create("Frame")({
			Name = "Rows",
			Position = UDim2.fromScale(0.1, 0.18),
			Size = UDim2.fromScale(0.8, 0.64),
			BackgroundTransparency = 1,
			ZIndex = 2,
			vide.indexes(mine, function(row, index)
				return RowView(row, index, UDim2.fromScale(1, 1), 22)
			end),
		}),
		-- A placa inteira é o botão que abre a lista completa.
		create("TextButton")({
			Name = "Open",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			ZIndex = 5,
			Activated = function()
				open(true)
			end,
		}),
	})

	local pad = Kit.panelPadding(12)
	local window = Kit.panel({
		Name = "Window",
		Active = true, -- clique dentro da janela não chega ao fundo (não fecha)
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = function()
			local rows = #all()
			local content = TITLE_HEIGHT + 6 + rows * (ROW_HEIGHT + ROW_GAP)
			local maxHeight = WINDOW_MAX_SHARE * ScreenMetrics.guiHeight()
			return UDim2.fromOffset(WINDOW_WIDTH, math.min(content + 2 * pad, maxHeight))
		end,
		ZIndex = 2,
		create("UIPadding")({
			PaddingTop = UDim.new(0, pad),
			PaddingBottom = UDim.new(0, pad),
			PaddingLeft = UDim.new(0, pad),
			PaddingRight = UDim.new(0, pad),
		}),
		Kit.text({
			Name = "Title",
			Size = UDim2.new(1, 0, 0, TITLE_HEIGHT),
			FontFace = Theme.font.number,
			Text = Strings.get("hud.players"),
			maxSize = 22,
		}),
		create("ScrollingFrame")({
			Name = "List",
			Position = UDim2.fromOffset(0, TITLE_HEIGHT + 6),
			Size = UDim2.new(1, 0, 1, -(TITLE_HEIGHT + 6)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			ScrollBarThickness = 4,
			ScrollBarImageColor3 = R.cream,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Vertical,
				Padding = UDim.new(0, ROW_GAP),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			vide.indexes(all, function(row, index)
				return RowView(row, index, UDim2.new(1, -8, 0, ROW_HEIGHT), 18)
			end),
		}),
	})

	-- Fundo invisível da tela inteira (sem escurecer, pedido do Elizeu):
	-- tocar fora da janela fecha.
	local overlay = create("TextButton")({
		Name = "LeaderboardOverlay",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Visible = open,
		Activated = function()
			open(false)
		end,
		window,
	})

	-- Por cima do resto do HUD (a janela precisa cobrir a coluna da direita).
	return create("Frame")({
		Name = "Leaderboard",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		ZIndex = 10,
		{ plate :: Instance, overlay :: Instance },
	}) :: Frame
end

return Leaderboard
