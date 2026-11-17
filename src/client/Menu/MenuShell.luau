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
local TutorialState = require(Client:WaitForChild("TutorialState"))
local Template = require(Client:WaitForChild("UITemplates"):WaitForChild("Template"))
local SettingsScreen = require(Client:WaitForChild("Screens"):WaitForChild("SettingsScreen"))
local MissionsState = require(Client:WaitForChild("MissionsState"))
local KitList = require(Client:WaitForChild("Screens"):WaitForChild("KitList"))
local Kit = require(Client:WaitForChild("UI"):WaitForChild("Kit"))
local XpBoostBadge = require(Client:WaitForChild("UI"):WaitForChild("XpBoostBadge"))
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
local RankingScreen = require(script.Parent:WaitForChild("Ranking"):WaitForChild("RankingScreen"))
local ProfilePanel = require(script.Parent:WaitForChild("ProfilePanel"))
local CheckInPanel = require(script.Parent:WaitForChild("CheckInPanel"))
local TutorialSpinPopup = require(script.Parent:WaitForChild("TutorialSpinPopup"))
local AssetProgress = require(script.Parent:WaitForChild("AssetProgress"))
local CosmeticsScreen = require(script.Parent:WaitForChild("Cosmetics"):WaitForChild("CosmeticsScreen"))

local create = vide.create
local R = Theme.rustic

-- Botões da coluna, de cima para baixo (ids de MenuState.Panel). "settings"
-- não é painel: abre a janela de Configurações de sempre.
local NAV: { string } = { "profile", "cosmetics", "shop", "missions", "ranking", "settings" }

local MARGIN = MenuLayout.MARGIN
local TOUCH = Theme.touchMinSize.Y
local SHADOW_SHARE = Vector2.new(0.62, 0.11) -- sombra no chão, fração do lado do boneco
-- Altura do centro da sombra acima da base da área do boneco (fração do lado):
-- os pés do boneco ficam acima da base, por causa do enquadramento da câmera.
local SHADOW_LIFT = 0.25

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

-- Pods no celular (48 de altura, 17/11/2026): avatar, moeda e "+" encolhem
-- junto; o "+" fica com 40 (a mesma exceção de toque dos botões da coluna).
local function avatarSide(l: Layout): number
	return l.podHeight - 12
end
local function textLeft(l: Layout): number
	return avatarSide(l) + 14
end
local function coinSide(l: Layout): number
	return math.min(COIN_SIZE, l.podHeight - 12)
end
local function buySide(l: Layout): number
	return if l.compact then math.max(l.podHeight - 8, 40) else TOUCH
end

-- "Nenhum" ou o nome do kit da próxima vida ("Explorador").
local function kitLabel(): string
	local id = KitShop.current()
	if id == nil then
		return Strings.get("menu.kits.none")
	end
	local kit = Defs.Kits[id]
	return if kit then Strings.get(kit.nameKey) else id
end

local function navButton(id: string, layout: () -> Layout): TextButton
	return Rustic.button({
		Name = "Nav_" .. id,
		Size = function()
			return UDim2.new(1, -6, 0, layout().buttonHeight)
		end,
		kind = function()
			local active = if id == "settings"
				then SettingsScreen.open()
				elseif id == "missions" then MissionsState.open()
				else MenuState.panel() == id
			return if active then "ember" else "wood"
		end,
		text = Strings.get("menu.nav." .. id),
		maxSize = 20,
		-- Uma janela por vez: as Configurações abrem no mesmo lugar do Perfil e
		-- dos Cosméticos, sem fundo escuro, então abrir uma fecha a outra.
		Activated = function()
			if id == "settings" then
				MenuState.open("play")
				MissionsState.open(false)
				SettingsScreen.open(true)
			elseif id == "missions" then
				MenuState.open("play")
				SettingsScreen.open(false)
				MissionsState.open(true)
			else
				MissionsState.open(false)
				SettingsScreen.open(false)
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
			Padding = function()
				return UDim.new(0, layout().buttonGap)
			end,
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
			return UDim2.fromOffset(podWidth(l), l.podHeight)
		end,
		-- Rosto do avatar do Roblox do jogador, numa moldura de madeira.
		create("Frame")({
			Name = "Avatar",
			Position = UDim2.fromOffset(6, 6),
			Size = function()
				local side = avatarSide(layout())
				return UDim2.fromOffset(side, side)
			end,
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
			Position = function()
				return UDim2.fromOffset(textLeft(layout()), if layout().compact then 4 else 5)
			end,
			Size = function()
				local left = textLeft(layout())
				return UDim2.new(0.58, -left, 0, if layout().compact then 18 else 20)
			end,
			FontFace = Theme.font.number,
			Text = Players.LocalPlayer.DisplayName,
			TextXAlignment = Enum.TextXAlignment.Left,
			maxSize = 17,
			create("UIStroke")({ Color = R.outline, Thickness = 1.5 }),
		}),
		Rustic.label({
			Name = "LevelText",
			AnchorPoint = Vector2.new(1, 0),
			Position = function()
				return UDim2.new(1, -10, 0, if layout().compact then 4 else 5)
			end,
			Size = function()
				return UDim2.new(0.42, -10, 0, if layout().compact then 18 else 20)
			end,
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
			Position = function()
				return UDim2.fromOffset(textLeft(layout()), if layout().compact then 26 else 30)
			end,
			Size = function()
				local left = textLeft(layout())
				return UDim2.new(1, -(left + 10), 0, if layout().compact then 16 else 18)
			end,
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
			local l = layout()
			return UDim2.fromOffset(podWidth(l), l.podHeight)
		end,
		create("ImageLabel")({
			Name = "Coin",
			Visible = UiImages.has(UiImages.COIN),
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 14, 0.5, -1),
			Size = function()
				local side = coinSide(layout())
				return UDim2.fromOffset(side, side)
			end,
			BackgroundTransparency = 1,
			Image = UiImages.COIN,
			ScaleType = Enum.ScaleType.Fit,
		}),
		-- Saldo real (atributo Currency); o mockup nunca o altera.
		Rustic.label({
			Name = "Balance",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = function()
				return UDim2.new(0, 14 + coinSide(layout()) + 8, 0.5, 0)
			end,
			Size = function()
				local l = layout()
				return UDim2.new(1, -(buySide(l) + 34 + coinSide(l)), 0.6, 0)
			end,
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
			Size = function()
				local side = buySide(layout())
				return UDim2.fromOffset(side, side)
			end,
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

-- Galho do celular (17/11/2026): no fundo sem área segura (MenuBackdrop), para
-- encostar de verdade no canto de cima e na borda direita da tela; no
-- celular a área segura deixava um vão entre o galho e a borda. Mede o card
-- do saldo (mesmo espaço de coordenadas do fundo) e estica o galho do mesmo
-- recuo à esquerda do card de sempre até a borda direita.
type Box = { position: Vector2, size: Vector2 }

local function boxOf(instance: GuiBase2d): Box
	return { position = instance.AbsolutePosition, size = instance.AbsoluteSize }
end

local function watchBox(instance: GuiBase2d): () -> Box
	local box = vide.source(boxOf(instance))
	local function update()
		box(boxOf(instance))
	end
	instance:GetPropertyChangedSignal("AbsolutePosition"):Connect(update)
	instance:GetPropertyChangedSignal("AbsoluteSize"):Connect(update)
	return box
end

local function compactBranch(card: () -> Box, screen: () -> Box, visible: () -> boolean): ImageLabel
	return create("ImageLabel")({
		Name = "BranchCompact",
		Visible = visible,
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(1, 0),
		Size = function()
			local c, s = card(), screen()
			local cardLeft = c.position.X - s.position.X
			local width = (s.size.X - cardLeft) + c.size.X * (BRANCH_SHARE - 1)
			return UDim2.fromOffset(width, width / BRANCH_ASPECT)
		end,
		BackgroundTransparency = 1,
		Image = UiImages.BRANCH,
		ScaleType = Enum.ScaleType.Fit,
		ZIndex = 2,
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
			-- As Configurações contam como janela aberta (abrem no mesmo lugar).
			if (panel ~= "play" and panel ~= "kits") or SettingsScreen.open() then
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
		-- As Configurações também escondem (abrem no lugar das outras janelas).
		return ScreenState.current() == "menu"
			and (panel == "play" or panel == "kits")
			and not layout().kitsCoverHero
			and not SettingsScreen.open()
	end

	local shadow = create("Frame")({
		Name = "Shadow",
		Visible = homeVisible,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.heroCenterX, l.heroBottom - l.heroSize * SHADOW_LIFT)
		end,
		Size = function()
			local side = layout().heroSize
			return UDim2.fromOffset(side * SHADOW_SHARE.X, side * SHADOW_SHARE.Y)
		end,
		BackgroundColor3 = R.outline,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		-- Some nas pontas, para parecer sombra e não uma barra.
		create("UIGradient")({
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.25, 0.2),
				NumberSequenceKeypoint.new(0.75, 0.2),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
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
		-- O JOGAR (à direita do grupo) fica embaixo do boneco; os kits, à esquerda.
		Position = function()
			local l = layout()
			return UDim2.fromOffset(l.actionsX, l.actionsY)
		end,
		Size = function()
			local l = layout()
			return UDim2.fromOffset(l.actionsWidth, l.actionsHeight)
		end,
		Rustic.button({
			Name = "KitsButton",
			-- Tutorial pendente: a próxima vida é de tutorial, sem kit.
			Visible = function()
				return not TutorialState.pending()
			end,
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
				-- O kit escolhido e a origem (pontos ou saldo); sem escolha, o
				-- servidor usa o kit para sempre ativo.
				Net.RequestSpawn.Fire({
					KitId = vide.untrack(KitList.selected),
					Source = vide.untrack(KitList.source),
				})
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

-- Aviso do menu (resultado de compra...): faixa no alto, abaixo dos pods; só enquanto há texto.
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
	-- Ranking aberto no celular: sobe até o topo, então o logo, o saldo e o
	-- galho saem da frente (pedido do Elizeu, 17/11/2026).
	local function rankingOnTop(): boolean
		return MenuState.panel() == "ranking" and layout().compact
	end

	local pod = levelPod(layout)
	local logoImage = logo(layout)
	local nav = column(layout)
	vide.apply(pod)({ Visible = notShop })
	vide.apply(logoImage)({
		Visible = function()
			return UiImages.has(UiImages.LOGO) and notShop() and not rankingOnTop()
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
			return not (shopOpen() and ShopState.spinType() ~= nil and shopLayout().compact) and not rankingOnTop()
		end,
	})
	-- O galho fica só no menu: na loja as folhas cobririam as abas. No celular
	-- quem aparece é o galho do fundo (compactBranch).
	local function branchVisible(): boolean
		return UiImages.has(UiImages.BRANCH) and notShop() and not rankingOnTop()
	end
	vide.apply(branchImage)({
		Visible = function()
			return branchVisible() and not layout().compact
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
		tick = SpinFx.tick,
		land = SpinFx.land,
		celebrate = SpinFx.celebrate,
	}).Parent =
		shop

	local children: { Instance } = { pod, branchImage, balance, logoImage, nav }
	for _, instance in home(layout) do
		table.insert(children, instance)
	end
	table.insert(children, kitsPanel(layout))
	-- Ranking semanal (UI 6): à direita da coluna.
	table.insert(children, RankingScreen.build(layout))
	-- Perfil e Cosméticos: janelas no centro, por cima do menu (sem escurecer).
	table.insert(children, ProfilePanel.build())
	table.insert(
		children,
		CosmeticsScreen.build(function()
			return screenSize()
		end)
	)
	table.insert(children, shop)
	-- Check-in de 7 dias: calendário abaixo do saldo (só no menu "limpo") e a janela.
	table.insert(
		children,
		CheckInPanel.button(layout, function()
			return MenuState.panel() == "play" and not rankingOnTop()
		end)
	)
	table.insert(children, CheckInPanel.build())
	table.insert(children, noticeBanner(layout))
	-- Boost de XP correndo: contagem no centro, logo abaixo do aviso (que fica
	-- no mesmo eixo), só no menu "limpo" como o calendário do check-in.
	table.insert(
		children,
		XpBoostBadge.build({
			AnchorPoint = Vector2.new(0.5, 0),
			Position = function()
				local l = layout()
				return UDim2.fromOffset(l.noticeCenterX, l.noticeY + MenuLayout.NOTICE_HEIGHT + 4)
			end,
			Size = UDim2.fromOffset(112, 34),
		}, function()
			return MenuState.panel() == "play" and not rankingOnTop()
		end)
	)
	-- Artes ainda baixando em segundo plano: contagem pequena no canto.
	table.insert(children, AssetProgress.build())

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
	compactBranch(watchBox(balance), watchBox(backdrop), function()
		return branchVisible() and layout().compact
	end).Parent =
		backdrop
	backdrop.Parent = playerGui

	-- Pop-up da roleta depois do tutorial (uma vez): ScreenGui próprio, por cima
	-- do menu, e sem a área segura, para o fundo escuro cobrir a tela toda
	-- (inclusive atrás dos botões do Roblox no topo).
	local popup = create("ScreenGui")({
		Name = "TutorialSpinPopup",
		ResetOnSpawn = false,
		DisplayOrder = 2,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.None,
		Enabled = function()
			return ScreenState.current() == "menu"
		end,
		TutorialSpinPopup.build(),
	}) :: ScreenGui
	popup.Parent = playerGui

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
