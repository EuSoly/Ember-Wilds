--!strict
-- Estado local do crafting. O servidor continua sendo a autoridade de início/fim.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local CraftRules = require(Shared:WaitForChild("Craft"):WaitForChild("CraftRules"))
local InventoryState = require(script.Parent:WaitForChild("InventoryState"))
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

local function readCurrent(): Current?
	local character = Players.LocalPlayer.Character
	if character == nil then
		return nil
	end
	local id = character:GetAttribute(StatNames.CraftRecipe)
	local start = character:GetAttribute(StatNames.CraftStart)
	local finish = character:GetAttribute(StatNames.CraftEnd)
	if type(id) == "string" and type(start) == "number" and type(finish) == "number" then
		return { id = id, start = start, finish = finish }
	end
	return nil
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

local function sameCurrent(a: Current?, b: Current?): boolean
	return if a == nil then b == nil else b ~= nil and a.id == b.id and a.start == b.start and a.finish == b.finish
end

local function updateRows()
	local near = CraftState.near()
	local craftable = CraftRules.craftable(Defs.Recipes, counts(), near)
	local out: { Row } = {}
	local seen: { [string]: boolean } = {}
	for _, recipe in craftable do
		seen[recipe.id] = true
		table.insert(out, { id = recipe.id, order = recipe.order })
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

function CraftState.isCrafting(): boolean
	return CraftState.current() ~= nil
end

function CraftState.start(id: string)
	local current = CraftState.current()
	if current and current.id == id then
		Net.CancelCraft.Fire()
	else
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
			local current = readCurrent()
			local currentChanged = not sameCurrent(CraftState.current(), current)
			if currentChanged then
				CraftState.current(current)
			end
			local character = Players.LocalPlayer.Character
			local equipped = character and character:GetAttribute(StatNames.Equipped)
			local equippedId = if type(equipped) == "string" then equipped else nil
			if CraftState.equipped() ~= equippedId then
				CraftState.equipped(equippedId)
			end
			CraftState.now(Workspace:GetServerTimeNow())
			local slots = InventoryState.slots()
			if not initialized or nearChanged or currentChanged or slots ~= previousSlots then
				updateRows()
				initialized = true
				previousSlots = slots
			end
			task.wait(0.1)
		end
	end)
end

return CraftState
