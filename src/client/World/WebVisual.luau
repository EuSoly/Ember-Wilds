--!strict
-- Teia provisória nos pés de quem está preso (atributo WebbedUntil do
-- personagem, instante de fim em tempo do servidor): um disco translúcido
-- branco com algumas linhas. Os atributos do personagem local previsto não
-- disparam AttributeChanged, então lê tudo por polling a cada quadro.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MobRules = require(Shared:WaitForChild("Mobs"):WaitForChild("MobRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))

local DIAMETER = 7
local THICKNESS = 0.2
local LINE_WIDTH = 0.15
local LINES = 4 -- diâmetros cruzando o disco
local DISC_TRANSPARENCY = 0.6
local LINE_TRANSPARENCY = 0.2

local WebVisual = {}

type Web = { model: Model, root: BasePart }

local webs: { [Model]: Web } = {}
local started = false

local function makePart(name: string, size: Vector3, transparency: number, parent: Instance): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = Color3.new(1, 1, 1)
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = transparency
	part.Anchored = true
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function build(): Model
	local model = Instance.new("Model")
	model.Name = "WebVisual"
	local disc = makePart("Disc", Vector3.new(THICKNESS, DIAMETER, DIAMETER), DISC_TRANSPARENCY, model)
	disc.Shape = Enum.PartType.Cylinder
	model.PrimaryPart = disc
	for _ = 1, LINES do
		makePart("Line", Vector3.new(DIAMETER, THICKNESS, LINE_WIDTH), LINE_TRANSPARENCY, model)
	end
	model.Parent = Workspace
	return model
end

-- Pés do personagem: centro da raiz menos meia altura dela e a altura do quadril.
local function feetOf(character: Model, root: BasePart): Vector3
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local hip = if humanoid then humanoid.HipHeight else 0
	return root.Position - Vector3.new(0, root.Size.Y / 2 + hip - THICKNESS, 0)
end

local function place(web: Web, feet: Vector3)
	-- O cilindro tem o eixo no X: deita girando 90° em Z.
	local base = CFrame.new(feet)
	local lines = 0
	for _, child in web.model:GetChildren() do
		if child.Name == "Disc" and child:IsA("BasePart") then
			child.CFrame = base * CFrame.Angles(0, 0, math.pi / 2)
		elseif child:IsA("BasePart") then
			child.CFrame = base * CFrame.Angles(0, math.pi * lines / LINES, 0) * CFrame.new(0, THICKNESS, 0)
			lines += 1
		end
	end
end

local function remove(character: Model)
	local web = webs[character]
	if web then
		web.model:Destroy()
		webs[character] = nil
	end
end

local function update()
	local now = Workspace:GetServerTimeNow()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if
			character
			and root
			and root:IsA("BasePart")
			and MobRules.isWebbed(character:GetAttribute(StatNames.WebbedUntil), now)
		then
			local web = webs[character]
			if not web then
				web = { model = build(), root = root }
				webs[character] = web
			end
			place(web :: Web, feetOf(character, root))
		elseif character then
			remove(character)
		end
	end
	-- Personagens que saíram (morreram, jogador foi embora) levam a teia junto.
	for character, web in webs do
		if not character:IsDescendantOf(Workspace) or not web.root:IsDescendantOf(character) then
			remove(character)
		end
	end
end

function WebVisual.start()
	if started then
		return
	end
	started = true
	RunService.RenderStepped:Connect(update)
end

return WebVisual
