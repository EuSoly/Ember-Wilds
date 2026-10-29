--!strict
-- Câmera top-down do jogo: fixa de cima, inclinada 65°, sem girar, seguindo o
-- personagem com suavização. Zoom curto pela roda do mouse ou pinça.
--
-- Como a câmera nunca gira, "para cima" no joystick/WASD é sempre o -Z do mundo,
-- que aparece como o topo da tela.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CameraMath = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CameraMath"))

local PITCH = 65 -- graus (90 seria olhar reto para baixo)
local DEFAULT_DISTANCE = 34
local MIN_DISTANCE = 28
local MAX_DISTANCE = 40
local FOLLOW_SHARPNESS = 12 -- maior = segue mais "colado" no personagem
local ZOOM_SHARPNESS = 10
local WHEEL_STEP = 2 -- studs por "clique" da roda

local CameraController = {}

local focus: Vector3? = nil -- ponto que a câmera olha (suavizado)
local distance = DEFAULT_DISTANCE -- distância atual (suavizada)
local targetDistance = DEFAULT_DISTANCE
local pinchStartDistance = DEFAULT_DISTANCE

local function setTargetDistance(value: number)
	targetDistance = math.clamp(value, MIN_DISTANCE, MAX_DISTANCE)
end

local function currentRoot(): BasePart?
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function update(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera then
		return
	end
	-- Os scripts padrão do Roblox podem trocar o tipo da câmera ao renascer.
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	-- Sempre o personagem atual (troca sozinho depois de um respawn).
	-- Sem personagem, a câmera fica parada onde estava.
	local root = currentRoot()
	if root then
		local target = root.Position
		if focus == nil then
			focus = target -- primeiro frame: começa já em cima do personagem
		else
			focus = (focus :: Vector3):Lerp(target, CameraMath.smoothAlpha(FOLLOW_SHARPNESS, dt))
		end
	end
	if focus == nil then
		return
	end

	distance += (targetDistance - distance) * CameraMath.smoothAlpha(ZOOM_SHARPNESS, dt)
	local height, back = CameraMath.offset(PITCH, distance)
	local position = (focus :: Vector3) + Vector3.new(0, height, back)
	camera.CFrame = CFrame.lookAt(position, focus :: Vector3)
end

local function connectZoom()
	UserInputService.InputChanged:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseWheel then
			setTargetDistance(targetDistance - input.Position.Z * WHEEL_STEP)
		end
	end)

	UserInputService.TouchPinch:Connect(function(_positions, scale, _velocity, state, gameProcessed)
		if gameProcessed then
			return
		end
		if state == Enum.UserInputState.Begin then
			pinchStartDistance = targetDistance
		elseif scale > 0 then
			-- Abrir os dedos (scale > 1) aproxima a câmera.
			setTargetDistance(pinchStartDistance / scale)
		end
	end)
end

function CameraController.Start(_self)
	connectZoom()
	RunService:BindToRenderStep("TopDownCamera", Enum.RenderPriority.Camera.Value + 1, update)
end

return CameraController
