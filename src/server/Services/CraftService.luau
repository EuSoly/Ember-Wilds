--!strict
-- O servidor valida e executa um craft por personagem; materiais saem no início.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Defs = require(ReplicatedStorage.Shared.Defs)
local CraftRules = require(ReplicatedStorage.Shared.Craft.CraftRules)
local Inventory = require(ReplicatedStorage.Shared.Inventory)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local InventoryService = require(script.Parent.InventoryService)
local StatsService = require(script.Parent.StatsService)
local Net = require(script.Parent.Parent.Net)

type ActiveCraft = { token: {}, character: Model, ingredients: { { id: string, count: number } } }
local CraftService = {}
local active: { [Player]: ActiveCraft } = {}

local function maxStackOf(id: string): number
	local item = Defs.Items[id]
	return if item then item.maxStack else 1
end

local function stationNear(kind: string, position: Vector3): boolean
	for _, station in CollectionService:GetTagged(StatNames.CraftStationTag) do
		if station:GetAttribute(StatNames.Station) == kind and station:IsDescendantOf(Workspace) then
			local center: Vector3?
			if station:IsA("Model") then
				center = station:GetPivot().Position
			elseif station:IsA("BasePart") then
				center = station.Position
			end
			if center then
				local dx, dz = center.X - position.X, center.Z - position.Z
				if dx * dx + dz * dz <= CraftRules.STATION_RADIUS * CraftRules.STATION_RADIUS then
					return true
				end
			end
		end
	end
	return false
end

local function notify(player: Player, key: string)
	Net.CraftNotice.Fire(player, key)
end

local function clear(character: Model)
	character:SetAttribute(StatNames.CraftRecipe, nil)
	character:SetAttribute(StatNames.CraftStart, nil)
	character:SetAttribute(StatNames.CraftEnd, nil)
end

local function stop(player: Player, refund: boolean)
	local state = active[player]
	if state == nil then
		return
	end
	active[player] = nil
	if refund and player.Parent == Players then
		for _, part in state.ingredients do
			InventoryService.give(player, part.id, part.count)
		end
	end
	clear(state.character)
end

local function countsOf(inv: Inventory.Inventory): { [string]: number }
	local counts = {}
	for _, slot in inv.slots do
		counts[slot.id] = (counts[slot.id] or 0) + slot.count
	end
	return counts
end

local function start(player: Player, recipeId: string)
	local character = player.Character
	local recipe = Defs.Recipes[recipeId]
	if recipe == nil or active[player] ~= nil or character == nil then
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or humanoid.Health <= 0 or root == nil or not root:IsA("BasePart") then
		return
	end
	local inv = InventoryService.get(player)
	if inv == nil then
		return
	end
	if recipe.station and not stationNear(recipe.station, root.Position) then
		notify(player, if recipe.station == "workbench" then "craft.needWorkbench" else "craft.needFire")
		return
	end
	local counts = countsOf(inv)
	if not CraftRules.hasIngredients(recipe, counts) then
		return
	end
	if not CraftRules.fits(inv, recipe, maxStackOf) then
		notify(player, "craft.full")
		return
	end
	local removed: { { id: string, count: number } } = {}
	for _, part in recipe.ingredients do
		if not InventoryService.take(player, part.id, part.count) then
			for _, taken in removed do
				InventoryService.give(player, taken.id, taken.count)
			end
			return
		end
		table.insert(removed, part)
	end
	local equipped = character:GetAttribute(StatNames.Equipped)
	local held = if type(equipped) == "string" then Defs.Items[equipped] else nil
	local now = Workspace:GetServerTimeNow()
	local duration = CraftRules.duration(recipe, held)
	local token = {}
	active[player] = { token = token, character = character, ingredients = removed }
	character:SetAttribute(StatNames.CraftRecipe, recipe.id)
	character:SetAttribute(StatNames.CraftStart, now)
	character:SetAttribute(StatNames.CraftEnd, now + duration)
	task.delay(duration, function()
		local state = active[player]
		if state == nil or state.token ~= token then
			return
		end
		local alive = player.Parent == Players
			and player.Character == character
			and character:FindFirstChildOfClass("Humanoid") ~= nil
			and (character:FindFirstChildOfClass("Humanoid") :: Humanoid).Health > 0
		active[player] = nil
		clear(character)
		if not alive then
			return
		end
		if InventoryService.give(player, recipe.result, recipe.count) > 0 then
			notify(player, "craft.full")
		end
		StatsService.add(player, "items_crafted", recipe.count, recipe.result)
	end)
end

local function setupPlayer(player: Player)
	player.CharacterRemoving:Connect(function(character)
		local state = active[player]
		if state and state.character == character then
			stop(player, false)
		end
	end)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid", 10)
		if humanoid and humanoid:IsA("Humanoid") then
			humanoid.Died:Connect(function()
				local state = active[player]
				if state and state.character == character then
					stop(player, false)
				end
			end)
		end
	end)
end

function CraftService.isCrafting(character: Model): boolean
	return character:GetAttribute(StatNames.CraftRecipe) ~= nil
end

function CraftService.Start(_self)
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		stop(player, false)
	end)
	Net.RequestCraft.On(start)
	Net.CancelCraft.On(function(player: Player)
		stop(player, true)
	end)
end

return CraftService
