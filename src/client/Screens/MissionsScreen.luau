--!strict
-- Missões (layout A, spec 2026-11-12-missoes): janela rústica por cima do menu
-- e do jogo, com 4 abas em cima (Partida, Diárias, Semanais, Conquistas) e a
-- lista de cartões embaixo. Abre pelo botão do HUD e pelo da coluna do menu;
-- fecha no X ou tocando fora. Tudo vem do retrato do servidor
-- (MissionsState.data); o RESGATAR só pede (Net.ClaimMission).
-- Artes em MissionImages (id vazio = desenho de reserva por código).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local MissionConfig = require(Shared:WaitForChild("Missions"):WaitForChild("MissionConfig"))
local MissionImages = require(Shared:WaitForChild("MissionImages"))
local MissionView = require(Shared:WaitForChild("UIFlow"):WaitForChild("MissionView"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local MissionsState = require(Client:WaitForChild("MissionsState"))
local SoundPlayer = require(Client:WaitForChild("Audio"):WaitForChild("SoundPlayer"))
local Template = require(Client:WaitForChild("UITemplates"):WaitForChild("Template"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))
local ItemIcon = require(Client:WaitForChild("UI"):WaitForChild("ItemIcon"))
local UiImages = require(Shared:WaitForChild("UiImages"))

local create = vide.create
local R = Theme.rustic

type Tab = MissionView.Tab
type Piece = MissionImages.Piece
type Badge = MissionView.Badge

local PANEL_MAX = Vector2.new(760, 520)
local TITLE_HEIGHT = 46
local TAB_HEIGHT = 38
local HEADER_HEIGHT = 18
local CARD_HEIGHT = 74
-- Os cartões pronto e falhou têm uma fita na ponta direita da arte (de x 800 a
-- 1024 em 241 de altura): prêmio e RESGATAR ficam antes dela.
local RIBBON = math.round((1024 - 800) * CARD_HEIGHT / 241) + 6
local STATE_READY, STATE_CLAIMED, STATE_FAILED, STATE_LOCKED = 1, 2, 3, 4
-- A moldura da janela sai fina: cantos em ~45% do tamanho que teriam pela altura.
local WINDOW_SLICE_FACTOR = 0.45

local MissionsScreen = {}

MissionsScreen.open = MissionsState.open
MissionsScreen.toggle = MissionsState.toggle

-- Relógios da tela (andam de segundo em segundo enquanto a janela existe).
-- unixNow: relógio do servidor em unix (o EndsAt das diárias é unix): não
-- depende do relógio do aparelho.
local unixNow = vide.source(math.floor(Workspace:GetServerTimeNow()))
local serverNow = vide.source(Workspace:GetServerTimeNow())

-- Imagem de uma peça (9 partes se tiver slice). Os cantos acompanham a altura
-- do elemento: SliceScale = altura na tela / altura da arte.
local function art(piece: Piece, props: { [any]: any }, factor: number?): ImageLabel
	local image = create("ImageLabel")({
		BackgroundTransparency = 1,
		Image = piece.image,
		ScaleType = if piece.slice then Enum.ScaleType.Slice else Enum.ScaleType.Fit,
		SliceCenter = if piece.slice
			then Rect.new(piece.slice[1], piece.slice[2], piece.slice[3], piece.slice[4])
			else Rect.new(0, 0, 0, 0),
	}) :: ImageLabel
	vide.apply(image)(props)
	if piece.slice then
		local function fit()
			local height = image.AbsoluteSize.Y
			image.SliceScale = if height > 0 then math.clamp(height / piece.size[2] * (factor or 1), 0.05, 1) else 1
		end
		image:GetPropertyChangedSignal("AbsoluteSize"):Connect(fit)
		fit()
	end
	return image
end

local function hasArt(piece: Piece): boolean
	return piece.image ~= ""
end

-- Ícone de missão; sem arte, um quadrado de madeira com a inicial.
local function icon(key: string | () -> string, props: { [any]: any }): Instance
	local function id(): string
		return MissionImages.ICON[if type(key) == "function" then key() else key] or ""
	end
	local frame = create("Frame")({
		BackgroundColor3 = R.woodLight,
		BackgroundTransparency = function()
			return if id() ~= "" then 1 else 0
		end,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		create("UIAspectRatioConstraint")({ AspectRatio = 1 }),
		create("ImageLabel")({
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Image = id,
			ScaleType = Enum.ScaleType.Fit,
		}),
	})
	return vide.apply(frame)(props)
end

-- Bolinha vermelha com o número de prêmios esperando.
local function dot(count: () -> number): Instance
	local piece = MissionImages.PIECES.DOT
	return create("Frame")({
		Name = "Dot",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -4, 0, 4),
		Size = UDim2.fromOffset(20, 20),
		BackgroundColor3 = Color3.fromHex("#E0412F"),
		BackgroundTransparency = if hasArt(piece) then 1 else 0,
		Visible = function()
			return count() > 0
		end,
		ZIndex = 6,
		create("UICorner")({ CornerRadius = UDim.new(1, 0) }),
		create("UIStroke")({ Color = R.outline, Thickness = if hasArt(piece) then 0 else 2 }),
		if hasArt(piece) then art(piece, { Size = UDim2.fromScale(1, 1), ZIndex = 6 }) else nil,
		Rustic.label({
			Size = UDim2.fromScale(0.8, 0.8),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			FontFace = Theme.font.number,
			Text = function()
				return tostring(count())
			end,
			maxSize = 13,
			ZIndex = 7,
		}),
	})
end

-- Barra de progresso (trilho + preenchimento laranja; verde quando completa).
local function bar(fraction: () -> number): Instance
	local orangeSlice = MissionImages.PIECES.BAR_ORANGE.slice :: { number }
	local track, orange, green =
		MissionImages.PIECES.BAR_TRACK, MissionImages.PIECES.BAR_ORANGE, MissionImages.PIECES.BAR_GREEN
	if not hasArt(track) then
		return Rustic.bar({ Size = UDim2.new(1, 0, 0, 10), fraction = fraction })
	end
	return art(track, {
		Size = UDim2.new(1, 0, 0, 12),
		create("Frame")({
			Name = "Fill",
			Position = UDim2.fromScale(0.03, 0.18),
			Size = function()
				return UDim2.fromScale(0.94 * math.clamp(fraction(), 0, 1), 0.64)
			end,
			BackgroundTransparency = 1,
			Visible = function()
				return fraction() > 0
			end,
			create("ImageLabel")({
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = function()
					return if fraction() >= 1 then green.image else orange.image
				end,
				ScaleType = Enum.ScaleType.Slice,
				SliceCenter = Rect.new(orangeSlice[1], orangeSlice[2], orangeSlice[3], orangeSlice[4]),
				SliceScale = 0.12,
			}),
		}),
	})
end

local function claimButton(onClaim: () -> ()): Instance
	return Rustic.button({
		Name = "Claim",
		AnchorPoint = Vector2.new(1, 0.5),
		-- O cartão pronto tem a fita verde na ponta direita.
		Position = UDim2.new(1, if hasArt(MissionImages.PIECES.CARD_DONE) then -RIBBON else -10, 0.5, 0),
		Size = UDim2.new(0.22, 0, 0, 40),
		kind = "ember",
		text = Strings.get("missions.claim"),
		maxSize = 19,
		-- O som toca quando o servidor confirma (MissionsState).
		Activated = onClaim,
	})
end

-- Imagem do ícone de um prêmio (o item usa o ItemIcon, à parte).
local function badgeImage(kind: string): string
	if kind == "ember" then
		return UiImages.COIN
	elseif kind == "spins" then
		return MissionImages.ICON.premio_giro_especial
	elseif kind == "kit" then
		return MissionImages.ICON.premio_uso_kit
	elseif kind == "score" or kind == "cosmetic" then
		return MissionImages.ICON.aba_conquistas
	end
	return ""
end

local BADGE_ICON = 30

-- Um prêmio: ícone + texto curto, lado a lado.
local function badge(item: () -> Badge, index: number): Instance
	return create("Frame")({
		Name = "Badge",
		LayoutOrder = index,
		Size = UDim2.fromOffset(0, BADGE_ICON),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 1,
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 3),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		create("ImageLabel")({
			Name = "Icon",
			LayoutOrder = 1,
			Size = UDim2.fromOffset(BADGE_ICON, BADGE_ICON),
			BackgroundTransparency = 1,
			ScaleType = Enum.ScaleType.Fit,
			Image = function()
				return badgeImage(item().kind)
			end,
			Visible = function()
				return badgeImage(item().kind) ~= ""
			end,
		}),
		vide.show(function()
			return item().kind == "item" and item().id ~= nil and Defs.Items[item().id :: string] ~= nil
		end, function()
			local holder = create("Frame")({
				Name = "Item",
				LayoutOrder = 1,
				Size = UDim2.fromOffset(BADGE_ICON + 6, BADGE_ICON + 6),
				BackgroundTransparency = 1,
			}) :: Frame
			ItemIcon({
				item = function()
					return { id = item().id :: string, count = 1 }
				end,
			}).Parent =
				holder
			return holder
		end),
		create("TextLabel")({
			Name = "Text",
			LayoutOrder = 2,
			Size = UDim2.fromOffset(0, BADGE_ICON),
			AutomaticSize = Enum.AutomaticSize.X,
			BackgroundTransparency = 1,
			FontFace = Theme.font.number,
			TextSize = 18,
			TextColor3 = R.charcoal,
			Text = function()
				return item().text
			end,
			Visible = function()
				return item().text ~= ""
			end,
		}),
	})
end

-- Os prêmios de um cartão, alinhados à direita.
local function badges(list: () -> { Badge }, beforeRibbon: () -> boolean): Instance
	return create("Frame")({
		Name = "Rewards",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = function()
			return UDim2.new(1, if beforeRibbon() then -RIBBON else -14, 0.5, 0)
		end,
		Size = UDim2.new(0.3, 0, 0, BADGE_ICON + 6),
		BackgroundTransparency = 1,
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			VerticalAlignment = Enum.VerticalAlignment.Center,
			Padding = UDim.new(0, 10),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		vide.indexes(list, badge),
	})
end

type CardView = {
	icon: () -> string,
	name: () -> string,
	detail: () -> string,
	badges: () -> { Badge },
	fraction: () -> number,
	state: () -> number,
	claim: () -> (),
}

-- Um cartão: fundo pelo estado, ícone, nome, detalhe, barra e prêmio/RESGATAR.
local function card(view: CardView, order: () -> number): Instance
	local P = MissionImages.PIECES
	local function background(): Piece
		local state = view.state()
		return if state == STATE_FAILED
			then P.CARD_FAILED
			elseif state == STATE_READY then P.CARD_DONE
			else P.CARD_ACTIVE
	end
	-- A arte do cartão e o quadradinho do ícone dela.
	local function cardArt(): (Piece, { number })
		local state = view.state()
		local key = if state == STATE_FAILED
			then "CARD_FAILED"
			elseif state == STATE_READY then "CARD_DONE"
			else "CARD_ACTIVE"
		return P[key], MissionImages.CARD_ICON[key]
	end
	return create("Frame")({
		Name = "Card",
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, CARD_HEIGHT),
		BackgroundColor3 = function()
			local state = view.state()
			return if state == STATE_FAILED then R.paperShadow else R.paperLight
		end,
		BackgroundTransparency = if hasArt(P.CARD_ACTIVE) then 1 else 0,
		-- Resgatada ou trancada fica apagada (camada de papel por cima; um
		-- CanvasGroup aqui dentro do Root, que já é CanvasGroup, não desenhava as imagens).
		create("Frame")({
			Name = "Dim",
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = R.paper,
			BackgroundTransparency = 0.45,
			BorderSizePixel = 0,
			ZIndex = 8,
			Visible = function()
				local state = view.state()
				return state == STATE_CLAIMED or state == STATE_LOCKED
			end,
			create("UICorner")({ CornerRadius = UDim.new(0, 10) }),
		}),
		create("Frame")({
			Name = "Content",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			if hasArt(P.CARD_ACTIVE)
				then create("ImageLabel")({
					Size = UDim2.fromScale(1, 1),
					BackgroundTransparency = 1,
					Image = function()
						return background().image
					end,
					ScaleType = Enum.ScaleType.Slice,
					SliceCenter = function()
						local s = background().slice :: { number }
						return Rect.new(s[1], s[2], s[3], s[4])
					end,
					-- Escala pela altura da própria arte (pronto/falhou têm 240 px, em
					-- andamento 258): assim a fita com o ✓/✗ não estica.
					SliceScale = function()
						return CARD_HEIGHT / background().size[2]
					end,
				})
				else create("UIStroke")({ Color = R.paperShadow, Thickness = 2 }),
			-- A fita (✓ pronto / ✗ falhou) por cima, inteira e na proporção da arte.
			create("ImageLabel")({
				Name = "Ribbon",
				AnchorPoint = Vector2.new(1, 0),
				Position = UDim2.fromScale(1, 0),
				Size = function()
					local cap = if view.state() == STATE_FAILED then P.CARD_FAILED_CAP else P.CARD_DONE_CAP
					return UDim2.fromOffset(math.round(CARD_HEIGHT * cap.size[1] / cap.size[2]), CARD_HEIGHT)
				end,
				BackgroundTransparency = 1,
				ScaleType = Enum.ScaleType.Stretch,
				ZIndex = 2,
				Image = function()
					local state = view.state()
					return if state == STATE_FAILED
						then P.CARD_FAILED_CAP.image
						elseif state == STATE_READY then P.CARD_DONE_CAP.image
						else ""
				end,
				Visible = function()
					local state = view.state()
					return hasArt(P.CARD_DONE) and (state == STATE_FAILED or state == STATE_READY)
				end,
			}),
			-- Em cima do quadradinho que a arte do cartão já tem (pelo estado).
			icon(view.icon, {
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = function()
					local piece, square = cardArt()
					local scale = CARD_HEIGHT / piece.size[2]
					if not hasArt(piece) then
						return UDim2.fromOffset(10 + CARD_HEIGHT * 0.36, CARD_HEIGHT / 2)
					end
					return UDim2.fromOffset(math.round(square[1] * scale), math.round(square[2] * scale))
				end,
				Size = function()
					local piece, square = cardArt()
					if not hasArt(piece) then
						return UDim2.fromOffset(CARD_HEIGHT * 0.72, CARD_HEIGHT * 0.72)
					end
					local side = math.round(square[3] * CARD_HEIGHT / piece.size[2] * 1.06) -- o ícone tem margem própria
					return UDim2.fromOffset(side, side)
				end,
			}),
			create("Frame")({
				Name = "Body",
				Position = UDim2.fromOffset(CARD_HEIGHT + 6, 6),
				Size = UDim2.new(0.56, -(CARD_HEIGHT + 6), 1, -12),
				BackgroundTransparency = 1,
				Rustic.label({
					Name = "Name",
					Size = UDim2.fromScale(1, 0.4),
					FontFace = Theme.font.number,
					Text = view.name,
					TextXAlignment = Enum.TextXAlignment.Left,
					dark = true,
					maxSize = 21,
				}),
				create("Frame")({
					Position = UDim2.fromScale(0, 0.45),
					Size = UDim2.fromScale(1, 0.18),
					BackgroundTransparency = 1,
					bar(view.fraction),
				}),
				Rustic.label({
					Name = "Detail",
					Position = UDim2.fromScale(0, 0.68),
					Size = UDim2.fromScale(1, 0.32),
					FontFace = Theme.font.label,
					Text = view.detail,
					TextXAlignment = Enum.TextXAlignment.Left,
					dark = true,
					maxSize = 15,
				}),
			}),
			create("Frame")({
				Name = "RewardArea",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Visible = function()
					return view.state() ~= STATE_READY
				end,
				badges(view.badges, function()
					return view.state() == STATE_FAILED and hasArt(P.CARD_FAILED)
				end),
			}),
		}),
		vide.show(function()
			return view.state() == STATE_READY
		end, function()
			return claimButton(view.claim)
		end),
	})
end

local function stateText(state: number): string?
	if state == STATE_FAILED then
		return Strings.get("missions.failed")
	elseif state == STATE_CLAIMED then
		return Strings.get("missions.claimed")
	elseif state == STATE_READY then
		return Strings.get("missions.done")
	end
	return nil
end

local function ruleText(quest: Defs.QuestDef): string
	local parts = {}
	for _, rule in quest.rules do
		table.insert(parts, Strings.get("missions.rule." .. rule.type))
	end
	return table.concat(parts, " · ")
end

-- Cartão da Partida (chrono quest).
local function questCard(item: () -> any, index: number): Instance
	local function def(): Defs.QuestDef
		return Defs.Quests[item().Id]
	end
	return card({
		icon = function()
			return def().icon
		end,
		name = function()
			return Strings.get(def().nameKey)
		end,
		detail = function()
			local c = item()
			return stateText(c.State)
				or `{Strings.format("missions.time_left", { time = MissionView.timeLeft(c.EndsAt - serverNow()) })} · {ruleText(
					def()
				)}`
		end,
		badges = function()
			return MissionView.questBadges(def())
		end,
		fraction = function()
			return MissionView.chronoFraction(item(), serverNow())
		end,
		state = function()
			return item().State
		end,
		claim = function()
			MissionsState.claim("match", item().Id)
		end,
	}, function()
		return index
	end)
end

-- Cartão de diária/semanal (ou a final, Id = "final").
local function periodCard(tab: Tab, item: () -> any, index: number): Instance
	local function isFinal(): boolean
		return item().Id == "final"
	end
	return card({
		icon = function()
			if isFinal() then
				return if tab == "daily" then "premio_uso_kit" else "premio_giro_especial"
			end
			return Defs.Missions[item().Id].icon
		end,
		name = function()
			local c = item()
			if isFinal() then
				return Strings.format("missions.final", { n = c.Target })
			end
			return MissionView.missionName(c.Id, c.Target)
		end,
		detail = function()
			local c = item()
			return stateText(c.State) or MissionView.progressText(c)
		end,
		badges = function()
			if isFinal() then
				local list = if tab == "daily" then { MissionConfig.DAILY_FINAL[1] } else MissionConfig.WEEKLY_FINAL
				return MissionView.rewardBadges(list, Defs)
			end
			return MissionView.rewardBadges(Defs.Missions[item().Id].rewards, Defs)
		end,
		fraction = function()
			local c = item()
			return if c.Target > 0 then c.Progress / c.Target else 0
		end,
		state = function()
			return item().State
		end,
		claim = function()
			MissionsState.claim(tab, item().Id)
		end,
	}, function()
		return if isFinal() then 100 else index
	end)
end

-- Cartão de conquista: o próximo nível (ou o último, quando todos resgatados).
local function achievementCard(item: () -> any, index: number): Instance
	local function def(): Defs.AchievementDef
		return Defs.Achievements[item().Id]
	end
	local function tier(): Defs.AchievementTier
		local a = item()
		return def().tiers[math.min(a.Claimed + 1, #def().tiers)]
	end
	return card({
		icon = function()
			return def().icon
		end,
		name = function()
			local a = item()
			local level = math.min(a.Claimed + 1, #def().tiers)
			return `{Strings.get(def().nameKey)} · {Strings.format("missions.level", { n = level })}`
		end,
		detail = function()
			local a = item()
			if a.Claimed >= #def().tiers then
				return Strings.get("missions.all_levels")
			end
			local target = tier().target
			return `{MissionView.achievementGoal(a.Id, target)} · {math.min(a.Progress, target)} / {target}`
		end,
		badges = function()
			local a = item()
			if a.Claimed >= #def().tiers then
				return {}
			end
			return MissionView.rewardBadges(tier().rewards, Defs)
		end,
		fraction = function()
			local a = item()
			if a.Claimed >= #def().tiers then
				return 1
			end
			return a.Progress / tier().target
		end,
		state = function()
			local a = item()
			if a.Ready then
				return STATE_READY
			elseif a.Claimed >= #def().tiers then
				return STATE_CLAIMED
			end
			return 0
		end,
		claim = function()
			MissionsState.claim("achievements", item().Id)
		end,
	}, function()
		return index
	end)
end

local function listOf(tab: Tab): () -> { any }
	return function()
		local data = MissionsState.data()
		if data == nil or data.Creative then
			return {}
		end
		if tab == "match" then
			return data.Chrono
		elseif tab == "daily" then
			local list = table.clone(data.Daily)
			if #list > 0 then
				table.insert(list, data.DailyFinal)
			end
			return list
		elseif tab == "weekly" then
			local list = table.clone(data.Weekly)
			if #list > 0 then
				table.insert(list, data.WeeklyFinal)
			end
			return list
		end
		return data.Achievements
	end
end

local TAB_ICON: { [Tab]: string } = {
	match = "aba_partida",
	daily = "aba_diarias",
	weekly = "aba_semanais",
	achievements = "aba_conquistas",
}

local function tabButton(tab: Tab, order: number): Instance
	local P = MissionImages.PIECES
	local function active(): boolean
		return MissionsState.tab() == tab
	end
	local button = create("TextButton")({
		Name = "Tab_" .. tab,
		LayoutOrder = order,
		Size = UDim2.new(0.25, -6, 1, 0),
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = function()
			return if active() then R.ember else R.leather
		end,
		BackgroundTransparency = if hasArt(P.TAB) then 1 else 0,
		Activated = function()
			SoundPlayer.play("ui_tab")
			MissionsState.tab(tab)
		end,
		create("UICorner")({ CornerRadius = UDim.new(0, 8) }),
		if hasArt(P.TAB)
			then create("ImageLabel")({
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Image = function()
					return if active() then P.TAB_ON.image else P.TAB.image
				end,
				-- Só a parte de cima da arte (sem a tábua), esticada inteira: o 9
				-- partes com escala fracionária deformava as pontas.
				ImageRectOffset = Vector2.zero,
				ImageRectSize = function()
					local piece = if active() then P.TAB_ON else P.TAB
					return Vector2.new(piece.size[1], MissionImages.TAB_TOP)
				end,
				ScaleType = Enum.ScaleType.Stretch,
			})
			else create("UIStroke")({ Color = R.outline, Thickness = 2 }),
		icon(TAB_ICON[tab], {
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, 6, 0.5, 0),
			Size = UDim2.fromScale(0.74, 0.74),
			SizeConstraint = Enum.SizeConstraint.RelativeYY,
		}),
		Rustic.label({
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.new(0, TAB_HEIGHT, 0.5, 0),
			Size = UDim2.new(1, -(TAB_HEIGHT + 6), 0.6, 0),
			FontFace = Theme.font.number,
			Text = Strings.get("missions.tab." .. tab),
			TextXAlignment = Enum.TextXAlignment.Left,
			TextColor3 = function()
				return if active() then R.outline else R.cream
			end,
			maxSize = 16,
		}),
		dot(function()
			return (MissionsState.badges() :: any)[tab]
		end),
	})
	return button
end

local function list(): Instance
	local function rows(tab: Tab, build: (item: () -> any, index: number) -> Instance): Instance
		return create("Frame")({
			Name = "Rows_" .. tab,
			Size = UDim2.fromScale(1, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			BackgroundTransparency = 1,
			Visible = function()
				return MissionsState.tab() == tab
			end,
			create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 6) }),
			vide.indexes(listOf(tab), build),
		})
	end
	return create("ScrollingFrame")({
		Name = "List",
		Position = UDim2.fromOffset(0, TAB_HEIGHT + HEADER_HEIGHT + 10),
		Size = UDim2.new(1, 0, 1, -(TAB_HEIGHT + HEADER_HEIGHT + 10)),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollBarThickness = 6,
		ScrollBarImageColor3 = R.woodLight,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		create("UIListLayout")({ SortOrder = Enum.SortOrder.LayoutOrder }),
		create("UIPadding")({ PaddingRight = UDim.new(0, 8) }),
		rows("match", questCard),
		rows("daily", function(item, index)
			return periodCard("daily", item, index)
		end),
		rows("weekly", function(item, index)
			return periodCard("weekly", item, index)
		end),
		rows("achievements", achievementCard),
	})
end

local function close()
	MissionsState.open(false)
end

local function window(): Instance
	local P = MissionImages.PIECES
	local windowHeight = vide.source(400)
	local tabs: { Instance } = {
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Horizontal,
			Padding = UDim.new(0, 6),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
	}
	for order, tab in MissionView.TABS do
		table.insert(tabs, tabButton(tab :: any, order))
	end
	local body: { any } = {
		create("UISizeConstraint")({ MaxSize = PANEL_MAX }),
		-- Segura o toque dentro da janela (senão ele passa para o "Outside"
		-- atrás e fecha a janela).
		create("TextButton")({
			Name = "Blocker",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			AutoButtonColor = false,
			ZIndex = 0,
		}),
		Rustic.plate({
			Name = "TitlePlate",
			AnchorPoint = Vector2.new(0.5, 0.5),
			Position = UDim2.fromScale(0.5, 0),
			Size = UDim2.new(0.5, 0, 0, TITLE_HEIGHT),
			ZIndex = 3,
			Rustic.label({
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.fromScale(0.86, 0.6),
				FontFace = Theme.font.title,
				Text = Strings.get("missions.title"),
				maxSize = 28,
				ZIndex = 4,
				create("UIStroke")({ Color = R.outline, Thickness = 2 }),
			}),
		}),
		Rustic.button({
			Name = "Close",
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, -8, 0, 8),
			Size = UDim2.fromOffset(34, 34),
			kind = "leather",
			text = "X",
			maxSize = 18,
			ZIndex = 5,
			Activated = close,
		}),
		create("Frame")({
			Name = "Inner",
			-- Com a arte: dentro da moldura (a madeira mede ~160 px dos lados e
			-- ~110 em cima/embaixo na arte; a escala acompanha a altura).
			Position = function()
				if not hasArt(P.WINDOW) then
					return UDim2.fromOffset(14, TITLE_HEIGHT / 2 + 8)
				end
				local scale = windowHeight() * WINDOW_SLICE_FACTOR / P.WINDOW.size[2]
				return UDim2.fromOffset(math.round(150 * scale) + 4, math.round(100 * scale) + 4)
			end,
			Size = function()
				if not hasArt(P.WINDOW) then
					return UDim2.new(1, -28, 1, -(TITLE_HEIGHT / 2 + 22))
				end
				local scale = windowHeight() * WINDOW_SLICE_FACTOR / P.WINDOW.size[2]
				return UDim2.new(1, -2 * (math.round(150 * scale) + 4), 1, -(math.round(210 * scale) + 8))
			end,
			BackgroundTransparency = 1,
			create("Frame")({
				Name = "Tabs",
				Size = UDim2.new(1, 0, 0, TAB_HEIGHT),
				BackgroundTransparency = 1,
				tabs,
			}),
			Rustic.label({
				Name = "Header",
				Position = UDim2.fromOffset(4, TAB_HEIGHT + 4),
				Size = UDim2.new(1, -8, 0, HEADER_HEIGHT),
				FontFace = Theme.font.body,
				Text = function()
					local tab = MissionsState.tab()
					return MissionView.tabHeader(
						tab :: any,
						MissionsState.data(),
						if tab == "match" then serverNow() else unixNow()
					)
				end,
				TextXAlignment = Enum.TextXAlignment.Left,
				dark = hasArt(P.WINDOW),
				maxSize = 14,
			}),
			list(),
		}),
	}
	local props = {
		Name = "Window",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, TITLE_HEIGHT / 4),
		Size = UDim2.new(0.94, 0, 0.88, -TITLE_HEIGHT / 2),
		Active = true, -- toque dentro da janela não fecha
		body,
	}
	if hasArt(P.WINDOW) then
		local frame = art(P.WINDOW, props, WINDOW_SLICE_FACTOR)
		local function measure()
			windowHeight(frame.AbsoluteSize.Y)
		end
		frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(measure)
		measure()
		return frame
	end
	props.BackgroundColor3 = R.charcoal
	props.BorderSizePixel = 0
	table.insert(body, create("UICorner")({ CornerRadius = UDim.new(0, 12) }))
	table.insert(body, create("UIStroke")({ Color = R.woodShadow, Thickness = 4 }))
	return create("Frame")(props)
end

-- Monta a janela (dentro do root Vide do ScreenController). O ScreenController
-- liga e desliga pelo Template.show (fade no CanvasGroup "Root").
function MissionsScreen.mount(playerGui: Instance): ScreenGui?
	MissionsState.start()
	-- Aberta, o servidor manda cada mudança; fechada, só o que muda as bolinhas.
	local watched: boolean? = nil
	vide.effect(function()
		local open = MissionsState.open()
		if open ~= watched then
			watched = open
			MissionsState.watch(open)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(1)
			unixNow(math.floor(Workspace:GetServerTimeNow()))
			serverNow(Workspace:GetServerTimeNow())
		end
	end)
	local gui = create("ScreenGui")({
		Name = "Missions",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 20, -- acima do menu e da HUD
		IgnoreGuiInset = false,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		create("CanvasGroup")({
			Name = "Root",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			-- Fundo invisível: tocar fora da janela fecha.
			create("TextButton")({
				Name = "Outside",
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = "",
				AutoButtonColor = false,
				Activated = close,
			}),
			window(),
		}),
	}) :: ScreenGui
	Template.bindUiScale(gui)
	gui.Parent = playerGui
	return gui
end

return MissionsScreen
