--!strict
-- Avisos curtos no lado direito da tela ("A noite está chegando" etc.).
-- No máximo 2 ao mesmo tempo; cada um some sozinho em 3 s.
-- Qualquer parte do cliente pode chamar Notifications.push("chave.do.texto"),
-- ou com valores no texto: Notifications.push("gather.needTool", { item = "..." }).
-- O 3º argumento é o tipo, que escolhe a faixa (HudImages.TOAST): "info"
-- (creme, padrão), "alert" (laranja: noite chegando, borda do mapa) ou
-- "success" (verde).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Strings = require(Shared:WaitForChild("Strings"))
local HudImages = require(Shared:WaitForChild("HudImages"))
local Theme = require(Shared:WaitForChild("Theme"))
local HudArt = require(script.Parent:WaitForChild("HudArt"))
local Kit = require(script.Parent:WaitForChild("Kit"))
local Rustic = require(script.Parent:WaitForChild("Rustic"))
local HudColumnState = require(script.Parent:WaitForChild("HudColumnState"))
local SoundPlayer = require(script.Parent.Parent:WaitForChild("Audio"):WaitForChild("SoundPlayer"))

local create = vide.create

local MAX_VISIBLE = 2
local LIFETIME = 3 -- segundos
local SLIDE_TIME = 0.2
-- Tela baixa: área dos avisos em px (cada aviso tem 45% dela: ~45 px).
local SHORT_HEIGHT = 100
local SHORT_MIN_WIDTH = 220

export type Kind = "info" | "alert" | "success"
type Entry = { text: string, kind: Kind }

local TOAST_CORNER = 22 -- px lógicos das pontas da faixa

-- Avisos visíveis: id → texto e tipo. O id cresce sempre, então também serve de ordem.
local visible = vide.source({} :: { [number]: Entry })
local nextId = 0

local Notifications = {}

local function remove(id: number)
	local current = table.clone(vide.untrack(visible))
	current[id] = nil
	visible(current)
end

function Notifications.push(textKey: string, vars: { [string]: string | number }?, kind: Kind?)
	nextId += 1
	local id = nextId
	-- Som do aviso pelo tipo (notify_info, notify_alert, notify_success).
	SoundPlayer.play("notify_" .. (kind or "info"))
	-- untrack: se push for chamado de dentro de um efeito, ler a lista não pode
	-- fazer esse efeito depender dela (senão cada aviso dispara o efeito de novo).
	local current = table.clone(vide.untrack(visible))
	current[id] = {
		text = if vars then Strings.format(textKey, vars) else Strings.get(textKey),
		kind = kind or "info",
	}

	-- Passou do limite: sai o mais antigo.
	local ids = {}
	for existing in current do
		table.insert(ids, existing)
	end
	table.sort(ids)
	while #ids > MAX_VISIBLE do
		current[table.remove(ids, 1) :: number] = nil
	end

	visible(current)
	task.delay(LIFETIME, remove, id)
end

local function Toast(entry: () -> Entry, id: number): Frame
	-- Entra deslizando da direita: começa fora e a mola traz para o lugar.
	local offset = vide.source(1.2)
	local x = vide.spring(offset, SLIDE_TIME * 2)
	task.defer(function()
		offset(0)
	end)
	local kind = vide.untrack(entry).kind
	local art = HudArt.sliced("toast", HudImages.TOAST[kind] or "", TOAST_CORNER)
	local props: { [any]: any } = {
		Name = `Toast{id}`,
		LayoutOrder = id,
		Size = UDim2.fromScale(1, 0.45),
		Position = function()
			return UDim2.fromScale(x(), 0)
		end,
		-- Rustic.label, sem o contorno grosso do Kit.text: texto escuro com
		-- contorno escuro sobre o creme embolava as letras (visto em 10/11/2026).
		-- No verde, texto claro com um contorno fino para destacar.
		Rustic.label({
			Size = UDim2.fromScale(0.82, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			FontFace = Theme.font.number,
			dark = kind ~= "success",
			Text = function()
				return entry().text
			end,
			maxSize = 22,
			ZIndex = 2,
			if kind == "success" then create("UIStroke")({ Color = Theme.rustic.outline, Thickness = 1 }) else nil,
		}),
	}
	if art then
		table.insert(props, art)
		return vide.apply(create("Frame")({ BackgroundTransparency = 1, BorderSizePixel = 0 }))(props) :: Frame
	end
	props.BackgroundColor3 = Theme.ui.warning
	props.BackgroundTransparency = 0
	return Kit.panel(props)
end

function Notifications.Component(): Frame
	return create("Frame")({
		Name = "Notifications",
		-- Abaixo dos botões redondos; com o quadrinho do tutorial ou a receita
		-- fixada, abaixo deles (UI/HudColumnState). Na tela baixa, à esquerda,
		-- com altura mínima: a fração dava avisos de 23 px (12/11/2026).
		AnchorPoint = HudColumnState.anchor,
		Position = function()
			return UDim2.fromScale(HudColumnState.x(), HudColumnState.column().notificationsY)
		end,
		Size = function()
			return if HudColumnState.left() then UDim2.new(0.26, 0, 0, SHORT_HEIGHT) else UDim2.fromScale(0.26, 0.16)
		end,
		BackgroundTransparency = 1,
		create("UISizeConstraint")({ MinSize = Vector2.new(SHORT_MIN_WIDTH, 0) }),
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = function()
				return if HudColumnState.left() then Enum.HorizontalAlignment.Left else Enum.HorizontalAlignment.Right
			end,
			Padding = UDim.new(0.05, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		vide.indexes(visible, function(text, id)
			return Toast(text, id)
		end),
	}) :: Frame
end

return Notifications
