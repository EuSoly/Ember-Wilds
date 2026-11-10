--!strict
-- Tela de morte (estilo rústico, feita em código, sem molde). Aparece no estado
-- "dead" com o resumo da vida (Net.LifeEnded, em ScreenState.lastSummary).
--
-- Janela escura no centro com a placa "VOCÊ MORREU" pregada no alto. No largo,
-- duas colunas: à esquerda o resumo numa folha de papel (causa ou quem matou,
-- dias, pontos, Golden Ember, nível e barra de XP); à direita os kits de pontos.
-- Na janela estreita, uma coluna só que rola (DeathLayout). Embaixo, "Menu"
-- (couro) e "Jogar de novo" (brasa).
--
-- Ao abrir, o mundo perde a cor (saturação até −1 em 1 s) e os pontos da vida
-- descem até 0 enquanto a Golden Ember sobe até o ganho (CountUp, 2 s). No
-- mesmo tempo, a barra de XP enche do XP de antes até o de agora (o nível sobe
-- e a barra recomeça a cada nível que passa) e, se subiu de nível, aparece
-- "Subiu para o nível N!". Ao sair da morte (nascer ou ir ao menu), a cor volta.
local Lighting = game:GetService("Lighting")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local CountUp = require(Shared:WaitForChild("UIFlow"):WaitForChild("CountUp"))
local DeathLayout = require(Shared:WaitForChild("UIFlow"):WaitForChild("DeathLayout"))
local KitChoice = require(Shared:WaitForChild("UIFlow"):WaitForChild("KitChoice"))
local KitRules = require(Shared:WaitForChild("UIFlow"):WaitForChild("KitRules"))
local LevelRules = require(Shared:WaitForChild("Data"):WaitForChild("LevelRules"))
local ProfileFormat = require(Shared:WaitForChild("UIFlow"):WaitForChild("ProfileFormat"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local UiImages = require(Shared:WaitForChild("UiImages"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local ScreenState = require(Client:WaitForChild("ScreenState"))
local ShopData = require(Client:WaitForChild("ShopData"))
local Template = require(Client:WaitForChild("UITemplates"):WaitForChild("Template"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local KitList = require(script.Parent:WaitForChild("KitList"))

local create = vide.create
local R = Theme.rustic

-- Fonte Vide: chamar sem argumento lê, com argumento escreve.
type Source<T> = (() -> T) & ((T) -> T)

local COUNT_DURATION = 2 -- segundos (pontos → Golden Ember, barra de XP)
local DESATURATE_INFO = TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local RESTORE_INFO = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local EFFECT_NAME = "DeathDesaturate"

local BODY = Color3.fromHex("#2B2018") -- corpo da janela (igual às Configurações)
local WELL = Color3.fromHex("#3A2B20") -- fundo da coluna dos kits
local DIM_TRANSPARENCY = 0.6 -- o mundo (já sem cor) fica um pouco mais escuro
local PLATE_WIDTH = 360
local KIT_DISABLED = 0.55 -- quanto o kit fora do alcance fica apagado
local COIN_SIZE = 26

local TITLE_HEIGHT = DeathLayout.TITLE_HEIGHT
local BUTTONS_HEIGHT = DeathLayout.BUTTONS_HEIGHT

local DeathScreen = {}

-- Efeito local (criado pelo cliente, não replica) que tira a cor do mundo.
local function desaturateEffect(): ColorCorrectionEffect
	local existing = Lighting:FindFirstChild(EFFECT_NAME)
	if existing and existing:IsA("ColorCorrectionEffect") then
		return existing
	end
	local effect = Instance.new("ColorCorrectionEffect")
	effect.Name = EFFECT_NAME
	effect.Saturation = 0
	effect.Parent = Lighting
	return effect
end

-- Posição e tamanho de um retângulo do layout (reativo).
local function place(rect: () -> DeathLayout.Rect): { [string]: any }
	return {
		Position = function()
			local r = rect()
			return UDim2.fromOffset(r.x, r.y)
		end,
		Size = function()
			local r = rect()
			return UDim2.fromOffset(r.w, r.h)
		end,
	}
end

-- Linha de texto do resumo (centralizada, sobre o papel).
local function summaryLine(props: { [any]: any }): TextLabel
	props.dark = true
	props.Size = props.Size or UDim2.new(1, 0, 0, 22)
	return Rustic.label(props)
end

-- Estado mostrado durante a contagem (escrito no quadro a quadro).
type Shown = {
	cause: Source<string>,
	days: Source<number>,
	points: Source<number>,
	currency: Source<number>,
	xp: Source<number>,
	xpGained: Source<number>,
	levelUp: Source<number?>, -- nível novo, quando já pode mostrar o aviso
}

local function summary(shown: Shown, rect: () -> DeathLayout.Rect): Frame
	local progress = vide.derive(function()
		return LevelRules.progress(shown.xp())
	end)
	local coin = UiImages.has(UiImages.COIN)

	-- As linhas ficam num Frame próprio: o papel tem um filho de borda (Edge)
	-- que a UIListLayout empilharia junto se ficasse direto nele.
	local content = create("Frame")({
		Name = "Content",
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		create("UIPadding")({
			PaddingTop = UDim.new(0, 10),
			PaddingBottom = UDim.new(0, 10),
			PaddingLeft = UDim.new(0, 14),
			PaddingRight = UDim.new(0, 14),
		}),
		create("UIListLayout")({
			SortOrder = Enum.SortOrder.LayoutOrder,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, 2),
		}),
		summaryLine({
			Name = "CauseLabel",
			LayoutOrder = 1,
			FontFace = Theme.font.label,
			Text = function()
				return Strings.format("death.cause", { cause = shown.cause() })
			end,
			maxSize = 18,
		}),
		summaryLine({
			Name = "DaysLabel",
			LayoutOrder = 2,
			FontFace = Theme.font.label,
			TextColor3 = R.textSecondaryLight,
			Text = function()
				return Strings.format("death.days", { days = shown.days() })
			end,
			maxSize = 16,
		}),
		summaryLine({
			Name = "PointsLabel",
			LayoutOrder = 3,
			Size = UDim2.new(1, 0, 0, 38),
			FontFace = Theme.font.number,
			Text = function()
				return Strings.format("death.points", { points = ProfileFormat.thousands(shown.points()) })
			end,
			maxSize = 32,
		}),
		-- Moeda: o ícone da Golden Ember ao lado do ganho, centralizados juntos.
		create("Frame")({
			Name = "Currency",
			LayoutOrder = 4,
			Size = UDim2.new(1, 0, 0, 30),
			BackgroundTransparency = 1,
			create("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			create("ImageLabel")({
				Name = "Coin",
				LayoutOrder = 1,
				Visible = coin,
				Size = UDim2.fromOffset(COIN_SIZE, COIN_SIZE),
				BackgroundTransparency = 1,
				Image = UiImages.COIN,
				ScaleType = Enum.ScaleType.Fit,
			}),
			Rustic.label({
				Name = "CurrencyLabel",
				LayoutOrder = 2,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromScale(0, 1),
				TextScaled = false,
				TextSize = 22,
				FontFace = Theme.font.number,
				TextColor3 = R.emberShadow,
				Text = function()
					return Strings.format("death.currency", { amount = ProfileFormat.thousands(shown.currency()) })
				end,
			}),
		}),
		create("Frame")({ Name = "Gap", LayoutOrder = 5, Size = UDim2.new(1, 0, 0, 6), BackgroundTransparency = 1 }),
		-- Nível à esquerda, XP ganho à direita (como a placa de nível do menu).
		create("Frame")({
			Name = "LevelRow",
			LayoutOrder = 6,
			Size = UDim2.new(1, 0, 0, 20),
			BackgroundTransparency = 1,
			Rustic.label({
				Name = "LevelLabel",
				dark = true,
				Size = UDim2.fromScale(0.5, 1),
				FontFace = Theme.font.number,
				TextXAlignment = Enum.TextXAlignment.Left,
				Text = function()
					return Strings.format("menu.level", { level = progress().level })
				end,
				maxSize = 16,
			}),
			Rustic.label({
				Name = "XpLabel",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = UDim2.fromScale(0.5, 1),
				FontFace = Theme.font.number,
				TextColor3 = R.emberShadow,
				TextXAlignment = Enum.TextXAlignment.Right,
				Text = function()
					return Strings.format("death.xp", { xp = ProfileFormat.thousands(shown.xpGained()) })
				end,
				maxSize = 16,
			}),
		}),
		Rustic.bar({
			Name = "XpBar",
			LayoutOrder = 7,
			Size = UDim2.new(1, 0, 0, 20),
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
			maxSize = 13,
		}),
		summaryLine({
			Name = "LevelUpLabel",
			LayoutOrder = 8,
			Size = UDim2.new(1, 0, 0, 20),
			FontFace = Theme.font.number,
			TextColor3 = R.emberShadow,
			-- Ocupa o lugar mesmo escondido: o resumo não pula quando aparece.
			TextTransparency = function()
				return if shown.levelUp() then 0 else 1
			end,
			Text = function()
				local level = shown.levelUp()
				return if level then Strings.format("death.levelup", { level = level }) else ""
			end,
			maxSize = 16,
		}),
	})
	local paper = Rustic.paper({ Name = "Summary", content })
	return vide.apply(paper)(place(rect)) :: Frame
end

local function kitRow(kit: Defs.KitDef): TextButton
	-- Dá para escolher com pontos ou com o saldo de 1 vida comprado na loja.
	local function canBuy(): boolean
		return KitChoice.auto(kit.id, KitList.points(), ShopData.balances(), Defs.Kits) ~= nil
	end
	local function balance(): number
		return ShopData.kitBalance(kit.id)
	end
	local function isSelected(): boolean
		return KitList.selected() == kit.id
	end
	local function fade(): number
		return if canBuy() then 0 else KIT_DISABLED
	end
	return create("TextButton")({
		Name = kit.id,
		LayoutOrder = kit.order,
		Size = UDim2.new(1, 0, 0, DeathLayout.KIT_ROW),
		Text = "",
		-- Sem o escurecer automático do Roblox (deixa o papel cinza no hover).
		AutoButtonColor = false,
		Active = canBuy,
		BackgroundColor3 = R.paperLight,
		BackgroundTransparency = fade,
		BorderSizePixel = 0,
		Activated = function()
			KitList.toggle(kit.id)
		end,
		create("UICorner")({ CornerRadius = UDim.new(0, 4) }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = function()
				return if isSelected() then R.ember else R.paperShadow
			end,
			Thickness = function()
				return if isSelected() then 3 else 2
			end,
			Transparency = fade,
		}),
		create("UIPadding")({ PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12) }),
		Rustic.label({
			Name = "NameLabel",
			dark = true,
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.new(0.62, 0, 0, 24),
			FontFace = Theme.font.number,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTransparency = fade,
			Text = function()
				local name = Strings.get(kit.nameKey)
				local n = balance()
				return if n > 0 then `{name} · {Strings.format("kit.balance", { n = n })}` else name
			end,
			maxSize = 19,
		}),
		Rustic.label({
			Name = "PriceLabel",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.fromScale(1, 0.5),
			Size = UDim2.new(0.38, 0, 0, 22),
			FontFace = Theme.font.number,
			TextColor3 = R.emberShadow,
			TextXAlignment = Enum.TextXAlignment.Right,
			TextTransparency = fade,
			Text = Strings.format("kit.price", { price = ProfileFormat.thousands(kit.price) }),
			maxSize = 18,
		}),
	}) :: TextButton
end

local function kitsColumn(layout: () -> DeathLayout.Layout, rect: () -> DeathLayout.Rect): Frame
	local rows: { Instance } = {
		create("UIListLayout")({ Padding = UDim.new(0, DeathLayout.KIT_GAP), SortOrder = Enum.SortOrder.LayoutOrder }),
		-- Espaço para o contorno de brasa do escolhido não ser cortado.
		create("UIPadding")({
			PaddingTop = UDim.new(0, DeathLayout.KIT_LIST_INSET),
			PaddingBottom = UDim.new(0, DeathLayout.KIT_LIST_INSET),
			PaddingLeft = UDim.new(0, DeathLayout.KIT_LIST_INSET),
			PaddingRight = UDim.new(0, 8),
		}),
	}
	for _, kit in KitRules.sorted(Defs.Kits) do
		table.insert(rows, kitRow(kit))
	end
	local column = create("Frame")({
		Name = "Kits",
		BackgroundColor3 = WELL,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0, 6) }),
		Rustic.label({
			Name = "KitsTitle",
			Position = UDim2.fromOffset(12, 6),
			Size = UDim2.new(1, -24, 0, 24),
			FontFace = Theme.font.title,
			TextColor3 = R.emberLight,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = string.upper(Strings.get("menu.kits")),
			maxSize = 22,
			create("UIStroke")({ Color = R.outline, Thickness = 2 }),
		}),
		Rustic.label({
			Name = "KitPointsLabel",
			Position = UDim2.fromOffset(12, 30),
			Size = UDim2.new(1, -24, 0, 16),
			FontFace = Theme.font.label,
			TextColor3 = R.textSecondaryDark,
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = function()
				return Strings.format("kit.points", { points = ProfileFormat.thousands(KitList.points()) })
			end,
			maxSize = 15,
		}),
		create("ScrollingFrame")({
			Name = "KitList",
			Position = UDim2.fromOffset(8, DeathLayout.KITS_HEADER),
			Size = UDim2.new(1, -12, 1, -(DeathLayout.KITS_HEADER + DeathLayout.KITS_PADDING)),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			CanvasSize = UDim2.new(),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			ScrollingDirection = Enum.ScrollingDirection.Y,
			-- Empilhado: a tela inteira rola; a lista mostra todos os kits.
			ScrollingEnabled = function()
				return not layout().stacked
			end,
			ScrollBarThickness = function()
				return if layout().stacked then 0 else 4
			end,
			ScrollBarImageColor3 = R.woodLight,
			rows,
		}),
	}) :: Frame
	return vide.apply(column)(place(rect)) :: Frame
end

-- Monta a tela (dentro do root Vide do ScreenController). O ScreenController
-- liga e desliga pelo Template.show (fade no CanvasGroup "Root").
function DeathScreen.mount(playerGui: Instance): ScreenGui?
	KitList.start()

	local kitCount = #KitRules.sorted(Defs.Kits)
	-- Tamanho da tela em pixels lógicos (descontada a escala da interface).
	local screenSize: Source<Vector2> = vide.source(Vector2.new(1280, 720)) :: any
	local layout = vide.derive(function(): DeathLayout.Layout
		local size = screenSize()
		return DeathLayout.compute(size.X, size.Y, kitCount)
	end)

	local shown: Shown = {
		cause = vide.source("") :: any,
		days = vide.source(0) :: any,
		points = vide.source(0) :: any,
		currency = vide.source(0) :: any,
		xp = vide.source(0) :: any,
		xpGained = vide.source(0) :: any,
		levelUp = vide.source(nil :: number?) :: any,
	}

	local gui = create("ScreenGui")({
		Name = "Death",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 10,
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.None,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		create("CanvasGroup")({
			Name = "Root",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			create("Frame")({
				Name = "Dim",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = R.outline,
				BackgroundTransparency = DIM_TRANSPARENCY,
				BorderSizePixel = 0,
			}),
			create("Frame")({
				Name = "Window",
				AnchorPoint = Vector2.new(0.5, 0.5),
				-- A placa sai metade por cima: o conjunto fica no centro.
				Position = UDim2.new(0.5, 0, 0.5, TITLE_HEIGHT / 4),
				Size = function()
					local l = layout()
					return UDim2.fromOffset(l.panelWidth, l.panelHeight)
				end,
				BackgroundColor3 = BODY,
				BorderSizePixel = 0,
				Active = true,
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
					Size = function()
						local l = layout()
						return UDim2.fromOffset(math.min(PLATE_WIDTH, l.panelWidth * 0.8), TITLE_HEIGHT)
					end,
					ZIndex = 3,
					Rustic.label({
						Name = "TitleLabel",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.86, 0.6),
						FontFace = Theme.font.title,
						Text = string.upper(Strings.get("death.title")),
						maxSize = 32,
						ZIndex = 4,
						create("UIStroke")({ Color = R.outline, Thickness = 2 }),
					}),
				}),
				create("ScrollingFrame")({
					Name = "Body",
					Position = UDim2.fromOffset(DeathLayout.BODY_SIDE, DeathLayout.BODY_TOP),
					Size = function()
						local l = layout()
						-- Empilhado: um respiro à direita para a barra de rolagem.
						return UDim2.fromOffset(l.bodyWidth + (if l.stacked then 8 else 0), l.bodyHeight)
					end,
					CanvasSize = function()
						return UDim2.fromOffset(0, layout().canvasHeight)
					end,
					ScrollingEnabled = function()
						return layout().stacked
					end,
					ScrollBarThickness = function()
						return if layout().stacked then 6 else 0
					end,
					ScrollBarImageColor3 = R.woodLight,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					summary(shown, function()
						return layout().summary
					end),
					kitsColumn(layout, function()
						return layout().kits
					end),
				}),
				create("Frame")({
					Name = "Buttons",
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 1, -16),
					Size = UDim2.new(1, -DeathLayout.BODY_SIDE * 2, 0, BUTTONS_HEIGHT),
					BackgroundTransparency = 1,
					Rustic.button({
						Name = "MenuButton",
						Size = UDim2.new(1 / 3, -4, 1, 0),
						kind = "leather",
						text = Strings.get("death.menu"),
						maxSize = 22,
						Activated = function()
							ScreenState.send("toMenu")
						end,
					}),
					Rustic.button({
						Name = "PlayAgainButton",
						AnchorPoint = Vector2.new(1, 0),
						Position = UDim2.fromScale(1, 0),
						Size = UDim2.new(2 / 3, -4, 1, 0),
						kind = "ember",
						text = Strings.get("death.playAgain"),
						maxSize = 26,
						Activated = function()
							Net.RequestSpawn.Fire({
								KitId = vide.untrack(KitList.selected),
								Source = vide.untrack(KitList.source),
							})
						end,
					}),
				}),
			}),
		}),
	}) :: ScreenGui
	Template.bindUiScale(gui)

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

	local effect = desaturateEffect()
	local counting: RBXScriptConnection? = nil

	local function stopCounting()
		if counting then
			counting:Disconnect()
			counting = nil
		end
	end

	vide.effect(function()
		local screen = ScreenState.current()
		if screen == "dead" then
			local life = vide.untrack(ScreenState.lastSummary)
			local causeKey = if life then life.CauseKey else "death.cause.unknown"
			local points = if life then life.Points else 0
			local currency = if life then life.Currency else 0
			local xpGained = if life then life.Xp else 0
			local xpAfter = if life then life.XpTotal else 0
			local xpBefore = math.max(xpAfter - xpGained, 0)
			local levelAfter = LevelRules.progress(xpAfter).level
			local leveledUp = levelAfter > LevelRules.progress(xpBefore).level
			-- Morte por jogador: o nome de quem matou no lugar da causa.
			local killerName = if life then life.KillerName else nil
			shown.cause(if killerName then killerName else Strings.get(causeKey))
			shown.days(if life then life.Days else 0)
			shown.xpGained(xpGained)
			shown.levelUp(nil)
			shown.points(points)
			shown.currency(0)
			shown.xp(xpBefore)
			TweenService:Create(effect, DESATURATE_INFO, { Saturation = -1 }):Play()

			stopCounting()
			local started = os.clock()
			counting = RunService.RenderStepped:Connect(function()
				local elapsed = os.clock() - started
				local shownPoints, shownCurrency = CountUp.at(elapsed, COUNT_DURATION, points, currency)
				shown.points(shownPoints)
				shown.currency(shownCurrency)
				local t = math.clamp(elapsed / COUNT_DURATION, 0, 1)
				shown.xp(math.floor(xpBefore + (xpAfter - xpBefore) * t))
				if elapsed >= COUNT_DURATION then
					stopCounting()
					if leveledUp then
						shown.levelUp(levelAfter)
					end
				end
			end)
		else
			-- Saiu da morte (nasceu ou foi ao menu): a cor volta.
			stopCounting()
			if effect.Saturation ~= 0 then
				TweenService:Create(effect, RESTORE_INFO, { Saturation = 0 }):Play()
			end
		end
	end)

	gui.Parent = playerGui
	refresh()
	return gui
end

return DeathScreen
