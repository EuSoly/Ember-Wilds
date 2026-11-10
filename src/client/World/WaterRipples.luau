--!strict
-- Ondinhas na água: quem anda pela água (jogadores e bonecos, tag Boneco; bichos,
-- tag Mob) solta anéis brancos que se abrem e somem, como uma pedra jogada no
-- lago. Só visual, no cliente; quando e como cada anel cresce está em
-- World/RippleRules (testado). Só olha quem está perto da câmera, e os anéis
-- são reaproveitados (pool), para pesar pouco com muitos bichos.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local RippleRules = require(Shared:WaitForChild("World"):WaitForChild("RippleRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local WaterSim = require(Shared:WaitForChild("Simulation"):WaitForChild("WaterSim"))

local CHECK_EVERY = 0.1 -- s entre conferências de quem está na água
local MAX_DISTANCE = 160 -- studs da câmera: mais longe não solta anel
local MAX_RINGS = 48 -- anéis ao mesmo tempo (o mais velho é reaproveitado)
local RING_Y = 0.32 -- acima da água pintada (chão, topo 0) e da água de peça (topo ~0,26)
local STROKE = 4 -- px da linha do anel
local PIXELS_PER_STUD = 24

type Ring = { part: Part, stroke: UIStroke, born: number, x: number, z: number, active: boolean }

local WaterRipples = {}

local rings: { Ring } = {}
local nextRing = 1
local states: { [Instance]: RippleRules.State } = {}

local function newRing(folder: Folder): Ring
	local part = Instance.new("Part")
	part.Name = "Ripple"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 0.05, 1)
	part.Parent = folder

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Adornee = part
	gui.Parent = part

	local circle = Instance.new("Frame")
	circle.BackgroundTransparency = 1
	circle.Size = UDim2.fromScale(1, 1)
	circle.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = circle
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.new(1, 1, 1)
	stroke.Thickness = STROKE
	stroke.Transparency = 1
	stroke.Parent = circle

	return { part = part, stroke = stroke, born = 0, x = 0, z = 0, active = false }
end

local function emit(x: number, z: number, now: number)
	local ring = rings[nextRing]
	nextRing = nextRing % #rings + 1
	ring.born, ring.x, ring.z, ring.active = now, x, z, true
end

local function animate(now: number)
	for _, ring in rings do
		if ring.active then
			local progress = (now - ring.born) / RippleRules.LIFE
			if progress >= 1 then
				ring.active = false
				ring.stroke.Transparency = 1
			else
				local size, alpha = RippleRules.ring(progress)
				ring.part.Size = Vector3.new(size, 0.05, size)
				ring.part.CFrame = CFrame.new(ring.x, RING_Y, ring.z)
				ring.stroke.Transparency = alpha
			end
		end
	end
end

-- Posição no chão de quem pode soltar anel (raiz do personagem ou do bicho).
local function rootOf(instance: Instance): BasePart?
	if instance:IsA("Model") then
		local root = instance:FindFirstChild("HumanoidRootPart") or instance.PrimaryPart
		return if root and root:IsA("BasePart") then root else nil
	end
	return if instance:IsA("BasePart") then instance else nil
end

local function check(now: number)
	local camera = Workspace.CurrentCamera
	local focus = if camera then camera.Focus.Position else Vector3.zero
	local seen: { [Instance]: boolean } = {}
	for _, tag in { StatNames.BonecoTag, StatNames.MobTag } do
		for _, instance in CollectionService:GetTagged(tag) do
			local root = rootOf(instance)
			if root and root:IsDescendantOf(Workspace) then
				local p = root.Position
				local dx, dz = p.X - focus.X, p.Z - focus.Z
				if dx * dx + dz * dz <= MAX_DISTANCE * MAX_DISTANCE and WaterSim.isWet(p.X, p.Z) then
					seen[instance] = true
					local shouldEmit, state = RippleRules.step(states[instance], p.X, p.Z, now)
					states[instance] = state
					if shouldEmit then
						emit(p.X, p.Z, now)
					end
				end
			end
		end
	end
	-- Saiu da água (ou de perto): o próximo passo na água solta na hora.
	for instance in states do
		if not seen[instance] then
			states[instance] = nil
		end
	end
end

-- Liga as ondinhas (chamado uma vez pelo WorldFxController).
function WaterRipples.start()
	local folder = Instance.new("Folder")
	folder.Name = "WaterRipples"
	folder.Parent = Workspace
	for i = 1, MAX_RINGS do
		rings[i] = newRing(folder)
	end
	local lastCheck = 0
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if now - lastCheck >= CHECK_EVERY then
			lastCheck = now
			check(now)
		end
		animate(now)
	end)
end

return WaterRipples
