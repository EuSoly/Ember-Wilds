--!strict
-- Rastro do tutorial: pontinhos dourados no chão, do personagem até o alvo da
-- etapa atual (a árvore, o arbusto ou a rocha mais perto com recurso, ou a
-- água mais perto). Piscam em onda do jogador para o alvo. Para onde apontar
-- vem de TutorialRules.trailTarget; os pontos, de TrailRules (testados). Só
-- visual, no cliente; os pontos são reaproveitados (pool).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))
local TrailRules = require(Shared:WaitForChild("Tutorial"):WaitForChild("TrailRules"))
local TutorialRules = require(Shared:WaitForChild("Tutorial"):WaitForChild("TutorialRules"))
local TutorialState = require(script.Parent.Parent:WaitForChild("TutorialState"))

local SEARCH_EVERY = 0.5 -- s entre buscas do alvo mais perto
local DOT_Y = 0.35 -- acima do chão, da água pintada e das vitórias-régias
local DOT_SIZE = 0.9 -- studs
local PIXELS_PER_STUD = 24
local WAVE_SPEED = 5 -- rad/s da onda que corre pelo rastro
local WAVE_STEP = 0.55 -- rad de atraso entre um ponto e o próximo

type Dot = { part: Part, frame: Frame }

local TutorialTrail = {}

local dots: { Dot } = {}
local target: Vector3? = nil

local function newDot(folder: Folder): Dot
	local part = Instance.new("Part")
	part.Name = "TrailDot"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(DOT_SIZE, 0.05, DOT_SIZE)
	part.Parent = folder

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = PIXELS_PER_STUD
	gui.LightInfluence = 0
	gui.AlwaysOnTop = false
	gui.Adornee = part
	gui.Parent = part

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Theme.rustic.emberLight
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame
	return { part = part, frame = frame }
end

local function rootPosition(): Vector3?
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root.Position else nil
end

-- O recurso `resourceId` com recurso (Amount > 0) mais perto de `from`.
local function nearestResource(resourceId: string, from: Vector3): Vector3?
	local best: Vector3? = nil
	local bestSq = math.huge
	for _, instance in CollectionService:GetTagged(StatNames.ResourceTag) do
		if instance:GetAttribute(StatNames.ResourceId) ~= resourceId or not instance:IsA("Model") then
			continue
		end
		local amount = instance:GetAttribute(StatNames.Amount)
		if type(amount) == "number" and amount <= 0 then
			continue
		end
		local position = instance:GetPivot().Position
		local sq = (position.X - from.X) ^ 2 + (position.Z - from.Z) ^ 2
		if sq < bestSq then
			best, bestSq = position, sq
		end
	end
	return best
end

-- O centro da peça de água (Map/Water) mais perto de `from`.
local function nearestWater(from: Vector3): Vector3?
	local map = Workspace:FindFirstChild("Map")
	local water = map and map:FindFirstChild("Water")
	if water == nil then
		return nil
	end
	local best: Vector3? = nil
	local bestSq = math.huge
	for _, part in water:GetDescendants() do
		if part:IsA("BasePart") then
			local sq = (part.Position.X - from.X) ^ 2 + (part.Position.Z - from.Z) ^ 2
			if sq < bestSq then
				best, bestSq = part.Position, sq
			end
		end
	end
	return best
end

local function search()
	target = nil
	local step = TutorialState.current()
	local from = rootPosition()
	if step == nil or from == nil then
		return
	end
	local goal = TutorialRules.trailTarget(step, TutorialState.counts())
	if goal == "water" then
		target = nearestWater(from)
	elseif goal then
		target = nearestResource(goal, from)
	end
end

local function hideAll()
	for _, dot in dots do
		dot.frame.BackgroundTransparency = 1
	end
end

local function draw(now: number)
	local from = rootPosition()
	if target == nil or from == nil then
		hideAll()
		return
	end
	local points = TrailRules.dots(from.X, from.Z, target.X, target.Z)
	for i, dot in dots do
		local point = points[i]
		if point then
			dot.part.CFrame = CFrame.new(point.x, DOT_Y, point.z)
			local wave = 0.5 + 0.5 * math.sin(now * WAVE_SPEED - i * WAVE_STEP)
			dot.frame.BackgroundTransparency = 0.15 + 0.55 * wave
		else
			dot.frame.BackgroundTransparency = 1
		end
	end
end

-- Liga o rastro (chamado uma vez pelo WorldFxController).
function TutorialTrail.start()
	local folder = Instance.new("Folder")
	folder.Name = "TutorialTrail"
	folder.Parent = Workspace
	for i = 1, TrailRules.MAX_DOTS do
		dots[i] = newDot(folder)
	end
	local lastSearch = -math.huge
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if now - lastSearch >= SEARCH_EVERY then
			lastSearch = now
			search()
		end
		draw(now)
	end)
end

return TutorialTrail
