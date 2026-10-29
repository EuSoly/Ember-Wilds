--!strict
-- Alimenta a InputAction de mira com a direção do mouse.
--
-- No PC (teclado e mouse), a cada frame calcula onde o cursor toca o plano do
-- chão na altura do personagem e manda a direção (x, z) pela AimBinding.
-- Em qualquer outro dispositivo manda zero: o personagem vira para onde anda.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local InputNames = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InputNames"))

local MIN_AIM_LENGTH = 0.01

local AimController = {}

local function usesMouse(): boolean
	return UserInputService.PreferredInput == Enum.PreferredInput.KeyboardAndMouse
end

-- Ponto em que o raio do cursor cruza o plano horizontal y = height.
local function mouseOnPlane(height: number): Vector3?
	local camera = Workspace.CurrentCamera
	if not camera then
		return nil
	end
	local mouse = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(mouse.X, mouse.Y)
	if math.abs(ray.Direction.Y) < 1e-4 then
		return nil -- raio paralelo ao chão
	end
	local t = (height - ray.Origin.Y) / ray.Direction.Y
	if t <= 0 then
		return nil -- o plano está atrás da câmera
	end
	return ray.Origin + ray.Direction * t
end

local function updateAim(binding: InputBinding)
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not (root and root:IsA("BasePart")) then
		return
	end
	local point = mouseOnPlane(root.Position.Y)
	if not point then
		return -- mantém a última mira válida
	end
	local direction = Vector2.new(point.X - root.Position.X, point.Z - root.Position.Z)
	if direction.Magnitude < MIN_AIM_LENGTH then
		return -- cursor em cima do personagem: mantém a última mira
	end
	binding:Fire(direction.Unit)
end

function AimController.Start(_self)
	-- O servidor cria o contexto quando o jogador entra; espera numa thread
	-- própria para não travar o Start dos outros controladores.
	task.spawn(function()
		local context = Players.LocalPlayer:WaitForChild(InputNames.Context)
		local binding = context:WaitForChild(InputNames.Aim):WaitForChild(InputNames.AimBinding) :: InputBinding

		RunService.RenderStepped:Connect(function()
			if usesMouse() then
				updateAim(binding)
			end
		end)

		-- Trocou de dispositivo (ex.: pegou o gamepad): zera a mira uma vez.
		UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(function()
			if not usesMouse() then
				binding:Fire(Vector2.zero)
			end
		end)
	end)
end

return AimController
