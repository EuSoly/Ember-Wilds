--!strict
-- Água dentro da simulação do Server Authority: quem está dentro de uma peça
-- de Workspace.Map/Water anda mais devagar (WorldConfig.WATER_SPEED_FACTOR).
-- Roda nos dois lados, como o FacingSim (servidor = autoridade, cliente =
-- predição): a velocidade muda junto nos dois e não há correção visível.
--
-- "Dentro" é visto de cima (X/Z), com as formas do Shapes. As peças de água
-- ficam num cache que se atualiza quando elas entram e saem: no cliente elas
-- chegam aos poucos pelo streaming.
-- WaterSim.isInWater(player) diz o último resultado (o WaterService usa para
-- o fôlego e o atributo InWater).
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local MapShapes = require("../World/MapShapes")
local Shapes = require("../World/Shapes")
local WorldConfig = require("../WorldConfig")

local WaterSim = {}

local waterShapes: { [BasePart]: Shapes.Shape } = {}
local inWater: { [Player]: boolean } = {}
local watching = false

local function track(instance: Instance)
	if instance:IsA("BasePart") then
		-- Formas inválidas já são avisadas pelo MapService no servidor.
		local shape = MapShapes.fromPart(instance)
		if shape then
			waterShapes[instance] = shape
		end
	end
end

-- Acompanha Workspace.Map.Water quando (e se) ele existir.
local function startWatching()
	if watching then
		return
	end
	watching = true
	task.spawn(function()
		local map = Workspace:WaitForChild("Map", math.huge)
		local water = map:WaitForChild("Water", math.huge)
		for _, descendant in water:GetDescendants() do
			track(descendant)
		end
		water.DescendantAdded:Connect(track)
		water.DescendantRemoving:Connect(function(descendant)
			if descendant:IsA("BasePart") then
				waterShapes[descendant] = nil
			end
		end)
	end)
	Players.PlayerRemoving:Connect(function(player)
		inWater[player] = nil
	end)
end

local function isWet(x: number, z: number): boolean
	for _, shape in waterShapes do
		if Shapes.contains(shape, x, z) then
			return true
		end
	end
	return false
end

-- Último resultado da simulação para o jogador (false sem personagem).
function WaterSim.isInWater(player: Player): boolean
	return inWater[player] == true
end

-- Liga a água na simulação. `getPlayers` diz quais jogadores este lado simula.
function WaterSim.start(getPlayers: () -> { Player }): RBXScriptConnection
	startWatching()
	local slowSpeed = WorldConfig.WALK_SPEED * WorldConfig.WATER_SPEED_FACTOR
	return RunService:BindToSimulation(function()
		for _, player in getPlayers() do
			local character = player.Character
			local root = character and character:FindFirstChild("HumanoidRootPart")
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			if not (root and root:IsA("BasePart") and humanoid) then
				inWater[player] = nil
				continue
			end
			local wet = isWet(root.Position.X, root.Position.Z)
			inWater[player] = wet
			local speed = if wet then slowSpeed else WorldConfig.WALK_SPEED
			-- Só escreve quando muda (não replica à toa).
			if humanoid.WalkSpeed ~= speed then
				humanoid.WalkSpeed = speed
			end
		end
	end, Enum.StepFrequency.Hz60)
end

return WaterSim
