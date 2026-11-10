--!strict
-- Brilhos na água: traços brancos que aparecem e somem devagar em pontos soltos
-- da água perto da câmera, para a água pintada (Map/Ground/Forest, ColorMap)
-- não parecer parada. Só visual, no cliente; o tempo e a forma de cada brilho
-- estão em World/GlintRules (testado). Os brilhos são reaproveitados (pool).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GlintRules = require(Shared:WaitForChild("World"):WaitForChild("GlintRules"))
local WaterSim = require(Shared:WaitForChild("Simulation"):WaitForChild("WaterSim"))

local MAX_GLINTS = 24 -- ao mesmo tempo (o mais velho é reaproveitado)
local GLINT_Y = 0.3 -- acima da água pintada (chão, topo 0) e da água de peça (topo ~0,26)
local PIXELS_PER_STUD = 24

type Glint = { part: Part, frame: Frame, born: number, length: number, cframe: CFrame, active: boolean }

local WaterGlints = {}

local glints: { Glint } = {}
local nextGlint = 1
local random = Random.new()

local function newGlint(folder: Folder): Glint
	local part = Instance.new("Part")
	part.Name = "Glint"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(1, 0.05, GlintRules.WIDTH)
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
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = frame

	return { part = part, frame = frame, born = 0, length = 1, cframe = CFrame.identity, active = false }
end

local function spawnGlint(now: number)
	local camera = Workspace.CurrentCamera
	if camera == nil then
		return
	end
	local focus = camera.Focus.Position
	local x, z = GlintRules.spot(focus.X, focus.Z, random:NextNumber(), random:NextNumber())
	if not WaterSim.isWet(x, z) then
		return
	end
	local glint = glints[nextGlint]
	nextGlint = nextGlint % #glints + 1
	local angle = GlintRules.ANGLE + random:NextNumber(-1, 1) * GlintRules.ANGLE_JITTER
	glint.born = now
	glint.length = random:NextNumber(GlintRules.MIN_LENGTH, GlintRules.MAX_LENGTH)
	glint.cframe = CFrame.new(x, GLINT_Y, z) * CFrame.Angles(0, angle, 0)
	glint.active = true
end

local function animate(now: number)
	for _, glint in glints do
		if glint.active then
			local progress = (now - glint.born) / GlintRules.LIFE
			if progress >= 1 then
				glint.active = false
				glint.frame.BackgroundTransparency = 1
			else
				glint.part.Size = Vector3.new(glint.length * GlintRules.stretch(progress), 0.05, GlintRules.WIDTH)
				glint.part.CFrame = glint.cframe
				glint.frame.BackgroundTransparency = GlintRules.transparency(progress)
			end
		end
	end
end

-- Liga os brilhos (chamado uma vez pelo WorldFxController).
function WaterGlints.start()
	local folder = Instance.new("Folder")
	folder.Name = "WaterGlints"
	folder.Parent = Workspace
	for i = 1, MAX_GLINTS do
		glints[i] = newGlint(folder)
	end
	local lastSpawn = 0
	RunService.RenderStepped:Connect(function()
		local now = os.clock()
		if now - lastSpawn >= GlintRules.EVERY then
			lastSpawn = now
			spawnGlint(now)
		end
		animate(now)
	end)
end

return WaterGlints
