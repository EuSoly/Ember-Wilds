--!strict
-- Gira o personagem dentro da simulação do Server Authority.
--
-- Roda nos dois lados: o servidor simula todos os jogadores (autoridade) e o
-- cliente simula só o próprio personagem (predição, para não ter atraso).
-- Como é a mesma função dos dois lados, o resultado bate e não há correção visível.
--
-- Regra de orientação (spec, seção 5):
-- - com mira (PC): vira para a direção da mira, mesmo andando para outro lado;
-- - sem mira (celular/gamepad): vira para onde está andando;
-- - parado e sem mira: mantém a direção atual.
local RunService = game:GetService("RunService")

local Facing = require("../Facing")
local InputNames = require("../InputNames")

-- Velocidade máxima de giro: rápida o bastante para parecer instantânea no
-- mouse, mas sem "teleportar" o personagem de um lado para o outro.
local TURN_SPEED = math.rad(900) -- graus por segundo
local DEFAULT_DT = 1 / 60

local FacingSim = {}

local function readAim(player: Player): Vector2?
	local context = player:FindFirstChild(InputNames.Context)
	local action = context and context:FindFirstChild(InputNames.Aim)
	if action and action:IsA("InputAction") then
		local state = action:GetState()
		if typeof(state) == "Vector2" then
			return state
		end
	end
	return nil
end

local function stepPlayer(player: Player, dt: number)
	-- Sempre o personagem atual: depois de um respawn a referência antiga não vale.
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not (root and root:IsA("BasePart") and humanoid) then
		return
	end

	local aim = readAim(player) or Vector2.zero
	local move = humanoid.MoveDirection
	local isAlive = humanoid.Health > 0
	local targetYaw = Facing.desiredYaw(isAlive, aim.X, aim.Y, move.X, move.Z)
	if targetYaw == nil then
		return -- morto, ou parado e sem mira: não mexe na rotação
	end

	local look = root.CFrame.LookVector
	local currentYaw = math.atan2(-look.X, -look.Z)
	local newYaw = Facing.stepYaw(currentYaw, targetYaw, TURN_SPEED * dt)
	-- Troca só a rotação; a posição continua a que a física calculou.
	root.CFrame = CFrame.new(root.Position) * CFrame.Angles(0, newYaw, 0)
end

-- Liga a rotação na simulação. `getPlayers` diz quais jogadores este lado simula.
function FacingSim.start(getPlayers: () -> { Player }): RBXScriptConnection
	return RunService:BindToSimulation(function(deltaTime: number?)
		local dt = deltaTime or DEFAULT_DT
		for _, player in getPlayers() do
			stepPlayer(player, dt)
		end
	end, Enum.StepFrequency.Hz60)
end

return FacingSim
