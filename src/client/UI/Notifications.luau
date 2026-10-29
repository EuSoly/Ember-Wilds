--!strict
-- Avisos curtos no lado direito da tela ("A noite está chegando" etc.).
-- No máximo 2 ao mesmo tempo; cada um some sozinho em 3 s.
-- Qualquer parte do cliente pode chamar Notifications.push("chave.do.texto").
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local create = vide.create

local MAX_VISIBLE = 2
local LIFETIME = 3 -- segundos
local SLIDE_TIME = 0.2

-- Avisos visíveis: id → texto. O id cresce sempre, então também serve de ordem.
local visible = vide.source({} :: { [number]: string })
local nextId = 0

local Notifications = {}

local function remove(id: number)
	local current = table.clone(vide.untrack(visible))
	current[id] = nil
	visible(current)
end

function Notifications.push(textKey: string)
	nextId += 1
	local id = nextId
	-- untrack: se push for chamado de dentro de um efeito, ler a lista não pode
	-- fazer esse efeito depender dela (senão cada aviso dispara o efeito de novo).
	local current = table.clone(vide.untrack(visible))
	current[id] = Strings.get(textKey)

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

local function Toast(text: () -> string, id: number): Frame
	-- Entra deslizando da direita: começa fora e a mola traz para o lugar.
	local offset = vide.source(1.2)
	local x = vide.spring(offset, SLIDE_TIME * 2)
	task.defer(function()
		offset(0)
	end)

	return Kit.panel({
		Name = `Toast{id}`,
		LayoutOrder = id,
		BackgroundColor3 = Theme.ui.warning,
		BackgroundTransparency = 0,
		Size = UDim2.fromScale(1, 0.45),
		Position = function()
			return UDim2.fromScale(x(), 0)
		end,
		Kit.text({
			Size = UDim2.fromScale(0.9, 0.6),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			TextColor3 = Theme.ui.panel,
			Text = text,
			maxSize = 22,
		}),
	})
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
