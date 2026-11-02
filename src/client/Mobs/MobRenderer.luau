--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local A = require(Shared:WaitForChild("Mobs"):WaitForChild("MobAnim"))
local C = require(Shared:WaitForChild("Mobs"):WaitForChild("MobAnimConfig"))
local Names = require(Shared:WaitForChild("StatNames"))
local V = require(script.Parent:WaitForChild("MobVisual"))

type Entry = {
	id: string,
	config: C.Mob,
	visual: V.Visual,
	state: A.State,
	lastPosition: Vector3,
	resting: A.Pose,
	seed: number, -- atraso do piscar deste mob (0–1)
}
local Renderer = {}
local entries: { [BasePart]: Entry } = {}
local folder: Folder? = nil
local started = false
local random = Random.new()

local function counter(root: BasePart, name: string): number
	local value = root:GetAttribute(name)
	return if type(value) == "number" and value == value then value else 0
end

local function remove(root: BasePart)
	local entry = entries[root]
	if entry then
		V.destroy(entry.visual)
		entries[root] = nil
	end
end

local function add(root: BasePart, id: string): Entry?
	local config = C.Mobs[id]
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local templates = if assets then assets:FindFirstChild("Mobs") else nil
	local template = if templates then templates:FindFirstChild(id) else nil
	if not config or not template or not template:IsA("Model") or not template:FindFirstChild("Body") then
		return nil -- tenta de novo se o template/atributo ainda estiver chegando.
	end
	local visual = V.create(template, config, folder :: Folder)
	local seed = random:NextNumber()
	local entry: Entry = {
		id = id,
		config = config,
		visual = visual,
		state = A.newState(
			counter(root, Names.MobAttack),
			counter(root, Names.MobHurt),
			seed,
			root:GetAttribute(Names.MobHostile) == true
		),
		lastPosition = root.Position,
		resting = A.restPose(config),
		seed = seed,
	}
	entries[root] = entry
	return entry
end

local function update(dt: number)
	local parts: { BasePart } = {}
	local frames: { CFrame } = {}
	local camera = Workspace.CurrentCamera
	for root in entries do
		if not root:IsDescendantOf(Workspace) or not CollectionService:HasTag(root, Names.MobTag) then
			remove(root)
		end
	end
	for _, instance in CollectionService:GetTagged(Names.MobTag) do
		if not instance:IsA("BasePart") or not instance:IsDescendantOf(Workspace) then
			continue
		end
		local root = instance
		local id = root:GetAttribute(Names.MobId)
		if type(id) ~= "string" then
			remove(root)
			continue
		end
		local entry: Entry? = entries[root]
		if entry and entry.id ~= id then
			remove(root)
			entry = nil
		end
		if not entry then
			entry = add(root, id)
		end
		if not entry then
			continue
		end
		local target = root.CFrame
		local delta = target.Position - entry.lastPosition
		entry.lastPosition = target.Position
		local speed = if dt > 0 then Vector2.new(delta.X, delta.Z).Magnitude / dt else 0
		local attack, hurt = counter(root, Names.MobAttack), counter(root, Names.MobHurt)
		local dead = root:GetAttribute(Names.MobDead) == true
		local hostile = root:GetAttribute(Names.MobHostile) == true
		local pose: A.Pose
		if camera == nil or (target.Position - camera.CFrame.Position).Magnitude <= C.ANIM_RANGE then
			pose = A.step(
				entry.state,
				dt,
				{ config = entry.config, speed = speed, attack = attack, hurt = hurt, dead = dead, hostile = hostile }
			)
		else
			-- Não guarda eventos fora do alcance para dispará-los ao voltar.
			local latchedDead = dead or entry.state.dead
			entry.state = A.newState(attack, hurt, entry.seed, hostile)
			entry.state.dead = latchedDead
			entry.state.deathTime = if latchedDead then C.DEATH_DURATION else 0
			pose = entry.resting
			pose.groups.Body.scale = if latchedDead then 0 else 1
			pose.outline = if hostile then 1 else 0
		end
		V.append(entry.visual, target, pose, parts, frames)
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

function Renderer.start()
	if started then
		return
	end
	started = true
	local visuals = Instance.new("Folder")
	visuals.Name = "MobVisuals"
	visuals.Parent = Workspace
	folder = visuals
	CollectionService:GetInstanceRemovedSignal(Names.MobTag):Connect(function(instance)
		if instance:IsA("BasePart") then
			remove(instance)
		end
	end)
	RunService:BindToRenderStep("Mobs", Enum.RenderPriority.Character.Value, update)
end

return Renderer
