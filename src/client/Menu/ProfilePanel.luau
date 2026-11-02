--!strict
-- Conteúdo do painel Perfil (mockup G7a): nome do jogador (só leitura), nível,
-- barra de XP e as quatro estatísticas falsas do MockStore.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Kit = require(Client:WaitForChild("UI"):WaitForChild("Kit"))

local create = vide.create

local function statCard(stat: MockStore.Stat): Frame
	return create("Frame")({
		Name = "Stat",
		BackgroundColor3 = Theme.ui.panelRaised,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = Theme.corner }),
		Kit.text({
			Position = UDim2.fromScale(0.5, 0.3),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0.3),
			FontFace = Theme.font.body,
			Text = Strings.get(stat.nameKey),
			maxSize = 18,
		}),
		Kit.text({
			Position = UDim2.fromScale(0.5, 0.7),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Size = UDim2.fromScale(0.9, 0.4),
			FontFace = Theme.font.number,
			Text = tostring(stat.value),
			maxSize = 28,
		}),
	}) :: Frame
end

local ProfilePanel = {}

function ProfilePanel.build(): Frame
	local profile = MockStore.PROFILE
	local stats: { Instance } = {
		create("UIGridLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			CellSize = UDim2.fromScale(0.485, 0.47),
			CellPadding = UDim2.fromScale(0.03, 0.06),
		}) :: Instance,
	}
	for _, stat in profile.stats do
		table.insert(stats, statCard(stat))
	end
	return create("Frame")({
		Name = "Profile",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.02, 0.15),
		Size = UDim2.fromScale(0.96, 0.82),
		Kit.text({
			Name = "PlayerName",
			Size = UDim2.fromScale(0.6, 0.12),
			FontFace = Theme.font.title,
			Text = Players.LocalPlayer.DisplayName,
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 30,
		}),
		Kit.text({
			Name = "Level",
			Position = UDim2.fromScale(1, 0),
			AnchorPoint = Vector2.new(1, 0),
			Size = UDim2.fromScale(0.3, 0.12),
			FontFace = Theme.font.number,
			Text = Strings.format("menu.level", { level = profile.level }),
			TextXAlignment = Enum.TextXAlignment.Right,
			maxSize = 26,
		}),
		create("Frame")({
			Name = "XpBar",
			Position = UDim2.fromScale(0, 0.15),
			Size = UDim2.fromScale(1, 0.1),
			BackgroundColor3 = Theme.ui.panelRaised,
			BorderSizePixel = 0,
			create("UISizeConstraint")({ MinSize = Vector2.new(0, 20) }),
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			create("Frame")({
				Name = "Fill",
				Size = UDim2.fromScale(math.clamp(profile.xp / profile.xpMax, 0, 1), 1),
				BackgroundColor3 = Theme.ui.success,
				BorderSizePixel = 0,
				create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			}),
			Kit.text({
				Size = UDim2.fromScale(0.9, 0.8),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Theme.font.body,
				Text = Strings.format("menu.xp", { xp = profile.xp, max = profile.xpMax }),
				maxSize = 16,
			}),
		}),
		create("Frame")({
			Name = "Stats",
			Position = UDim2.fromScale(0, 0.3),
			Size = UDim2.fromScale(1, 0.7),
			BackgroundTransparency = 1,
			stats,
		}),
	}) :: Frame
end

return ProfilePanel
