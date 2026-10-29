--!strict
-- Arrastar itens entre slots (hotbar ↔ mochila, e dentro de cada uma).
--
-- Fluxo:
-- 1. o slot chama DragState.press(index, input) quando o dedo/clique começa nele;
-- 2. se o ponteiro andar mais que DRAG_THRESHOLD px, vira arrasto: o item segue
--    o ponteiro (componente DragGhost) e o slot debaixo dele fica destacado;
-- 3. ao soltar em cima de outro slot, pede ao servidor MoveSlot(origem, destino).
--    Soltar fora de um slot cancela.
-- Se o ponteiro não andou o bastante, foi um toque simples e o slot trata como
-- seleção (ver SlotButton).
--
-- Os slots são reconhecidos pelo atributo SlotIndex que o SlotButton grava.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local UIMath = require(Shared:WaitForChild("UIMath"))
local InventoryState = require(script.Parent:WaitForChild("InventoryState"))
local Net = require(script.Parent:WaitForChild("Net"))

local DRAG_THRESHOLD = 8 -- pixels
-- Por quanto tempo depois de soltar um arrasto o "clique" do slot é ignorado
-- (o Activated do botão chega logo depois do fim do arrasto).
local SUPPRESS_CLICK_TIME = 0.25

export type Drag = {
	from: number, -- slot de origem
	item: InventoryState.Item,
	position: Vector2, -- ponteiro, em coordenadas de interface
}

local DragState = {}

-- Arrasto em andamento (nil = nenhum).
DragState.current = vide.source(nil :: Drag?)
-- Slot debaixo do ponteiro durante o arrasto (nil = nenhum).
DragState.target = vide.source(nil :: number?)

local pressed: { index: number, input: InputObject, start: Vector2 }? = nil
local lastDragEnd = -math.huge

-- O slot (atributo SlotIndex) que está no ponto (x, y) da tela, se houver.
local function slotAt(position: Vector2): number?
	local playerGui = Players.LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if not playerGui then
		return nil
	end
	for _, gui in playerGui:GetGuiObjectsAtPosition(position.X, position.Y) do
		local index = gui:GetAttribute("SlotIndex")
		if type(index) == "number" then
			return index
		end
	end
	return nil
end

local function finish(position: Vector2)
	local drag = vide.untrack(DragState.current)
	pressed = nil
	if drag then
		lastDragEnd = os.clock()
		local target = slotAt(position)
		if target and target ~= drag.from then
			Net.MoveSlot.Fire(drag.from, target)
		end
	end
	DragState.current(nil)
	DragState.target(nil)
end

-- O dedo/clique começou num slot com item.
function DragState.press(index: number, input: InputObject)
	if pressed ~= nil or vide.untrack(InventoryState.slots)[index] == nil then
		return
	end
	pressed = { index = index, input = input, start = Vector2.new(input.Position.X, input.Position.Y) }
end

-- true logo depois de um arrasto terminar: o slot não deve tratar como clique.
function DragState.justDropped(): boolean
	return os.clock() - lastDragEnd < SUPPRESS_CLICK_TIME
end

-- Liga os ouvintes de movimento e de soltar (chamado uma vez pelo InventoryController).
function DragState.start()
	UserInputService.InputChanged:Connect(function(input: InputObject)
		local press = pressed
		if press == nil then
			return
		end
		local isMouse = input.UserInputType == Enum.UserInputType.MouseMovement
			and press.input.UserInputType == Enum.UserInputType.MouseButton1
		-- No toque, só o dedo que começou no slot conta.
		if not isMouse and input ~= press.input then
			return
		end
		local position = Vector2.new(input.Position.X, input.Position.Y)
		local drag = vide.untrack(DragState.current)
		if drag == nil then
			local delta = position - press.start
			if not UIMath.isDrag(delta.X, delta.Y, DRAG_THRESHOLD) then
				return
			end
			local item = vide.untrack(InventoryState.slots)[press.index]
			if item == nil then
				pressed = nil
				return
			end
			DragState.current({ from = press.index, item = item, position = position })
		else
			DragState.current({ from = drag.from, item = drag.item, position = position })
		end
		DragState.target(slotAt(position))
	end)

	-- A janela perdeu o foco no meio do arrasto: o "soltar" nunca chega, então cancela.
	UserInputService.WindowFocusReleased:Connect(function()
		pressed = nil
		DragState.current(nil)
		DragState.target(nil)
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		local press = pressed
		if press == nil then
			return
		end
		local isMouseRelease = input.UserInputType == Enum.UserInputType.MouseButton1
			and press.input.UserInputType == Enum.UserInputType.MouseButton1
		if isMouseRelease or input == press.input then
			finish(Vector2.new(input.Position.X, input.Position.Y))
		end
	end)
end

return DragState
