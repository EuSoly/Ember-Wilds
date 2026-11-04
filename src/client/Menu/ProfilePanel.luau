--!strict
-- Perfil (UI 4): janela rústica no centro do menu, no visual das
-- Configurações, mas sem escurecer o menu atrás. Abre pelo botão Perfil da
-- coluna (painel "profile" do MenuState); Fechar volta ao "play".
--
-- Tudo real, lido dos atributos que o servidor publica (Stat_<id>, StatsService):
--   topo: nome, NÍVEL N, barra de XP do nível (LevelRules) e o XP total;
--   cartões: Mortes (só de verdade), Dias sobrevividos, Recorde de dias;
--   Outros: jogadores e criaturas mortas, recursos coletados, itens criados,
--   recorde de pontos numa vida e tempo de jogo.
-- No celular o conteúdo rola e o Fechar fica sempre à vista.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local LevelRules = require(Shared:WaitForChild("Data"):WaitForChild("LevelRules"))
local ProfileFormat = require(Shared:WaitForChild("UIFlow"):WaitForChild("ProfileFormat"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))

local create = vide.create
local R = Theme.rustic

local WINDOW_MAX = Vector2.new(560, 600)
local TITLE_HEIGHT = 58
local CLOSE_HEIGHT = 50
local HEADER_HEIGHT = 92
local CARD_HEIGHT = 84
local ROW_HEIGHT = 40
local GROUP_HEIGHT = 30

local BODY = Color3.fromHex("#2B2018")
local ROW = Color3.fromHex("#3A2B20")
local TRACK = Color3.fromHex("#1A130D")

-- Os três cartões grandes e a lista "Outros", na ordem do design.
local CARDS = { "real_deaths", "days_total", "days_best" }
local OTHERS =
	{ "players_killed", "mobs_killed", "resources_gathered", "items_crafted", "score_best", "playtime_seconds" }

local ProfilePanel = {}

local function stat(id: string): () -> number
	local value = Sources.attribute(Players.LocalPlayer, StatNames.StatPrefix .. id, 0)
	return function()
		local v = value()
		return if type(v) == "number" then v else 0
	end
end

local function statText(id: string): () -> string
	local value = stat(id)
	return function()
		return if id == "playtime_seconds" then ProfileFormat.playtime(value()) else ProfileFormat.thousands(value())
	end
end

local function outlined(props: { [any]: any }): TextLabel
	table.insert(props, create("UIStroke")({ Color = R.outline, Thickness = 2 }))
	return Rustic.label(props)
end

local function header(order: number): Frame
	local xp = stat("xp_total")
	local function progress(): LevelRules.Progress
		return LevelRules.progress(xp())
	end
	return create("Frame")({
		Name = "Header",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		BackgroundTransparency = 1,
		outlined({
			Name = "PlayerName",
			Size = UDim2.new(0.62, 0, 0, 30),
			FontFace = Theme.font.title,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = Players.LocalPlayer.DisplayName,
			maxSize = 28,
		}),
		outlined({
			Name = "Level",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = UDim2.new(0.36, 0, 0, 30),
			FontFace = Theme.font.title,
			TextColor3 = R.emberLight,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = function()
				return string.upper(Strings.format("menu.level", { level = progress().level }))
			end,
			maxSize = 26,
		}),
		create("Frame")({
			Name = "XpBar",
			Position = UDim2.fromOffset(0, 38),
			Size = UDim2.new(1, 0, 0, 22),
			BackgroundColor3 = TRACK,
			BorderSizePixel = 0,
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			create("UIStroke")({ Color = R.outline, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
			create("Frame")({
				Name = "Fill",
				Size = function()
					local p = progress()
					return UDim2.fromScale(math.clamp(p.into / p.need, 0, 1), 1)
				end,
				BackgroundColor3 = R.success,
				BorderSizePixel = 0,
				create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			}),
			outlined({
				Name = "XpText",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.9, 0.8),
				FontFace = Theme.font.number,
				ZIndex = 2,
				Text = function()
					local p = progress()
					return Strings.format(
						"menu.xp",
						{ xp = ProfileFormat.thousands(p.into), max = ProfileFormat.thousands(p.need) }
					)
				end,
				maxSize = 16,
			}),
		}),
		Rustic.label({
			Name = "TotalXp",
			Position = UDim2.fromOffset(0, 66),
			Size = UDim2.new(1, 0, 0, 22),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = R.cream,
			Text = function()
				return Strings.format("profile.total_xp", { xp = ProfileFormat.thousands(xp()) })
			end,
			maxSize = 18,
		}),
	}) :: Frame
end

local function card(id: string, order: number): Frame
	return create("Frame")({
		Name = id,
		LayoutOrder = order,
		Size = UDim2.new(1 / #CARDS, -6, 1, 0),
		BackgroundColor3 = ROW,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		create("UIStroke")({ Color = R.woodShadow, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		Rustic.label({
			Name = "NameLabel",
			AnchorPoint = Vector2.new(0.5, 0),
			Position = UDim2.new(0.5, 0, 0, 8),
			Size = UDim2.new(0.9, 0, 0, 22),
			Text = Strings.get(`stat.{id}`),
			maxSize = 16,
		}),
		outlined({
			Name = "ValueLabel",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -8),
			Size = UDim2.new(0.9, 0, 0, 36),
			FontFace = Theme.font.number,
			TextColor3 = R.emberLight,
			Text = statText(id),
			maxSize = 32,
		}),
	}) :: Frame
end

local function cards(order: number): Frame
	local children: { Instance } = {
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, 8),
		}),
	}
	for i, id in CARDS do
		table.insert(children, card(id, i))
	end
	return create("Frame")({
		Name = "Cards",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, CARD_HEIGHT),
		BackgroundTransparency = 1,
		children,
	}) :: Frame
end

local function row(id: string, order: number): Frame
	return create("Frame")({
		Name = id,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, ROW_HEIGHT),
		BackgroundColor3 = ROW,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
		create("UIPadding")({ PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14) }),
		Rustic.label({
			Name = "NameLabel",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.new(0.66, 0, 0, 22),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = Strings.get(`stat.{id}`),
			maxSize = 18,
		}),
		Rustic.label({
			Name = "ValueLabel",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.new(0.32, 0, 0, 24),
			FontFace = Theme.font.number,
			TextColor3 = R.emberLight,
			TextXAlignment = Enum.TextXAlignment.Right,
			Text = statText(id),
			maxSize = 20,
		}),
	}) :: Frame
end

local function content(): { Instance }
	local list: { Instance } = {
		header(1),
		cards(2),
		outlined({
			Name = "Others",
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, GROUP_HEIGHT),
			FontFace = Theme.font.title,
			TextColor3 = R.emberLight,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = string.upper(Strings.get("profile.others")),
			maxSize = 22,
		}),
	}
	for i, id in OTHERS do
		table.insert(list, row(id, 3 + i))
	end
	return list
end

-- A janela do Perfil (filha do MenuShell; aparece com o painel "profile").
function ProfilePanel.build(): Frame
	return create("Frame")({
		Name = "Profile",
		Visible = function()
			return MenuState.panel() == "profile"
		end,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, TITLE_HEIGHT / 4),
		Size = UDim2.new(0.92, 0, 0.86, -TITLE_HEIGHT / 2),
		BackgroundColor3 = BODY,
		BorderSizePixel = 0,
		Active = true,
		ZIndex = 8, -- acima das placas do topo (o saldo usa 6)
		create("UISizeConstraint")({ MaxSize = WINDOW_MAX }),
		create("UICorner")({ CornerRadius = UDim.new(0, 12) }),
		create("UIStroke")({
			Color = R.woodShadow,
			Thickness = 4,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Rustic.plate({
			Name = "TitlePlate",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.new(0.5, 0, 0, TITLE_HEIGHT),
			ZIndex = 3,
			outlined({
				Name = "Title",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.86, 0.6),
				FontFace = Theme.font.title,
				Text = string.upper(Strings.get("profile.title")),
				maxSize = 32,
				ZIndex = 4,
			}),
		}),
		create("ScrollingFrame")({
			Name = "List",
			Position = UDim2.fromOffset(16, TITLE_HEIGHT / 2 + 12),
			Size = UDim2.new(1, -32, 1, -(TITLE_HEIGHT / 2 + 12 + CLOSE_HEIGHT + 28)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.new(),
			ScrollBarThickness = 6,
			ScrollBarImageColor3 = R.woodLight,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			create("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				Padding = UDim.new(0, 8),
			}),
			create("UIPadding")({ PaddingRight = UDim.new(0, 8) }),
			content(),
		}),
		Rustic.button({
			Name = "CloseButton",
			AnchorPoint = Vector2.new(0.5, 1),
			Position = UDim2.new(0.5, 0, 1, -14),
			Size = UDim2.fromOffset(200, CLOSE_HEIGHT),
			kind = "ember",
			text = Strings.get("menu.close"),
			maxSize = 24,
			Activated = function()
				MenuState.open("play")
			end,
		}),
	}) :: Frame
end

return ProfilePanel
