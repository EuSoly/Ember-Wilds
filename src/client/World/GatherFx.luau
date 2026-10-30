--!strict
-- Efeitos da coleta no cliente (G2): a cada golpe que o servidor manda
-- (Net.ResourceHit), o recurso dá um tranco na direção do golpe e volta, solta
-- lasquinhas da cor do material e toca o som do material. Também mostra os
-- avisos da coleta (Net.GatherNotice) no Notifications.
-- O tranco é só visual e só neste cliente (PivotTo local num modelo do servidor).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Defs = require(Shared:WaitForChild("Defs"))
local GatherFxConfig = require(Shared:WaitForChild("GatherFxConfig"))
local Strings = require(Shared:WaitForChild("Strings"))

local Client = script.Parent.Parent
local Net = require(Client:WaitForChild("Net"))
local Notifications = require(Client:WaitForChild("UI"):WaitForChild("Notifications"))

local NUDGE = 0.3 -- studs do tranco
local NUDGE_TIME = 0.15 -- segundos (vai e volta)
local CHIPS = 6 -- lasquinhas por golpe
local CHIP_HEIGHT = 2 -- altura (studs) de onde saem as lasquinhas

local GatherFx = {}

-- Pivô original de cada modelo em tranco (golpes seguidos não acumulam).
local shaking: { [Model]: { origin: CFrame, started: number, dir: Vector3 } } = {}

local function nudge(model: Model, dir: Vector3)
	local current = shaking[model]
	shaking[model] = {
		origin = if current then current.origin else model:GetPivot(),
		started = os.clock(),
		dir = dir,
	}
end

local function stepShakes()
	local now = os.clock()
	for model, shake in shaking do
		local t = (now - shake.started) / NUDGE_TIME
		if t >= 1 or model.Parent == nil then
			if model.Parent then
				model:PivotTo(shake.origin)
			end
			shaking[model] = nil
		else
			-- Sobe e desce (seno): sai do lugar e volta.
			local offset = shake.dir * (NUDGE * math.sin(t * math.pi))
			model:PivotTo(shake.origin + offset)
		end
	end
end

-- Uma peça invisível com o emissor de lasquinhas, reaproveitada a cada golpe.
local chipPart: Part? = nil
local chipEmitter: ParticleEmitter? = nil

local function ensureChips(): (Part, ParticleEmitter)
	if chipPart and chipEmitter and chipPart.Parent then
		return chipPart, chipEmitter
	end
	local part = Instance.new("Part")
	part.Name = "GatherChips"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Transparency = 1
	part.Size = Vector3.one * 0.5
	local emitter = Instance.new("ParticleEmitter")
	emitter.Enabled = false
	emitter.Lifetime = NumberRange.new(0.3, 0.5)
	emitter.Speed = NumberRange.new(8, 14)
	emitter.SpreadAngle = Vector2.new(60, 60)
	emitter.Acceleration = Vector3.new(0, -40, 0)
	emitter.Size = NumberSequence.new(0.35, 0.1)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-200, 200)
	emitter.Parent = part
	part.Parent = Workspace
	chipPart, chipEmitter = part, emitter
	return part, emitter
end

local function chips(x: number, z: number, dir: Vector3, color: Color3)
	local part, emitter = ensureChips()
	-- Saem de volta para quem bateu (contra a direção do golpe), um pouco para cima.
	part.CFrame =
		CFrame.lookAt(Vector3.new(x, CHIP_HEIGHT, z), Vector3.new(x, CHIP_HEIGHT, z) - dir + Vector3.yAxis * 0.6)
	emitter.EmissionDirection = Enum.NormalId.Front
	emitter.Color = ColorSequence.new(color)
	emitter:Emit(CHIPS)
end

local function sound(x: number, z: number, fx: GatherFxConfig.MaterialFx)
	if fx.soundId == "" then
		return
	end
	local attachment = Instance.new("Attachment")
	attachment.WorldPosition = Vector3.new(x, CHIP_HEIGHT, z)
	attachment.Parent = Workspace.Terrain
	local s = Instance.new("Sound")
	s.SoundId = fx.soundId
	s.Volume = fx.volume
	s.PlaybackSpeed = 0.9 + math.random() * 0.2 -- variação de tom (identidade visual)
	s.SoundGroup = SoundService:FindFirstChild("Effects") :: SoundGroup?
	s.Parent = attachment
	s:Play()
	s.Ended:Once(function()
		attachment:Destroy()
	end)
	task.delay(3, function()
		if attachment.Parent then
			attachment:Destroy()
		end
	end)
end

function GatherFx.start()
	RunService.RenderStepped:Connect(stepShakes)

	Net.ResourceHit.On(function(data)
		local fx = GatherFxConfig[data.Material]
		local dir = Vector3.new(data.DirX, 0, data.DirZ)
		local model = data.Resource
		if model and model:IsA("Model") then
			nudge(model, dir)
		end
		if fx then
			chips(data.X, data.Z, dir, Color3.fromHex(fx.color))
			sound(data.X, data.Z, fx)
		end
	end)

	Net.GatherNotice.On(function(data)
		local item = if data.ItemId then Defs.Items[data.ItemId] else nil
		if item then
			local vars: { [string]: string | number } = { item = Strings.get(item.nameKey) }
			Notifications.push(data.Key, vars)
		else
			Notifications.push(data.Key)
		end
	end)
end

return GatherFx
