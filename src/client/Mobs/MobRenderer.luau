--!strict
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local A = require(Shared:WaitForChild("Mobs"):WaitForChild("MobAnim"))
local C = require(Shared:WaitForChild("Mobs"):WaitForChild("MobAnimConfig"))
local Defs = require(Shared:WaitForChild("Defs"))
local Names = require(Shared:WaitForChild("StatNames"))
local V = require(script.Parent:WaitForChild("MobVisual"))
local AngryEyes = require(script.Parent:WaitForChild("AngryEyes"))

type Entry = {
	id: string,
	config: C.Mob,
	visual: V.Visual,
	state: A.State,
	lastPosition: Vector3,
	displayed: CFrame, -- posição mostrada: segue a raiz (10 Hz) com suavização
	resting: A.Pose,
	seed: number, -- atraso do piscar deste mob (0–1)
}
local Renderer = {}
local entries: { [BasePart]: Entry } = {}
local folder: Folder? = nil
local started = false
local random = Random.new()
local TELEPORT_DISTANCE = 30 -- acima disto o mostrado pula direto para a raiz

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
	-- Corpo no jogo: no Studio o atributo Radius do modelo (ajuste ao vivo).
	local stats = Defs.Mobs[id] and Defs.Mobs[id].stats
	local devRadius = template:GetAttribute(Names.MobDevRadius)
	local radius = if type(devRadius) == "number" and devRadius > 0 then devRadius elseif stats then stats.radius else 0
	local visual = V.create(template, config, folder :: Folder, radius)
	local seed = random:NextNumber()
	local entry: Entry = {
		id = id,
		config = config,
		visual = visual,
		state = A.newState(
			counter(root, Names.MobAttack),
			counter(root, Names.MobHurt),
			seed,
			root:GetAttribute(Names.MobHostile) == true,
			root:GetAttribute(Names.MobFlying) == true
		),
		lastPosition = root.Position,
		displayed = root.CFrame,
		resting = A.restPose(config),
		seed = seed,
	}
	entries[root] = entry
	return entry
end

local isStudio = RunService:IsStudio()

-- Studio: ShowBody na pasta Assets.Mobs mostra o círculo do corpo dos mobs.
local function bodyShown(): boolean
	if not isStudio then
		return false
	end
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local templates = assets and assets:FindFirstChild("Mobs")
	return templates ~= nil and templates:GetAttribute(Names.MobDevShowBody) == true
end

local function update(dt: number)
	local showBody = bodyShown()
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
		-- A raiz anda em passos de 10 Hz: o mostrado a segue com suavização
		-- exponencial; a velocidade da animação sai do mostrado.
		local goal = root.CFrame
		local alpha = 1 - math.exp(-C.ROOT_SMOOTHING * math.clamp(dt, 0, C.MAX_DT))
		local target = if (goal.Position - entry.displayed.Position).Magnitude > TELEPORT_DISTANCE
			then goal -- salto grande (renasceu/teletransporte): não desliza
			else entry.displayed:Lerp(goal, alpha)
		entry.displayed = target
		local delta = target.Position - entry.lastPosition
		entry.lastPosition = target.Position
		local speed = if dt > 0 then Vector2.new(delta.X, delta.Z).Magnitude / dt else 0
		local attack, hurt = counter(root, Names.MobAttack), counter(root, Names.MobHurt)
		local dead = root:GetAttribute(Names.MobDead) == true
		local hostile = root:GetAttribute(Names.MobHostile) == true
		local flying = root:GetAttribute(Names.MobFlying) == true
		local pose: A.Pose
		if camera == nil or (target.Position - camera.CFrame.Position).Magnitude <= C.ANIM_RANGE then
			pose = A.step(entry.state, dt, {
				config = entry.config,
				speed = speed,
				attack = attack,
				hurt = hurt,
				dead = dead,
				hostile = hostile,
				flying = flying,
			})
		else
			-- Não guarda eventos fora do alcance para dispará-los ao voltar.
			local latchedDead = dead or entry.state.dead
			entry.state = A.newState(attack, hurt, entry.seed, hostile, flying)
			entry.state.dead = latchedDead
			entry.state.deathTime = if latchedDead then C.DEATH_DURATION else 0
			pose = entry.resting
			pose.groups.Body.scale = if latchedDead then 0 else 1
			pose.outline = if hostile then 1 else 0
			pose.fly = if flying and not latchedDead then 1 else 0
		end
		V.append(entry.visual, target, pose, parts, frames, showBody)
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
end

-- Refaz os mobs de um tipo: somem agora e voltam no próximo quadro.
local function rebuild(id: string)
	for root, entry in entries do
		if entry.id == id then
			remove(root)
		end
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
	-- Corte dos olhos bravos ficou pronto: refaz os mobs desse tipo (voltam no
	-- próximo quadro, já com os olhos cortados).
	AngryEyes.onReady(rebuild)
	-- Studio: mudou Scale ou Radius de um modelo (ajuste de tamanho ao vivo).
	if RunService:IsStudio() then
		task.spawn(function()
			local assets = ReplicatedStorage:WaitForChild("Assets", 10)
			local templates = assets and assets:WaitForChild("Mobs", 10)
			if templates == nil then
				return
			end
			for _, template in templates:GetChildren() do
				for _, name in { Names.MobDevScale, Names.MobDevRadius } do
					template:GetAttributeChangedSignal(name):Connect(function()
						rebuild(template.Name)
					end)
				end
			end
		end)
	end
	CollectionService:GetInstanceRemovedSignal(Names.MobTag):Connect(function(instance)
		if instance:IsA("BasePart") then
			remove(instance)
		end
	end)
	RunService:BindToRenderStep("Mobs", Enum.RenderPriority.Character.Value, update)
end

return Renderer
