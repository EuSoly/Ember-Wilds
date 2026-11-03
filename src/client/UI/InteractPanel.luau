--!strict
-- Painel de interação com estruturas (G8): aparece acima da hotbar só enquanto
-- há uma peça de usar de perto (extrator, fornalha, poço, cama, placa) e mostra
-- o nome dela, o estado (madeira, estoque, goles: só o que a peça tem) e um
-- botão por ação. Fica empilhado em cima dos painéis do baú e da caixa quando
-- eles estão visíveis, sem sobrepor. Só pede: quem decide é o servidor.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local InteractRules = require(Shared:WaitForChild("Build"):WaitForChild("InteractRules"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local ChestState = require(script.Parent.Parent:WaitForChild("ChestState"))
local CrateState = require(script.Parent.Parent:WaitForChild("CrateState"))
local InteractState = require(script.Parent.Parent:WaitForChild("InteractState"))
local Kit = require(script.Parent:WaitForChild("Kit"))

local create = vide.create

local GAP = 6
local WIDTH = 2 * 120 + GAP -- px: cabe dois botões lado a lado
local BUTTON = Vector2.new(120, 44) -- px (altura = mínimo de toque)
local STACK_GAP = 12 -- px entre este painel e o de baixo
-- Mesmas medidas do ChestPanel (64 px) e do CratePanel (CELL, GAP, COLUMNS,
-- título de 20 px): a altura deles, para empilhar sem sobrepor.
local CHEST_HEIGHT = 64
local CRATE_CELL = 56
local CRATE_GAP = 6
local CRATE_COLUMNS = 8
local CRATE_TITLE = 20

-- Nome de cada número de ação (para o texto do botão: "interact.<nome>").
local ACTION_NAMES: { [number]: string } = {}
for name, number in InteractRules.ACTIONS :: { [string]: number } do
	ACTION_NAMES[number] = name
end

-- Altura do painel da caixa com `count` slots (padding + título + grade).
local function crateHeight(count: number): number
	local rows = math.ceil(count / CRATE_COLUMNS)
	local grid = if rows > 0 then rows * CRATE_CELL + (rows - 1) * CRATE_GAP else 0
	return CRATE_GAP + CRATE_TITLE + CRATE_GAP + grid + CRATE_GAP
end

-- Quanto subir para ficar em cima dos painéis do baú e da caixa visíveis.
local function stackOffset(): number
	local offset = 0
	if ChestState.near() ~= nil then
		offset += CHEST_HEIGHT + STACK_GAP
	end
	if CrateState.near() ~= nil then
		offset += crateHeight(#CrateState.contents()) + STACK_GAP
	end
	return offset
end

-- Texto do estado: só os atributos que a peça tem ("" = nenhum).
local function statusText(): string
	local status = InteractState.status()
	local parts: { string } = {}
	if status.wood ~= nil then
		table.insert(parts, Strings.format("interact.wood", { count = status.wood }))
	end
	if status.stock ~= nil then
		table.insert(parts, Strings.format("interact.stock", { count = status.stock }))
	end
	if status.drinks ~= nil then
		table.insert(parts, Strings.format("interact.drinks", { count = status.drinks }))
	end
	return table.concat(parts, "   ")
end

-- Botão da ação na posição `order`. `action` é reativo: ao trocar de peça o
-- botão da mesma posição é reaproveitado e passa a ser de outra ação.
local function ActionButton(action: () -> number, order: number): TextButton
	return create("TextButton")({
		Name = "Action",
		LayoutOrder = order,
		Size = UDim2.fromOffset(BUTTON.X, BUTTON.Y),
		Text = "",
		AutoButtonColor = true,
		BackgroundColor3 = Theme.ui.panel,
		BackgroundTransparency = Theme.panelTransparency,
		BorderSizePixel = 0,
		create("UICorner")({ CornerRadius = Theme.slotCorner }),
		create("UIStroke")({
			ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
			Color = Theme.ui.border,
			Thickness = Theme.strokeThickness,
		}),
		Activated = function()
			-- Tarefa 12: a ação "symbol" (placa) vira uma fileira de botões, um por
			-- símbolo (SignRules.SYMBOLS), cada um mandando o índice em Arg. Até lá,
			-- um botão só que manda o símbolo 1.
			local current = vide.untrack(action)
			InteractState.act(current, if current == InteractRules.ACTIONS.symbol then 1 else 0)
		end,
		Kit.text({
			Size = UDim2.fromScale(0.86, 0.6),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = function()
				return Strings.get("interact." .. (ACTION_NAMES[action()] or "?"))
			end,
			maxSize = 16,
		}),
	}) :: TextButton
end

local function InteractPanel(): Frame
	local kind = function(): string?
		local model = InteractState.near()
		return if model then InteractState.kindOf(model) else nil
	end
	local actions = function(): { number }
		local current = kind()
		return InteractRules.actionsFor(current or "")
	end
	return Kit.panel({
		Name = "InteractPanel",
		AnchorPoint = Vector2.new(0.5, 1),
		-- Na base do painel do baú; sobe a altura do baú e da caixa visíveis.
		Position = function()
			return UDim2.new(0.5, 0, 0.77, -stackOffset())
		end,
		AutomaticSize = Enum.AutomaticSize.XY,
		Size = UDim2.fromOffset(0, 0),
		Visible = function()
			return InteractState.near() ~= nil
		end,
		create("UIPadding")({
			PaddingTop = UDim.new(0, GAP),
			PaddingBottom = UDim.new(0, GAP),
			PaddingLeft = UDim.new(0, GAP),
			PaddingRight = UDim.new(0, GAP),
		}),
		create("UIListLayout")({
			FillDirection = Enum.FillDirection.Vertical,
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Padding = UDim.new(0, GAP),
			SortOrder = Enum.SortOrder.LayoutOrder,
		}),
		Kit.text({
			Name = "Title",
			LayoutOrder = 1,
			Size = UDim2.fromOffset(WIDTH, 20),
			Text = function()
				local model = InteractState.near()
				local def = model and InteractState.itemOf(model)
				return if def then Strings.get(def.nameKey) else ""
			end,
			maxSize = 18,
		}),
		Kit.text({
			Name = "Status",
			LayoutOrder = 2,
			Size = UDim2.fromOffset(WIDTH, 16),
			FontFace = Theme.font.number,
			Text = statusText,
			Visible = function()
				return statusText() ~= ""
			end,
			maxSize = 14,
		}),
		create("Frame")({
			Name = "Actions",
			LayoutOrder = 3,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromOffset(WIDTH, 0),
			create("UIGridLayout")({
				CellSize = UDim2.fromOffset(BUTTON.X, BUTTON.Y),
				CellPadding = UDim2.fromOffset(GAP, GAP),
				FillDirectionMaxCells = 2,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			vide.indexes(actions, function(action, index)
				return ActionButton(action, index)
			end),
		}),
	}) :: Frame
end

return InteractPanel
