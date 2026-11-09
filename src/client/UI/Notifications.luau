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

local create = vide.create

local MAX_VISIBLE = 2
local LIFETIME = 3 -- segundos
local SLIDE_TIME = 0.2

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
		Kit.text({
			Size = UDim2.fromScale(0.82, 0.5),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			-- Texto escuro no creme e no laranja; claro no verde.
			TextColor3 = if kind == "success" then Theme.rustic.cream else Theme.rustic.charcoal,
			Text = function()
				return entry().text
			end,
			maxSize = 22,
			ZIndex = 2,
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
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.fromScale(0.98, 0.3),
		Size = UDim2.fromScale(0.26, 0.16),
		BackgroundTransparency = 1,
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Right,
			Padding = UDim.new(0.05, 0),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		vide.indexes(visible, function(text, id)
			return Toast(text, id)
		end),
	}) :: Frame
end

return Notifications
