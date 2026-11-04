--!strict
-- Configurações (estilo rústico): janela por cima do menu (que fica escurecido
-- atrás) e do jogo. Abre pelo botão do menu e pela engrenagem da HUD; fecha no
-- Fechar ou tocando fora da janela.
--
-- As linhas saem de Defs.Settings, separadas em grupos (Som, Tela, Controles:
-- SettingsFormat.grouped). Configuração nova num update aparece sozinha:
--   number  → barrinha de arrastar (de 5 em 5%);
--   boolean → chave liga/desliga;
--   choice  → setas ◀ ▶ trocando a opção.
--
-- Cada mudança é um pedido ao servidor (Net.SetSetting, ele valida); o valor
-- mostrado é o do atributo Setting_<id> do Player (fonte da verdade), menos
-- enquanto o dedo arrasta a barrinha (aí mostra onde o dedo está). Os volumes
-- mudam enquanto arrasta (dá para ouvir); o tamanho da interface só ao soltar
-- (senão a tela mudaria de tamanho embaixo do dedo).
-- "quality" e "left_handed" só são salvos por enquanto (spec F5, seção 7).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local SettingsFormat = require(Shared:WaitForChild("UIFlow"):WaitForChild("SettingsFormat"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local Template = require(Client:WaitForChild("UITemplates"):WaitForChild("Template"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local Rustic = require(Client:WaitForChild("UI"):WaitForChild("Rustic"))

local create = vide.create
local R = Theme.rustic

type SettingDef = Defs.SettingDef

local PANEL_MAX = Vector2.new(560, 600)
local HEADER_HEIGHT = 30
local ROW_HEIGHT = 50
local TITLE_HEIGHT = 58
local CLOSE_HEIGHT = 50
local SEND_EVERY = 0.15 -- s entre pedidos enquanto arrasta um volume
local PENDING_TIMEOUT = 1.5 -- s esperando o servidor confirmar o valor solto
local APPLY_ON_RELEASE: { [string]: boolean } = { ui_scale = true }

local BODY = Color3.fromHex("#2B2018")
local ROW = Color3.fromHex("#3A2B20")
local TRACK = Color3.fromHex("#1A130D")
local OFF = Color3.fromHex("#5C5148")

local SettingsScreen = {}

-- Janela aberta? Quem abre: botão do menu e engrenagem da HUD. Quem fecha:
-- Fechar, tocar fora, ou o ScreenController quando o estado de tela não permite.
SettingsScreen.open = vide.source(false)

function SettingsScreen.toggle()
	SettingsScreen.open(not vide.untrack(SettingsScreen.open))
end

local function send(def: SettingDef, value: number | boolean | string)
	if def.kind == "number" and type(value) == "number" then
		Net.SetSetting.Fire({ Id = def.id, Number = value })
	elseif def.kind == "boolean" and type(value) == "boolean" then
		Net.SetSetting.Fire({ Id = def.id, Flag = value })
	elseif def.kind == "choice" and type(value) == "string" then
		Net.SetSetting.Fire({ Id = def.id, Choice = value })
	end
end

local function round(radius: number): Instance
	return create("UICorner")({ CornerRadius = UDim.new(radius, 0) })
end

local function stroke(thickness: number): Instance
	return create("UIStroke")({
		Color = R.outline,
		Thickness = thickness,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function valueLabel(text: () -> string): TextLabel
	return Rustic.label({
		Name = "ValueLabel",
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.fromScale(1, 0.5),
		Size = UDim2.new(0.2, 0, 0, 26),
		FontFace = Theme.font.number,
		TextColor3 = R.emberLight,
		TextXAlignment = Enum.TextXAlignment.Right,
		Text = text,
		maxSize = 20,
	})
end

-- Área do controle: entre o nome (esquerda) e o valor (direita).
local CONTROL_POSITION = UDim2.fromScale(0.4, 0.5)
local CONTROL_SIZE = UDim2.fromScale(0.38, 1)

-- Barrinha de arrastar (configurações "number").
local function slider(def: SettingDef, value: () -> any): { Instance }
	-- Valor onde o dedo está (arrastando) ou o que acabou de soltar, até o
	-- servidor confirmar. nil = mostra o atributo.
	local held: (() -> number?) & ((number?) -> number?) = vide.source(nil :: number?) :: any
	local activeInput: InputObject? = nil
	local lastSent = 0
	local releaseToken = 0

	local function shown(): number
		local dragged = held()
		if dragged ~= nil then
			return dragged
		end
		local current = value()
		return if type(current) == "number" then current else def.default :: number
	end
	local function fraction(): number
		return SettingsFormat.fraction(def, shown())
	end

	local hit = create("TextButton")({
		Name = "Slider",
		AnchorPoint = Vector2.new(0, 0.5),
		Position = CONTROL_POSITION,
		Size = CONTROL_SIZE,
		Text = "",
		AutoButtonColor = false,
		BackgroundTransparency = 1,
		create("Frame")({
			Name = "Track",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = UDim2.fromScale(0, 0.5),
			Size = UDim2.new(1, 0, 0, 12),
			BackgroundColor3 = TRACK,
			BorderSizePixel = 0,
			round(1),
			stroke(2),
			create("Frame")({
				Name = "Fill",
				Size = function()
					return UDim2.fromScale(fraction(), 1)
				end,
				BackgroundColor3 = Color3.new(1, 1, 1),
				BorderSizePixel = 0,
				round(1),
				create("UIGradient")({
					Rotation = 90,
					Color = ColorSequence.new(R.emberLight, R.ember),
				}),
			}),
			create("Frame")({
				Name = "Knob",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = function()
					return UDim2.fromScale(fraction(), 0.5)
				end,
				Size = UDim2.fromOffset(24, 24),
				BackgroundColor3 = R.cream,
				BorderSizePixel = 0,
				ZIndex = 2,
				round(1),
				stroke(2),
			}),
		}),
	}) :: TextButton

	local function valueAt(x: number): number
		local width = hit.AbsoluteSize.X
		if width <= 0 then
			return shown()
		end
		return SettingsFormat.fromFraction(def, (x - hit.AbsolutePosition.X) / width)
	end

	local function move(x: number)
		local v = valueAt(x)
		held(v)
		local now = os.clock()
		if not APPLY_ON_RELEASE[def.id] and now - lastSent >= SEND_EVERY and v ~= value() then
			lastSent = now
			send(def, v)
		end
	end

	local function release()
		activeInput = nil
		local v = vide.untrack(held)
		if v == nil then
			return
		end
		if v == vide.untrack(value) then
			held(nil)
			return
		end
		send(def, v)
		-- Segura o valor solto até o atributo chegar (senão a bolinha pularia
		-- de volta por um instante); se o servidor recusar, volta sozinho.
		releaseToken += 1
		local token = releaseToken
		task.delay(PENDING_TIMEOUT, function()
			if releaseToken == token and activeInput == nil then
				held(nil)
			end
		end)
	end

	-- O atributo chegou igual ao valor solto: volta a mostrar o atributo.
	vide.effect(function()
		local current = value()
		if activeInput == nil and vide.untrack(held) == current then
			held(nil)
		end
	end)

	hit.InputBegan:Connect(function(input: InputObject)
		local kind = input.UserInputType
		if kind == Enum.UserInputType.MouseButton1 or kind == Enum.UserInputType.Touch then
			activeInput = input
			releaseToken += 1
			move(input.Position.X)
		end
	end)
	local changed = UserInputService.InputChanged:Connect(function(input: InputObject)
		local active = activeInput
		if active == nil then
			return
		end
		local mouseDrag = active.UserInputType == Enum.UserInputType.MouseButton1
			and input.UserInputType == Enum.UserInputType.MouseMovement
		if input == active or mouseDrag then
			move(input.Position.X)
		end
	end)
	local ended = UserInputService.InputEnded:Connect(function(input: InputObject)
		local active = activeInput
		if active ~= nil and (input == active or input.UserInputType == active.UserInputType) then
			release()
		end
	end)
	vide.cleanup(function()
		changed:Disconnect()
		ended:Disconnect()
	end)

	return {
		hit,
		valueLabel(function()
			return SettingsFormat.display(def, shown(), Strings.get)
		end),
	}
end

-- Chave liga/desliga (configurações "boolean").
local function toggle(def: SettingDef, value: () -> any): { Instance }
	local function on(): boolean
		return value() == true
	end
	return {
		create("TextButton")({
			Name = "ToggleButton",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = CONTROL_POSITION,
			Size = UDim2.fromOffset(64, 32),
			Text = "",
			AutoButtonColor = false,
			BackgroundColor3 = function()
				return if on() then R.success else OFF
			end,
			BorderSizePixel = 0,
			round(1),
			stroke(2),
			create("Frame")({
				Name = "Knob",
				AnchorPoint = function()
					return if on() then Vector2.new(1, 0.5) else Vector2.new(0, 0.5)
				end,
				Position = function()
					return if on() then UDim2.new(1, -4, 0.5, 0) else UDim2.new(0, 4, 0.5, 0)
				end,
				Size = UDim2.fromOffset(24, 24),
				BackgroundColor3 = R.cream,
				BorderSizePixel = 0,
				round(1),
				stroke(2),
			}),
			Activated = function()
				send(def, not on())
			end,
		}),
		valueLabel(function()
			return SettingsFormat.display(def, value(), Strings.get)
		end),
	}
end

-- Setas trocando a opção (configurações "choice"); o nome da opção no meio.
local function choice(def: SettingDef, value: () -> any): { Instance }
	local function cycle(direction: number)
		local current = vide.untrack(value)
		if type(current) == "string" then
			send(def, SettingsFormat.cycle(def, current, direction))
		end
	end
	local function arrow(name: string, text: string, anchor: number, direction: number): Instance
		return Rustic.button({
			Name = name,
			AnchorPoint = Vector2.new(anchor, 0.5),
			Position = UDim2.fromScale(anchor, 0.5),
			Size = UDim2.fromOffset(40, 36),
			kind = "leather",
			text = text,
			maxSize = 18,
			Activated = function()
				cycle(direction)
			end,
		})
	end
	return {
		create("Frame")({
			Name = "Choice",
			AnchorPoint = Vector2.new(0, 0.5),
			Position = CONTROL_POSITION,
			Size = UDim2.fromScale(0.6, 1),
			BackgroundTransparency = 1,
			arrow("PrevButton", "<", 0, -1),
			Rustic.label({
				Name = "ValueLabel",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.fromScale(0.5, 0.5),
				Size = UDim2.new(1, -96, 0, 26),
				FontFace = Theme.font.number,
				TextColor3 = R.emberLight,
				Text = function()
					return SettingsFormat.display(def, value(), Strings.get)
				end,
				maxSize = 20,
			}),
			arrow("NextButton", ">", 1, 1),
		}),
	}
end

local CONTROLS = {
	number = slider,
	boolean = toggle,
	choice = choice,
}

local function row(def: SettingDef, order: number): Frame
	local value = Sources.attribute(Players.LocalPlayer, StatNames.SettingPrefix .. def.id, def.default)
	local controls = CONTROLS[def.kind](def, value)
	return create("Frame")({
		Name = def.id,
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
			Size = UDim2.new(0.37, 0, 0, 24),
			TextXAlignment = Enum.TextXAlignment.Left,
			Text = Strings.get(def.nameKey),
			maxSize = 20,
		}),
		controls,
	}) :: Frame
end

local function groupHeader(id: string, order: number): TextLabel
	return Rustic.label({
		Name = "Group_" .. id,
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, HEADER_HEIGHT),
		FontFace = Theme.font.title,
		TextColor3 = R.emberLight,
		TextXAlignment = Enum.TextXAlignment.Left,
		Text = string.upper(Strings.get(`setting.group.{id}`)),
		maxSize = 22,
		create("UIStroke")({ Color = R.outline, Thickness = 2 }),
	})
end

local function rows(): { Instance }
	local list: { Instance } = {}
	local order = 0
	for _, group in SettingsFormat.grouped(Defs.Settings) do
		order += 1
		table.insert(list, groupHeader(group.id, order))
		for _, def in group.settings do
			order += 1
			table.insert(list, row(def, order))
		end
	end
	return list
end

local function close()
	SettingsScreen.open(false)
end

-- Monta a janela (dentro do root Vide do ScreenController). O ScreenController
-- liga e desliga pelo Template.show (fade no CanvasGroup "Root").
function SettingsScreen.mount(playerGui: Instance): ScreenGui?
	local gui = create("ScreenGui")({
		Name = "Settings",
		ResetOnSpawn = false,
		Enabled = false,
		DisplayOrder = 20, -- acima do menu e da HUD
		IgnoreGuiInset = true,
		ScreenInsets = Enum.ScreenInsets.None,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		create("CanvasGroup")({
			Name = "Root",
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			-- Fundo escuro: o menu (ou o jogo) aparece atrás; tocar aqui fecha.
			create("TextButton")({
				Name = "Dim",
				Size = UDim2.fromScale(1, 1),
				Text = "",
				AutoButtonColor = false,
				BackgroundColor3 = Color3.new(0, 0, 0),
				BackgroundTransparency = 0.45,
				Activated = close,
			}),
			create("Frame")({
				Name = "Window",
				AnchorPoint = Vector2.new(0.5, 0.5),
				Position = UDim2.new(0.5, 0, 0.5, TITLE_HEIGHT / 4),
				Size = UDim2.new(0.92, 0, 0.86, -TITLE_HEIGHT / 2),
				BackgroundColor3 = BODY,
				BorderSizePixel = 0,
				Active = true, -- toque dentro da janela não chega no fundo
				create("UISizeConstraint")({ MaxSize = PANEL_MAX }),
				create("UICorner")({ CornerRadius = UDim.new(0, 12) }),
				create("UIStroke")({
					Color = R.woodShadow,
					Thickness = 4,
					ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
				}),
				-- Placa com o título, pregada no alto da janela.
				Rustic.plate({
					Name = "TitlePlate",
					AnchorPoint = Vector2.new(0.5, 0.5),
					Position = UDim2.fromScale(0.5, 0),
					Size = UDim2.new(0.62, 0, 0, TITLE_HEIGHT),
					ZIndex = 3,
					Rustic.label({
						Name = "Title",
						AnchorPoint = Vector2.new(0.5, 0.5),
						Position = UDim2.fromScale(0.5, 0.5),
						Size = UDim2.fromScale(0.86, 0.6),
						FontFace = Theme.font.title,
						Text = Strings.get("settings.title"),
						maxSize = 32,
						ZIndex = 4,
						create("UIStroke")({ Color = R.outline, Thickness = 2 }),
					}),
				}),
				create("ScrollingFrame")({
					Name = "List",
					Position = UDim2.fromOffset(16, TITLE_HEIGHT / 2 + 10),
					Size = UDim2.new(1, -32, 1, -(TITLE_HEIGHT / 2 + 10 + CLOSE_HEIGHT + 28)),
					BackgroundTransparency = 1,
					BorderSizePixel = 0,
					AutomaticCanvasSize = Enum.AutomaticSize.Y,
					CanvasSize = UDim2.new(),
					ScrollBarThickness = 6,
					ScrollBarImageColor3 = R.woodLight,
					ScrollingDirection = Enum.ScrollingDirection.Y,
					create("UIListLayout")({
						SortOrder = Enum.SortOrder.LayoutOrder,
						Padding = UDim.new(0, 6),
					}),
					create("UIPadding")({ PaddingRight = UDim.new(0, 8) }),
					rows(),
				}),
				Rustic.button({
					Name = "CloseButton",
					AnchorPoint = Vector2.new(0.5, 1),
					Position = UDim2.new(0.5, 0, 1, -14),
					Size = UDim2.fromOffset(200, CLOSE_HEIGHT),
					kind = "ember",
					text = Strings.get("settings.close"),
					maxSize = 24,
					Activated = close,
				}),
			}),
		}),
	}) :: ScreenGui
	Template.bindUiScale(gui)
	gui.Parent = playerGui
	return gui
end

return SettingsScreen
