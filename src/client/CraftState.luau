--!strict
-- Estado local do crafting. O servidor continua sendo a autoridade de início/fim.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local CraftRules = require(Shared:WaitForChild("Craft"):WaitForChild("CraftRules"))
local ItemAccess = require(Shared:WaitForChild("ItemAccess"))
local Inventory = require(Shared:WaitForChild("Inventory"))
local InventoryState = require(script.Parent:WaitForChild("InventoryState"))
local HotbarState = require(script.Parent:WaitForChild("HotbarState"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Net = require(script.Parent:WaitForChild("Net"))
local Notifications = require(script.Parent:WaitForChild("UI"):WaitForChild("Notifications"))

export type Current = { id: string, start: number, finish: number }
export type Row = { id: string, order: number }

local CraftState = {
	near = vide.source({} :: { [string]: boolean }),
	current = vide.source(nil :: Current?),
	rows = vide.source({} :: { Row }),
	now = vide.source(Workspace:GetServerTimeNow()),
	equipped = vide.source(nil :: string?),
}

local function counts(): { [string]: number }
	local result = {}
	for _, slot in InventoryState.slots() do
		result[slot.id] = (result[slot.id] or 0) + slot.count
	end
	return result
end

local function updateNear()
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local result: { [string]: boolean } = {}
	if root and root:IsA("BasePart") then
		for _, station in CollectionService:GetTagged(StatNames.CraftStationTag) do
			if station:IsDescendantOf(Workspace) then
				local stationType = station:GetAttribute(StatNames.Station)
				local point = if station:IsA("Model")
					then station:GetPivot().Position
					elseif station:IsA("BasePart") then station.Position
					else nil
				if type(stationType) == "string" and point then
					local dx, dz = point.X - root.Position.X, point.Z - root.Position.Z
					if dx * dx + dz * dz <= CraftRules.STATION_RADIUS * CraftRules.STATION_RADIUS then
						result[stationType] = true
					end
				end
			end
		end
	end
	local previous = CraftState.near()
	for stationType, isNear in result do
		if isNear ~= previous[stationType] then
			CraftState.near(result)
			return true
		end
	end
	for stationType, isNear in previous do
		if isNear ~= result[stationType] then
			CraftState.near(result)
			return true
		end
	end
	return false
end

local function sameRows(a: { Row }, b: { Row }): boolean
	if #a ~= #b then
		return false
	end
	for index, row in a do
		if b[index] == nil or row.id ~= b[index].id then
			return false
		end
	end
	return true
end

local function updateRows()
	local near = CraftState.near()
	local craftable = CraftRules.craftable(Defs.Recipes, counts(), near)
	local out: { Row } = {}
	local seen: { [string]: boolean } = {}
	local inStudio = RunService:IsStudio()
	for _, recipe in craftable do
		if ItemAccess.recipeAvailable(recipe, inStudio) then
			seen[recipe.id] = true
			table.insert(out, { id = recipe.id, order = recipe.order })
		end
	end
	local current = CraftState.current()
	if current and not seen[current.id] then
		local recipe = Defs.Recipes[current.id]
		if recipe then
			table.insert(out, { id = recipe.id, order = recipe.order })
		end
	end
	table.sort(out, function(a, b)
		return if a.order == b.order then a.id < b.id else a.order < b.order
	end)
	if not sameRows(CraftState.rows(), out) then
		CraftState.rows(out)
	end
end

-- Auto-equipar o livro ao craftar: se há um livro na hotbar, o cliente o
-- seleciona antes de pedir o craft (o livro dá craftSpeed e o servidor lê o
-- slot selecionado na hora) e, ao terminar/cancelar, volta ao slot anterior.
local BOOK_ID = "book"
-- Craft recusado pelo servidor não manda CraftProgress; se depois disso não
-- houver craft ativo, restaura o slot como rede de segurança.
local REJECT_GRACE = 0.5

type BookRestore = { prev: number, bookSlot: number, requestedAt: number, confirmed: boolean }
local bookRestore: BookRestore? = nil

-- Primeiro slot do livro dentro da hotbar (ignora a mochila), ou nil.
local function findBookSlot(): number?
	local slots = InventoryState.slots()
	return Inventory.findSlot({ capacity = HotbarState.SLOT_COUNT, slots = slots }, BOOK_ID)
end

-- Volta ao slot de antes do craft — só se o jogador ainda está no livro (uma
-- troca manual no meio do craft é respeitada: não força a volta).
local function restoreBook()
	local pending = bookRestore
	if pending == nil then
		return
	end
	bookRestore = nil
	if vide.untrack(HotbarState.selected) == pending.bookSlot then
		HotbarState.select(pending.prev)
	end
end

-- Antes de pedir um craft novo: seleciona o livro da hotbar (se houver e não for
-- já o selecionado) e guarda o slot atual para restaurar depois.
local function equipBookForCraft()
	if bookRestore ~= nil then
		return
	end
	local bookSlot = findBookSlot()
	if bookSlot == nil then
		return
	end
	local selected = vide.untrack(HotbarState.selected)
	if selected == bookSlot or HotbarState.isLocked() then
		return
	end
	bookRestore = {
		prev = selected,
		bookSlot = bookSlot,
		requestedAt = Workspace:GetServerTimeNow(),
		confirmed = false,
	}
	HotbarState.select(bookSlot)
end

function CraftState.isCrafting(): boolean
	return CraftState.current() ~= nil
end

function CraftState.start(id: string)
	local current = CraftState.current()
	if current and current.id == id then
		Net.CancelCraft.Fire()
	else
		-- Só equipa o livro ao começar do zero (não no meio de outro craft, que
		-- o servidor recusa de qualquer jeito).
		if current == nil then
			equipBookForCraft()
		end
		Net.RequestCraft.Fire(id)
	end
end

function CraftState.toggle(id: string)
	local current = CraftState.current()
	if current and current.id == id then
		CraftState.cancel()
	else
		CraftState.start(id)
	end
end

function CraftState.cancel()
	if CraftState.isCrafting() then
		Net.CancelCraft.Fire()
	end
end

function CraftState.recipe(id: string): Defs.RecipeDef?
	return Defs.Recipes[id]
end

function CraftState.Start(_self)
	Net.CraftNotice.On(function(key: string)
		Notifications.push(key)
	end)
	-- Só o dono recebe o estado do craft (os outros não podem saber).
	local currentChanged = false
	Net.CraftProgress.On(function(data)
		local recipe = data.Recipe
		CraftState.current(if recipe then { id = recipe, start = data.Start, finish = data.Finish } else nil)
		currentChanged = true
		if recipe then
			if bookRestore then
				bookRestore.confirmed = true
			end
		else
			restoreBook()
		end
	end)
	UserInputService.InputBegan:Connect(function(input, processed)
		if not processed and input.UserInputType == Enum.UserInputType.MouseButton2 then
			CraftState.cancel()
		end
	end)
	task.spawn(function()
		local previousSlots = nil
		local initialized = false
		while true do
			local nearChanged = updateNear()
			local character = Players.LocalPlayer.Character
			local equipped = character and character:GetAttribute(StatNames.Equipped)
			local equippedId = if type(equipped) == "string" then equipped else nil
			if CraftState.equipped() ~= equippedId then
				CraftState.equipped(equippedId)
			end
			CraftState.now(Workspace:GetServerTimeNow())
			-- Rede de segurança: craft recusado não manda CraftProgress; se o
			-- livro foi equipado e nenhum craft começou até o prazo, restaura.
			local pending = bookRestore
			if
				pending
				and not pending.confirmed
				and CraftState.current() == nil
				and Workspace:GetServerTimeNow() - pending.requestedAt > REJECT_GRACE
			then
				restoreBook()
			end
			local slots = InventoryState.slots()
			if not initialized or nearChanged or currentChanged or slots ~= previousSlots then
				updateRows()
				initialized = true
				previousSlots = slots
				currentChanged = false
			end
			task.wait(0.1)
		end
	end)
end

return CraftState
