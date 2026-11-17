--!strict
-- Bolha de proteção do revive: uma esfera translúcida em volta de quem tem o
-- atributo SpawnShieldUntil no futuro (relógio do servidor). O atributo vem
-- do MODELO do personagem e é lido por POLLING a cada quadro (regra do
-- projeto: com Server Authority o sinal de mudança não é confiável). A esfera
-- é só do cliente.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local ReviveRules = require(Shared:WaitForChild("Survival"):WaitForChild("ReviveRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))

local DIAMETER = 9 -- studs
local BASE_TRANSPARENCY = 0.65
local FADE_SECONDS = 0.6 -- no fim a bolha some aos poucos
local COLOR = Color3.fromRGB(255, 190, 90)

local SpawnShieldFx = {}

local bubbles: { [Player]: Part } = {}

local function newBubble(): Part
	local part = Instance.new("Part")
	part.Name = "SpawnShieldBubble"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(DIAMETER, DIAMETER, DIAMETER)
	part.Material = Enum.Material.ForceField
	part.Color = COLOR
	part.Transparency = BASE_TRANSPARENCY
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = Workspace
	return part
end

local function drop(player: Player)
	local bubble: Part? = bubbles[player]
	if bubble then
		bubble:Destroy()
		bubbles[player] = nil
	end
end

-- Liga a bolha (chamado uma vez pelo WorldFxController).
function SpawnShieldFx.start()
	Players.PlayerRemoving:Connect(drop)
	RunService.RenderStepped:Connect(function()
		local now = Workspace:GetServerTimeNow()
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local untilAt = character and character:GetAttribute(StatNames.SpawnShieldUntil)
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if ReviveRules.shielded(untilAt, now) and root and root:IsA("BasePart") then
				local bubble: Part = bubbles[player] or newBubble()
				bubbles[player] = bubble
				local left = (untilAt :: number) - now
				bubble.CFrame = root.CFrame
				bubble.Transparency = BASE_TRANSPARENCY
					+ (1 - BASE_TRANSPARENCY) * (1 - math.clamp(left / FADE_SECONDS, 0, 1))
			else
				drop(player)
			end
		end
	end)
end

return SpawnShieldFx
