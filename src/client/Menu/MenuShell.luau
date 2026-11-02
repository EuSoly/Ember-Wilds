--!strict
-- Casca do menu (G7a): coluna de botões à esquerda, barra no topo (nível, XP,
-- saldo real e selo MOCKUP) e a área dos painéis. Fica por cima do molde
-- MainMenu, só no estado "menu". Os painéis são placeholders com título e
-- botão de fechar; as próximas tarefas os preenchem.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local MockStore = require(Shared:WaitForChild("UIFlow"):WaitForChild("MockStore"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local ScreenState = require(Client:WaitForChild("ScreenState"))
local Template = require(Client:WaitForChild("UITemplates"):WaitForChild("Template"))
local Kit = require(Client:WaitForChild("UI"):WaitForChild("Kit"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))

local create = vide.create

-- Botões da coluna, de cima para baixo.
local NAV = { "play", "profile", "cosmetics", "shop", "tutorial", "ranking" } :: { MenuState.Panel }
-- Painéis com conteúdo próprio (o "play" é o molde MainMenu).
local PANELS = { "profile", "cosmetics", "shop", "buy", "tutorial", "ranking" } :: { MenuState.Panel }

local BAR_TOP = 0.02
local BAR_HEIGHT = 0.11
local BODY_TOP = 0.15 -- coluna e painéis começam abaixo da barra
local COLUMN_WIDTH = 0.16
local BUTTON_HEIGHT = 0.15 -- 6 botões de 0.15 + 5 vãos de 0.02 = 1

local function navButton(panel: MenuState.Panel): TextButton
	return create("TextButton")({
		Name = "Nav_" .. panel,
		Text = "",
		AutoButtonColor = true,
		Size = UDim2.fromScale(1, BUTTON_HEIGHT),
		BackgroundColor3 = function()
			return if MenuState.panel() == panel then Theme.ui.action else Theme.ui.panelRaised
		end,
		BorderSizePixel = 0,
		create("UISizeConstraint")({ MinSize = Theme.touchMinSize }),
		create("UICorner")({ CornerRadius = Theme.corner }),
		create("UIStroke")({
			Color = Theme.ui.border,
			Thickness = Theme.strokeThickness,
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		}),
		Activated = function()
			MenuState.open(panel)
		end,
		Kit.text({
			Size = UDim2.fromScale(0.9, 0.6),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Theme.font.number,
			Text = Strings.get("menu.nav." .. panel),
			maxSize = 22,
		}),
	}) :: TextButton
end

local function column(): Frame
	local children: { Instance } = {
		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0.02, 0),
		}) :: Instance,
	}
	for i = 1, #NAV do
		table.insert(children, navButton(NAV[i]))
	end
	return create("Frame")({
		Name = "Column",
		BackgroundTransparency = 1,
		Position = UDim2.fromScale(0.01, BODY_TOP),
		Size = UDim2.fromScale(COLUMN_WIDTH, 1 - BODY_TOP - BAR_TOP),
		-- Em tela baixa os botões mantêm o mínimo de toque.
		create("UISizeConstraint")({ MinSize = Vector2.new(84, 6 * 44 + 5 * 4) }),
		children,
	}) :: Frame
end

local function topBar(): Frame
	local currency = Sources.attribute(Players.LocalPlayer, StatNames.Currency, 0)
	local profile = MockStore.PROFILE

	return Kit.panel({
		Name = "TopBar",
		Position = UDim2.fromScale(0.01, BAR_TOP),
		Size = UDim2.fromScale(0.98, BAR_HEIGHT),
		create("UISizeConstraint")({ MinSize = Vector2.new(0, 44) }),
		Kit.text({
			Name = "Level",
			Position = UDim2.fromScale(0.02, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromScale(0.13, 0.7),
			FontFace = Theme.font.number,
			Text = Strings.format("menu.level", { level = profile.level }),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 24,
		}),
		-- Barra de XP (falsa): trilho escuro com o preenchimento proporcional.
		create("Frame")({
			Name = "XpBar",
			Position = UDim2.fromScale(0.16, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromScale(0.28, 0.45),
			BackgroundColor3 = Theme.ui.panelRaised,
			BorderSizePixel = 0,
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
		Kit.pill({
			Name = "MockupBadge",
			Position = UDim2.fromScale(0.47, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromScale(0.13, 0.6),
			BackgroundColor3 = Theme.ui.warning,
			text = Strings.get("menu.mockup"),
		}),
		-- Saldo real (atributo Currency); o mockup nunca o altera.
		Kit.text({
			Name = "Balance",
			Position = UDim2.fromScale(0.63, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromScale(0.27, 0.7),
			FontFace = Theme.font.number,
			Text = function()
				return Strings.format("menu.balance", { amount = currency() })
			end,
			TextXAlignment = Enum.TextXAlignment.Right,
			maxSize = 24,
		}),
		create("TextButton")({
			Name = "BuyButton",
			Text = "",
			AutoButtonColor = true,
			Position = UDim2.fromScale(0.98, 0.5),
			AnchorPoint = Vector2.new(1, 0.5),
			Size = UDim2.fromScale(0.06, 0.8),
			BackgroundColor3 = Theme.ui.action,
			BorderSizePixel = 0,
			create("UISizeConstraint")({ MinSize = Vector2.new(36, 36) }),
			create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
			Activated = function()
				MenuState.open("buy")
			end,
			Kit.text({
				Size = UDim2.fromScale(0.7, 0.7),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Theme.font.number,
				Text = "+",
				maxSize = 28,
			}),
		}),
	})
end

-- Painel placeholder: título e botão de fechar (volta a "play").
local function panelFrame(panel: MenuState.Panel): Frame
	return Kit.panel({
		Name = "Panel_" .. panel,
		Visible = function()
			return MenuState.panel() == panel
		end,
		Position = UDim2.fromScale(COLUMN_WIDTH + 0.02, BODY_TOP),
		Size = UDim2.fromScale(0.98 - COLUMN_WIDTH - 0.01, 1 - BODY_TOP - BAR_TOP),
		Kit.text({
			Name = "Title",
			Position = UDim2.fromScale(0.03, 0.03),
			Size = UDim2.fromScale(0.6, 0.1),
			FontFace = Theme.font.title,
			Text = Strings.get("menu.panel." .. panel),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 36,
		}),
		create("TextButton")({
			Name = "CloseButton",
			Text = "",
			AutoButtonColor = true,
			Position = UDim2.fromScale(0.97, 0.03),
			AnchorPoint = Vector2.new(1, 0),
			Size = UDim2.fromScale(0.15, 0.1),
			BackgroundColor3 = Theme.ui.panelRaised,
			BorderSizePixel = 0,
			create("UISizeConstraint")({ MinSize = Theme.touchMinSize }),
			create("UICorner")({ CornerRadius = Theme.corner }),
			Activated = function()
				MenuState.open("play")
			end,
			Kit.text({
				Size = UDim2.fromScale(0.8, 0.6),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				FontFace = Theme.font.number,
				Text = Strings.get("menu.close"),
				maxSize = 22,
			}),
		}),
	})
end

local MenuShell = {}

-- Monta a casca (dentro do root Vide do ScreenController); só aparece no menu.
function MenuShell.mount(playerGui: Instance): ScreenGui
	local children: { Instance } = { topBar(), column() }
	for i = 1, #PANELS do
		table.insert(children, panelFrame(PANELS[i]))
	end

	local gui = create("ScreenGui")({
		Name = "MenuShell",
		ResetOnSpawn = false,
		-- Acima do molde MainMenu, para a coluna e os painéis receberem o toque.
		DisplayOrder = 1,
		Enabled = function()
			return ScreenState.current() == "menu"
		end,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		children,
	}) :: ScreenGui
	Template.bindUiScale(gui)
	gui.Parent = playerGui
	return gui
end

return MenuShell
