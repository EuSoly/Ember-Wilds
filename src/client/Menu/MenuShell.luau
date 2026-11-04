--!strict
-- Menu (UI 1, design system rústico). Tudo do menu mora aqui:
--   topo: placa de nível + XP (reais: ProfileStats.xp_total), logo, saldo real + "+";
--   coluna à esquerda: Perfil, Cosméticos, Loja, Ranking e Configurações;
--   centro: o boneco do jogador segurando o livro (MenuBoneco), com os botões
--   Kits e JOGAR embaixo; o painel de kits abre à direita (KitsPanel);
--   Perfil e Cosméticos abrem como janelas no centro; o Ranking (mockup)
--   abre à direita da coluna.
-- Só aparece no estado "menu" (a janela de Configurações abre por cima). As posições vêm do
-- MenuLayout (pixels lógicos, testados do celular ao PC) e são recalculadas
-- quando o tamanho da tela ou o tamanho da interface muda.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local MenuLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("MenuLayout"))
local ShopLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("ShopLayout"))
local LevelRules = require(Shared:WaitForChild("Data"):WaitForChild("LevelRules"))
local ProfileFormat = require(Shared:WaitForChild("UIFlow"):WaitForChild("ProfileFormat"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local UiImages = require(Shared:WaitForChild("UiImages"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local ScreenState = require(Client:WaitForChild("ScreenState"))
local Template = require(Client:WaitForChild("UITemplates"):WaitForChild("Template"))
local SettingsScreen = require(Client:WaitForChild("Screens"):WaitForChild("SettingsScreen"))
local KitList = require(Client:WaitForChild("Screens"):WaitForChild("KitList"))
local Kit = require(Client:WaitForChild("UI"):WaitForChild("Kit"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local MenuState = require(script.Parent:WaitForChild("MenuState"))
local KitShop = require(script.Parent:WaitForChild("KitShop"))
local KitsPanel = require(script.Parent:WaitForChild("KitsPanel"))
local ShopFolder = script.Parent:WaitForChild("Shop")
local ShopScreen = require(ShopFolder:WaitForChild("ShopScreen"))
local Featured = require(ShopFolder:WaitForChild("Featured"))
local Passes = require(ShopFolder:WaitForChild("Passes"))
local EmberPacks = require(ShopFolder:WaitForChild("EmberPacks"))
local SpinTypes = require(ShopFolder:WaitForChild("SpinTypes"))
local SpinScreen = require(ShopFolder:WaitForChild("SpinScreen"))
local SpinFx = require(ShopFolder:WaitForChild("SpinFx"))
local SpinSounds = require(ShopFolder:WaitForChild("SpinSounds"))
local ShopState = require(ShopFolder:WaitForChild("ShopState"))
local MenuBoneco = require(script.Parent:WaitForChild("MenuBoneco"))
local RankingPanel = require(script.Parent:WaitForChild("RankingPanel"))
local ProfilePanel = require(script.Parent:WaitForChild("ProfilePanel"))
local CosmeticsScreen = require(script.Parent:WaitForChild("Cosmetics"):WaitForChild("CosmeticsScreen"))

local create = vide.create
local R = Theme.rustic

-- Botões da coluna, de cima para baixo (ids de MenuState.Panel). "settings"
-- não é painel: abre a janela de Configurações de sempre.
local NAV: { string } = { "profile", "cosmetics", "shop", "ranking", "settings" }
-- Painéis do mockup com conteúdo próprio (abrem à direita da coluna).
local PANELS = { "ranking" } :: { MenuState.Panel }

local MARGIN = MenuLayout.MARGIN
local TITLE_ROW = MenuLayout.TITLE_ROW
local TOUCH = Theme.touchMinSize.Y
local SHADOW_SHARE = Vector2.new(0.7, 0.12) -- sombra no chão, fração do lado do boneco

type Layout = MenuLayout.Layout

local function podWidth(l: Layout): number
	return l.podWidth
end

-- 1321 → "1.321" (separador de milhar do pt-BR).
local function thousands(value: number): string
	local digits = tostring(math.floor(math.max(value, 0)))
	local out = digits:reverse():gsub("(%d%d%d)", "%1."):reverse()
	return (out:gsub("^%.", ""))
end

-- Galho atrás do card da Golden Ember: maior que o card, encostado na borda
-- direita, com o tronco do galho passando logo abaixo do card.
local BRANCH_ASPECT = 584 / 222 -- proporção do PNG do galho
local BRANCH_SHARE = 1.45 -- largura do galho em relação ao card
local BRANCH_LIFT = 0.22 -- quanto do galho fica acima do topo do card
local COIN_SIZE = 40

-- "Nenhum", "Explorador" ou "Iniciante (simulado)" (kit que não vai ao servidor).
local function kitLabel(): string
	local id, source = KitShop.current()
	if id == nil then
		return Strings.get("menu.kits.none")
	end
	local kit = Defs.Kits[id]
	local name = if kit then Strings.get(kit.nameKey) else id
	if source ~= "points" then
		return Strings.format("menu.kits.simulated", { name = name })
	end
	return name
end

local function navButton(id: string, layout: () -> Layout): TextButton
	return Rustic.button({
		Name = "Nav_" .. id,
		Size = function()
			return UDim2.new(1, -6, 0, layout().buttonHeight)
		end,
		kind = function()
			return if MenuState.panel() == id then "ember" else "wood"
		end,
		text = Strings.get("menu.nav." .. id),
		maxSize = 20,
		Activated = function()
			if id == "settings" then
				SettingsScreen.open(true)
			else
				MenuState.open((id :: any) :: MenuState.Panel)
			end
		end,
	})
end

-- Coluna rolável: se a tela for baixa demais para os 6 botões, ela rola.
local function column(layout: () -> Layout): ScrollingFrame
	local children: { Instance } = {
		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			Padding = UDim.new(0, MenuLayout.BUTTON_GAP),
		}) :: Instance,
		create("UIPadding")({ PaddingTop = UDim.new(0, 2), PaddingLeft = UDim.new(0, 2) }) :: Instance,
	}
	for i, id in NAV do
		local button = navButton(id, layout)
		button.LayoutOrder = i
		table.insert(children, button)
	end
	return create("ScrollingFrame")({
		Name = "Column",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.columnX, l.bodyTop)
		end,
		Size = function()
			local l = layout()
			return UDim2.fromOffset(l.columnWidth, l.columnBottom - l.bodyTop)
		end,
		CanvasSize = UDim2.fromScale(0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ScrollBarThickness = 4,
		ScrollBarImageColor3 = R.woodEdge,
		children,
	}) :: ScrollingFrame
end

local function levelPod(layout: () -> Layout): Frame
	local xp = Sources.childAttribute(Players.LocalPlayer, StatNames.StatsFolder, "xp_total", 0)
	local function progress(): LevelRules.Progress
		local value = xp()
		return LevelRules.progress(if type(value) == "number" then value else 0)
	end
	return Rustic.plate({
		Name = "TopLeft",
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.columnX, l.podTop)
		end,
		Size = function()
			local l = layout()
			return UDim2.fromOffset(podWidth(l), MenuLayout.POD_HEIGHT)
		end,
		-- Rosto do avatar do Roblox do jogador, numa moldura de madeira.
		create("Frame")({
			Name = "Avatar",
			Position = UDim2.fromOffset(6, 6),
			Size = UDim2.fromOffset(44, 44),
			BackgroundColor3 = R.walnut,
			BorderSizePixel = 0,
			create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
			create("UIStroke")({ Color = R.outline, Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
			create("ImageLabel")({
				Name = "Headshot",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				-- Miniatura pronta do Roblox: carrega sozinha, sem pedir nada antes.
				Image = `rbxthumb://type=AvatarHeadShot&id={Players.LocalPlayer.UserId}&w=150&h=150`,
				create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
			}),
		}),
		Rustic.label({
			Name = "PlayerName",
			Position = UDim2.fromOffset(58, 5),
			Size = UDim2.new(0.58, -58, 0, 20),
			FontFace = Theme.font.number,
			Text = Players.LocalPlayer.DisplayName,
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 17,
			create("UIStroke")({ Color = R.outline, Thickness = 1.5 }),
		}),
		Rustic.label({
			Name = "LevelText",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -10, 0, 5),
			Size = UDim2.new(0.42, -10, 0, 20),
			FontFace = Theme.font.number,
			TextColor3 = R.emberLight,
			Text = function()
				return Strings.format("menu.level", { level = progress().level })
			end,
			TextXAlignment = Enum.TextXAlignment.Right,
			maxSize = 17,
			create("UIStroke")({ Color = R.outline, Thickness = 1.5 }),
		}),
		-- Barra de XP do nível atual.
		Rustic.bar({
			Name = "XpBar",
			Position = UDim2.fromOffset(58, 30),
			Size = UDim2.new(1, -68, 0, 18),
			fraction = function()
				local p = progress()
				return p.into / p.need
			end,
			text = function()
				local p = progress()
				return Strings.format(
					"menu.xp",
					{ xp = ProfileFormat.thousands(p.into), max = ProfileFormat.thousands(p.need) }
				)
			end,
			maxSize = 12,
		}),
	})
end

local function balancePod(layout: () -> Layout): Frame
	local currency = Sources.attribute(Players.LocalPlayer, StatNames.Currency, 0)
	return Rustic.plate({
		Name = "TopRight",
		AnchorPoint = Vector2.new(1, 0),
		Position = function()
			local l = layout()
			return UDim2.new(1, -MARGIN, 0, l.podTop)
		end,
		Size = function()
			return UDim2.fromOffset(podWidth(layout()), MenuLayout.POD_HEIGHT)
		end,
		create("ImageLabel")({
			Name = "Coin",
			Visible = UiImages.has(UiImages.COIN),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, -1),
			Size = UDim2.fromOffset(COIN_SIZE, COIN_SIZE),
			BackgroundTransparency = 1,
			Image = UiImages.COIN,
			ScaleType = Enum.ScaleType.Fit,
		}),
		-- Saldo real (atributo Currency); o mockup nunca o altera.
		Rustic.label({
			Name = "Balance",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14 + COIN_SIZE + 8, 0.5, 0),
			Size = UDim2.new(1, -(TOUCH + 34 + COIN_SIZE), 0.6, 0),
			FontFace = Theme.font.number,
			Text = function()
				return thousands(currency())
			end,
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 26,
			create("UIStroke")({ Color = Theme.rustic.outline, Thickness = 1.5 }),
		}),
		Rustic.button({
			Name = "BuyButton",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -10, 0.5, 0),
			Size = UDim2.fromOffset(TOUCH, TOUCH),
			kind = "ember",
			text = "+",
			maxSize = 26,
			Activated = function()
				MenuState.openShop("ember")
			end,
		}),
	})
end

-- Galho atrás do card do saldo (vem antes dele na lista: fica por baixo).
local function branch(layout: () -> Layout): ImageLabel
	return create("ImageLabel")({
		Name = "Branch",
		Visible = UiImages.has(UiImages.BRANCH),
		AnchorPoint = Vector2.new(1, 0),
		Position = function()
			local l = layout()
			local height = l.podWidth * BRANCH_SHARE / BRANCH_ASPECT
			return UDim2.new(1, 0, 0, l.podTop - height * BRANCH_LIFT)
		end,
		Size = function()
			local width = layout().podWidth * BRANCH_SHARE
			return UDim2.fromOffset(width, width / BRANCH_ASPECT)
		end,
		BackgroundTransparency = 1,
		Image = UiImages.BRANCH,
		ScaleType = Enum.ScaleType.Fit,
	}) :: ImageLabel
end

-- Logo maior no menu; com um painel do mockup aberto, encolhe para não cobrir o título.
local PANEL_LOGO_HEIGHT = 56
local function logo(layout: () -> Layout): ImageLabel
	return create("ImageLabel")({
		Name = "Logo",
		Visible = UiImages.has(UiImages.LOGO),
		AnchorPoint = Vector2.new(0.5, 0),
		Position = function()
			return UDim2.new(0.5, 0, 0, layout().logoTop)
		end,
		Size = function()
			local panel = MenuState.panel()
			local height = layout().logoHeight
			if panel ~= "play" and panel ~= "kits" then
				height = math.min(height, PANEL_LOGO_HEIGHT)
			end
			return UDim2.fromOffset(height * MenuLayout.LOGO_ASPECT, height)
		end,
		BackgroundTransparency = 1,
		Image = UiImages.LOGO,
		ScaleType = Enum.ScaleType.Fit,
	}) :: ImageLabel
end

-- Boneco, sombra e os botões Kits + JOGAR. Somem com painéis do mockup
-- abertos e quando o painel de kits cobre a área (celular).
local function home(layout: () -> Layout): { Instance }
	local function homeVisible(): boolean
		local panel = MenuState.panel()
		return ScreenState.current() == "menu" and (panel == "play" or panel == "kits") and not layout().kitsCoverHero
	end

	local shadow = create("Frame")({
		Name = "Shadow",
		Visible = homeVisible,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.heroCenterX, l.heroBottom - l.heroSize * 0.08)
		end,
		Size = function()
			local side = layout().heroSize
			return UDim2.fromOffset(side * SHADOW_SHARE.X, side * SHADOW_SHARE.Y)
		end,
		BackgroundColor3 = R.outline,
		BackgroundTransparency = 0.55,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
	}) :: Frame

	local boneco = MenuBoneco.build(homeVisible)
	vide.apply(boneco)({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.heroCenterX, l.heroBottom)
		end,
		Size = function()
			local side = layout().heroSize
			return UDim2.fromOffset(side, side)
		end,
		Visible = homeVisible,
	})

	local actions = create("Frame")({
		Name = "Actions",
		Visible = homeVisible,
		BackgroundTransparency = 1,
		AnchorPoint = Vector2.new(0.5, 0),
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.heroCenterX, l.actionsY)
		end,
		Size = function()
			local l = layout()
			return UDim2.fromOffset(l.actionsWidth, l.actionsHeight)
		end,
		Rustic.button({
			Name = "KitsButton",
			Size = function()
				local l = layout()
				return UDim2.fromOffset(l.kitsButtonWidth, l.actionsHeight)
			end,
			kind = "leather",
			text = Strings.get("menu.kits.button"),
			subtext = kitLabel,
			Activated = function()
				MenuState.open(if vide.untrack(MenuState.panel) == "kits" then "play" else "kits")
			end,
		}),
		Rustic.button({
			Name = "PlayButton",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.fromScale(1, 0),
			Size = function()
				local l = layout()
				return UDim2.fromOffset(l.playButtonWidth, l.actionsHeight)
			end,
			kind = "ember",
			text = Strings.get("menu.play.big"),
			maxSize = 30,
			Activated = function()
				-- Só o kit de pontos vai ao servidor (os de Robux são mockup).
				Net.RequestSpawn.Fire({ KitId = vide.untrack(KitList.selected) })
			end,
		}),
	}) :: Frame

	return { shadow, boneco, actions }
end

local function kitsPanel(layout: () -> Layout): Frame
	local panel = KitsPanel.build()
	vide.apply(panel)({
		Visible = function()
			return MenuState.panel() == "kits"
		end,
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.kitPanelX, l.bodyTop)
		end,
		Size = function()
			local l = layout()
			return UDim2.fromOffset(l.kitPanelWidth, l.panelBottom - l.bodyTop)
		end,
		ZIndex = 2,
	})
	return panel
end

-- Conteúdo de cada painel do mockup, abaixo do título. Os builders rodam uma
-- vez, dentro do root Vide.
local CONTENT: { [MenuState.Panel]: () -> Instance } = {
	ranking = RankingPanel.build,
}

-- Painel do mockup: título, botão de fechar (volta a "play") e o conteúdo.
-- O visual destes painéis é o antigo: o redesenho deles é outra fase.
local function panelFrame(panel: MenuState.Panel, layout: () -> Layout): Frame
	local builder = CONTENT[panel]
	local content = if builder then builder() :: GuiObject else nil
	if content then
		content.Position = UDim2.new(0.02, 0, 0, TITLE_ROW)
		content.Size = UDim2.new(0.96, 0, 1, -(TITLE_ROW + MARGIN))
	end
	return Kit.panel({
		Name = "Panel_" .. panel,
		Visible = function()
			return MenuState.panel() == panel
		end,
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.panelX, l.bodyTop)
		end,
		Size = function()
			local l = layout()
			return UDim2.fromOffset(l.panelWidth, l.panelBottom - l.bodyTop)
		end,
		Kit.text({
			Name = "Title",
			Position = UDim2.fromOffset(12, 4),
			Size = UDim2.new(0.6, 0, 0, TOUCH),
			FontFace = Theme.font.title,
			Text = Strings.get("menu.panel." .. panel),
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 36,
		}),
		Rustic.button({
			Name = "CloseButton",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 4),
			Size = UDim2.new(0.15, 0, 0, TOUCH),
			kind = "wood",
			text = Strings.get("menu.close"),
			Activated = function()
				MenuState.open("play")
			end,
		}),
		content,
	})
end

-- Aviso de compra simulada: faixa no alto, abaixo dos pods; só enquanto há texto.
local function noticeBanner(layout: () -> Layout): Frame
	return Kit.pill({
		Name = "Notice",
		Visible = function()
			return MenuState.notice() ~= nil
		end,
		ZIndex = 10,
		AnchorPoint = Vector2.new(0.5, 0),
		-- Onde fica vem do MenuLayout: nunca cobre o título nem o fechar dos kits.
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.noticeCenterX, l.noticeY)
		end,
		Size = function()
			return UDim2.fromOffset(layout().noticeWidth, MenuLayout.NOTICE_HEIGHT)
		end,
		BackgroundColor3 = Theme.ui.warning,
		BackgroundTransparency = 0,
		text = function()
			return MenuState.notice() or ""
		end,
	})
end

local MenuShell = {}

-- Monta o menu (dentro do root Vide do ScreenController); só aparece no menu.
function MenuShell.mount(playerGui: Instance): ScreenGui
	-- Tamanho da tela em pixels lógicos (descontada a escala da interface).
	local screenSize = vide.source(Vector2.new(1280, 720))
	local layout = vide.derive(function(): Layout
		local size = screenSize()
		return MenuLayout.compute(size.X, size.Y, MenuState.panel() == "kits")
	end)

	local shopLayout = vide.derive(function(): ShopLayout.Layout
		local size = screenSize()
		return ShopLayout.compute(size.X, size.Y)
	end)
	-- Loja aberta: ocupa a tela toda; só o card da Golden Ember fica.
	local function shopOpen(): boolean
		return MenuState.panel() == "shop"
	end
	local function notShop(): boolean
		return not shopOpen()
	end

	local pod = levelPod(layout)
	local logoImage = logo(layout)
	local nav = column(layout)
	vide.apply(pod)({ Visible = notShop })
	vide.apply(logoImage)({
		Visible = function()
			return UiImages.has(UiImages.LOGO) and notShop()
		end,
	})
	vide.apply(nav)({ Visible = notShop })
	-- O card do saldo fica acima da loja (ZIndex maior).
	local balance = balancePod(layout)
	local branchImage = branch(layout)
	balance.ZIndex = 6
	-- No celular a tela do giro sobe até o topo: o card sairia por cima do X.
	vide.apply(balance)({
		Visible = function()
			return not (shopOpen() and ShopState.spinType() ~= nil and shopLayout().compact)
		end,
	})
	-- O galho fica só no menu: na loja as folhas cobririam as abas.
	vide.apply(branchImage)({
		Visible = function()
			return UiImages.has(UiImages.BRANCH) and notShop()
		end,
	})

	local shop = ShopScreen.build(
		shopLayout,
		function()
			return screenSize().Y
		end,
		shopOpen,
		{
			packs = function()
				return Featured.build(shopLayout, shopOpen)
			end,
			passes = function()
				return Passes.build(shopLayout)
			end,
			spins = function()
				return SpinTypes.build(shopLayout, shopOpen)
			end,
			ember = function()
				return EmberPacks.build(shopLayout)
			end,
		}
	)
	-- Tela do giro por cima da loja (abre ao escolher um tipo de giro).
	SpinSounds.preload()
	SpinScreen.build(shopLayout, screenSize, shopOpen, {
		sounds = SpinSounds.begin,
		startPaid = SpinFx.start,
		land = SpinFx.land,
		celebrate = SpinFx.celebrate,
	}).Parent =
		shop

	local children: { Instance } = { pod, branchImage, balance, logoImage, nav }
	for _, instance in home(layout) do
		table.insert(children, instance)
	end
	table.insert(children, kitsPanel(layout))
	for i = 1, #PANELS do
		table.insert(children, panelFrame(PANELS[i], layout))
	end
	-- Perfil e Cosméticos: janelas no centro, por cima do menu (sem escurecer).
	table.insert(children, ProfilePanel.build())
	table.insert(
		children,
		CosmeticsScreen.build(function()
			return screenSize()
		end)
	)
	table.insert(children, shop)
	table.insert(children, noticeBanner(layout))

	local gui = create("ScreenGui")({
		Name = "MenuShell",
		ResetOnSpawn = false,
		-- Abaixo da janela de Configurações (que abre por cima, com o menu escurecido).
		DisplayOrder = 1,
		Enabled = function()
			return ScreenState.current() == "menu"
		end,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		children,
	}) :: ScreenGui
	Template.bindUiScale(gui)

	-- Fundo do menu: a árvore, em tela cheia (passa por trás dos botões do
	-- Roblox no topo) e da altura da tela. Fica num ScreenGui próprio, abaixo
	-- do menu, porque o menu respeita a área segura e a árvore não.
	local backdrop = create("ScreenGui")({
		Name = "MenuBackdrop",
		ResetOnSpawn = false,
		DisplayOrder = 0,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.None,
		Enabled = function()
			return ScreenState.current() == "menu" and MenuState.panel() ~= "shop"
		end,
		create("ImageLabel")({
			Name = "Tree",
			Visible = UiImages.has(UiImages.TREE),
			Size = UDim2.fromScale(MenuLayout.TREE_ASPECT, 1),
			SizeConstraint = Enum.SizeConstraint.RelativeYY, -- largura proporcional à altura
			BackgroundTransparency = 1,
			Image = UiImages.TREE,
			ScaleType = Enum.ScaleType.Fit,
		}),
	}) :: ScreenGui
	backdrop.Parent = playerGui

	local scale = gui:FindFirstChildOfClass("UIScale")
	local function refresh()
		local factor = if scale and scale.Scale > 0 then scale.Scale else 1
		local size = gui.AbsoluteSize / factor
		if size.X > 0 and size.Y > 0 then
			screenSize(size)
		end
	end
	gui:GetPropertyChangedSignal("AbsoluteSize"):Connect(refresh)
	if scale then
		scale:GetPropertyChangedSignal("Scale"):Connect(refresh)
	end
	gui.Parent = playerGui
	refresh()
	return gui
end

return MenuShell
