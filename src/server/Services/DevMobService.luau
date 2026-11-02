--!strict
-- Galeria visual exclusiva do Studio: nenhuma IA, Humanoid ou dano real.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local C = require(ReplicatedStorage.Shared.Mobs.MobAnimConfig)
local Names = require(ReplicatedStorage.Shared.StatNames)
local Service = {}
-- Estes tempos e deslocamentos pertencem somente à demonstração.
local IDLE, WALK, ATTACK, HURT, DEAD = 3, 5, 1.5, 1.5, 1
local CYCLE = IDLE + WALK + ATTACK + HURT + DEAD
-- Raio 4 em 5 s ≈ 5 studs/s: rápido o bastante para a animação de andar aparecer.
local SPACING, RADIUS = 16, 4
type Member = { id: string, center: Vector3, root: Part?, phase: string }
local members: { Member } = {}
local gallery: Folder? = nil
local connection: RBXScriptConnection? = nil

local function clear()
	if connection then
		connection:Disconnect()
		connection = nil
	end
	table.clear(members)
	if gallery then
		gallery:Destroy()
		gallery = nil
	end
end

local function newRoot(member: Member): Part
	local root = Instance.new("Part")
	root.Name = member.id
	root.Size = Vector3.one
	root.Anchored, root.Transparency = true, 1
	root.CanCollide, root.CanTouch, root.CanQuery = false, false, false
	root.CFrame = CFrame.new(member.center + Vector3.new(RADIUS, 0, 0))
	root:SetAttribute(Names.MobId, member.id)
	root:SetAttribute(Names.MobAttack, 0)
	root:SetAttribute(Names.MobHurt, 0)
	root:SetAttribute(Names.MobDead, false)
	root.Parent = gallery
	CollectionService:AddTag(root, Names.MobTag)
	member.root, member.phase = root, "idle"
	return root
end

local function groundAt(position: Vector3): Vector3
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore: { Instance } = {}
	for _, player in Players:GetPlayers() do
		if player.Character then
			table.insert(ignore, player.Character)
		end
	end
	params.FilterDescendantsInstances = ignore
	local hit = Workspace:Raycast(position + Vector3.new(0, 100, 0), Vector3.new(0, -250, 0), params)
	return Vector3.new(position.X, if hit then hit.Position.Y else position.Y, position.Z)
end

local function enable(on: boolean): number
	clear()
	if not on then
		return 0
	end
	local origin = Vector3.new(0, 0, 0)
	local player = Players:GetPlayers()[1]
	if player and player.Character then
		origin = player.Character:GetPivot().Position
	end
	local f = Instance.new("Folder")
	f.Name = "DevMobs"
	f.Parent = Workspace
	gallery = f
	local ids: { string } = {}
	for id in C.Mobs :: { [string]: C.Mob } do
		table.insert(ids, id)
	end
	table.sort(ids)
	for i, id in ids do
		local center =
			groundAt(origin + Vector3.new(((i - 1) % 5 - 2) * SPACING, 0, 18 + math.floor((i - 1) / 5) * SPACING))
		local member: Member = { id = id, center = center, root = nil, phase = "" }
		table.insert(members, member)
		newRoot(member)
	end
	local start = os.clock()
	connection = RunService.Heartbeat:Connect(function()
		local t = (os.clock() - start) % CYCLE
		local phase = if t < IDLE
			then "idle"
			elseif t < IDLE + WALK then "walk"
			elseif t < IDLE + WALK + ATTACK then "attack"
			elseif t < IDLE + WALK + ATTACK + HURT then "hurt"
			else "dead"
		for _, member in members do
			local root = member.root
			if not root then
				if phase == "idle" then
					newRoot(member)
				end
				continue
			end
			if phase ~= member.phase then
				member.phase = phase
				if phase == "attack" then
					root:SetAttribute(Names.MobAttack, (root:GetAttribute(Names.MobAttack) :: number) + 1)
				elseif phase == "hurt" then
					root:SetAttribute(Names.MobHurt, (root:GetAttribute(Names.MobHurt) :: number) + 1)
				elseif phase == "dead" then
					root:SetAttribute(Names.MobDead, true)
				end
			end
			if phase == "walk" then
				local angle = (t - IDLE) / WALK * 2 * math.pi
				local position = member.center + Vector3.new(math.cos(angle), 0, math.sin(angle)) * RADIUS
				root.CFrame = CFrame.lookAt(position, position + Vector3.new(-math.sin(angle), 0, math.cos(angle)))
			elseif phase == "dead" and t >= CYCLE - DEAD + C.DEATH_DURATION + 0.2 then
				root:Destroy()
				member.root = nil
			end
		end
	end)
	return #members
end

function Service.Start(_self)
	if not RunService:IsStudio() then
		return
	end
	local command = Instance.new("BindableFunction")
	command.Name = "DevMobs"
	command.OnInvoke = enable
	command.Parent = ServerStorage
end

return Service
