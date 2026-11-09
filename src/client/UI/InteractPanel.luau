--!strict
-- Painel de interação com estruturas (G8): aparece acima da hotbar só enquanto
-- há uma peça de usar de perto (extrator, fornalha, poço, cama, placa) e mostra
-- o nome dela, o estado (madeira, estoque, goles: só o que a peça tem) e um
-- botão por ação. Fica empilhado em cima dos painéis do baú e da caixa quando
-- eles estão visíveis, sem sobrepor. Só pede: quem decide é o servidor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local InteractRules = require(Shared:WaitForChild("Build"):WaitForChild("InteractRules"))
local SignRules = require(Shared:WaitForChild("Build"):WaitForChild("SignRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
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
-- Botões dos símbolos da placa: 4 por fileira (4 * 56 + 3 * 6 cabe em WIDTH).
local SYMBOL_BUTTON = Vector2.new(56, 44) -- px (altura = mínimo de toque)
local SYMBOL_COLUMNS = 4
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
	if status.symbol ~= nil and SignRules.isValid(status.symbol) then
		table.insert(parts, Strings.format("interact.symbol_now", { symbol = SignRules.symbolOf(status.symbol) }))
	end
	return table.concat(parts, "   ")
end

-- O jogador local é o dono da peça? (atributo Owner = UserId, escrito pelo
-- StructureService). O servidor confere de novo: isto só decide o que mostrar.
local function isOwner(model: Model): boolean
	return model:GetAttribute(StatNames.Owner) == Players.LocalPlayer.UserId
end

-- Botão do símbolo `index` da placa: manda o índice em Arg.
local function SymbolButton(index: () -> number, order: number): TextButton
	return create("TextButton")({
		Name = "Symbol",
		LayoutOrder = order,
		Size = UDim2.fromOffset(SYMBOL_BUTTON.X, SYMBOL_BUTTON.Y),
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
			InteractState.act(InteractRules.ACTIONS.symbol, vide.untrack(index))
		end,
		Kit.text({
			Size = UDim2.fromScale(0.8, 0.7),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Text = function()
				return SignRules.symbolOf(index())
			end,
			maxSize = 24,
		}),
	}) :: TextButton
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
			InteractState.act(vide.untrack(action))
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
		-- "symbol" não é um botão só: são os botões de símbolo, logo abaixo.
		local list: { number } = {}
		local model = InteractState.near()
		local owner = model ~= nil and isOwner(model)
		for _, action in InteractRules.actionsFor(current or "") do
			if action ~= InteractRules.ACTIONS.symbol and InteractRules.allowed(current or "", action, owner) then
				table.insert(list, action)
			end
		end
		return list
	end
	-- Índices dos símbolos: só o dono da placa vê os botões (lista vazia = nenhum).
	local symbols = function(): { number }
		local model = InteractState.near()
		local list: { number } = {}
		if model and kind() == "sign" and isOwner(model) then
			for index = 1, #SignRules.SYMBOLS do
				table.insert(list, index)
			end
		end
		return list
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
			PaddingTop = UDim.new(0, Kit.panelPadding(GAP)),
			PaddingBottom = UDim.new(0, Kit.panelPadding(GAP)),
			PaddingLeft = UDim.new(0, Kit.panelPadding(GAP)),
			PaddingRight = UDim.new(0, Kit.panelPadding(GAP)),
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
		create("Frame")({
			Name = "Symbols",
			LayoutOrder = 4,
			BackgroundTransparency = 1,
			AutomaticSize = Enum.AutomaticSize.Y,
			Size = UDim2.fromOffset(WIDTH, 0),
			Visible = function()
				return #symbols() > 0
			end,
			create("UIGridLayout")({
				CellSize = UDim2.fromOffset(SYMBOL_BUTTON.X, SYMBOL_BUTTON.Y),
				CellPadding = UDim2.fromOffset(GAP, GAP),
				FillDirectionMaxCells = SYMBOL_COLUMNS,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			vide.indexes(symbols, function(symbol, index)
				return SymbolButton(symbol, index)
			end),
		}),
	}) :: Frame
end

return InteractPanel
