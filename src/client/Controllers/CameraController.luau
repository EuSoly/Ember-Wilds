--!strict
-- Câmera top-down do jogo: fixa de cima, inclinada 65°, sem girar, seguindo o
-- personagem com suavização. Zoom curto pela roda do mouse ou pinça.
--
-- Sem personagem (menu e tela de morte), a câmera do menu: segue o jogador
-- que o servidor escolheu (atributo SpectateTarget, um pouco mais alta) ou,
-- sem ninguém vivo, gira devagar em volta do centro do mapa. A troca de alvo
-- fica suave pela mesma suavização do seguir.
--
-- Como a câmera nunca gira, "para cima" no joystick/WASD é sempre o -Z do mundo,
-- que aparece como o topo da tela.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local CameraMath = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("CameraMath"))
local StatNames = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("StatNames"))
local WorldConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("WorldConfig"))

local PITCH = 65 -- graus (90 seria olhar reto para baixo)
local DEFAULT_DISTANCE = 34
local MIN_DISTANCE = 28
local MAX_DISTANCE = 40
local FOLLOW_SHARPNESS = 12 -- maior = segue mais "colado" no personagem
local ZOOM_SHARPNESS = 10
local WHEEL_STEP = 2 -- studs por "clique" da roda
-- Câmera do menu.
local SPECTATE_EXTRA_DISTANCE = 6 -- um pouco mais alta ao assistir alguém
local ORBIT_SPEED = 6 -- graus por segundo, girando sem alvo
local YAW_SHARPNESS = 3 -- volta ao ângulo normal (câmera do jogo nunca gira)
-- Sem alvo, a câmera do menu gira em volta do centro da floresta (onde se nasce).
local MAP_CENTER = Vector3.new(WorldConfig.SPAWN.x, WorldConfig.SPAWN.y, WorldConfig.SPAWN.z)

local CameraController = {}

local focus: Vector3? = nil -- ponto que a câmera olha (suavizado)
local distance = DEFAULT_DISTANCE -- distância atual (suavizada)
local targetDistance = DEFAULT_DISTANCE
local pinchStartDistance = DEFAULT_DISTANCE

local function setTargetDistance(value: number)
	targetDistance = math.clamp(value, MIN_DISTANCE, MAX_DISTANCE)
end

-- Giro da câmera em volta do alvo (radianos). Só a câmera do menu sem alvo
-- gira; com alvo volta para a volta inteira mais próxima (0, 2π...), para
-- "para cima" no controle continuar sendo o topo da tela.
local yaw = 0

local function rootOf(player: Player?): BasePart?
	local character = player and player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

-- Jogador que o servidor mandou assistir (atributo do Player: chega no
-- cliente). O personagem dele pode nem ter chegado pelo streaming ainda.
local function spectateRoot(): BasePart?
	local userId = Players.LocalPlayer:GetAttribute(StatNames.SpectateTarget)
	if type(userId) ~= "number" or userId == 0 then
		return nil
	end
	return rootOf(Players:GetPlayerByUserId(userId))
end

type Mode = "own" | "spectate" | "orbit"

-- Para onde a câmera olha, a distância extra e o modo: o próprio personagem;
-- senão o jogador assistido; senão o centro do mapa, girando na distância máxima.
local function cameraTarget(): (Vector3, number, Mode)
	local own = rootOf(Players.LocalPlayer)
	if own then
		return own.Position, 0, "own"
	end
	local spectated = spectateRoot()
	if spectated then
		return spectated.Position, SPECTATE_EXTRA_DISTANCE, "spectate"
	end
	return MAP_CENTER, MAX_DISTANCE - targetDistance, "orbit"
end

local function updateYaw(mode: Mode, dt: number)
	if mode == "orbit" then
		yaw += math.rad(ORBIT_SPEED) * dt
		return
	end
	local rest = math.round(yaw / (2 * math.pi)) * 2 * math.pi
	if mode == "own" then
		-- Jogando, volta na hora: o movimento é relativo à câmera, e um giro
		-- voltando aos poucos entortaria os controles no começo da vida.
		yaw = rest
	else
		yaw += (rest - yaw) * CameraMath.smoothAlpha(YAW_SHARPNESS, dt)
	end
end

-- Só no Studio: Shift + P liga a câmera livre do Roblox (Freecam). Enquanto
-- ela está ligada, esta câmera fica pausada, senão as duas brigam pelo
-- CFrame a cada quadro e a Freecam não consegue se mover. Jogadores nunca
-- têm a Freecam, então fora do Studio isto não existe.
local devFreecam = false

local function connectDevFreecam()
	if not RunService:IsStudio() then
		return
	end
	UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		-- gameProcessed: um "P" maiúsculo digitado no chat não liga a câmera livre.
		if gameProcessed or input.KeyCode ~= Enum.KeyCode.P then
			return
		end
		if
			UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.RightShift)
		then
			devFreecam = not devFreecam
			-- Ao voltar, recomeça em cima do alvo (sem "viajar" de onde a Freecam parou).
			if not devFreecam then
				focus = nil
			end
		end
	end)
end

local function update(dt: number)
	local camera = Workspace.CurrentCamera
	if not camera or devFreecam then
		return
	end
	-- Os scripts padrão do Roblox podem trocar o tipo da câmera ao renascer.
	if camera.CameraType ~= Enum.CameraType.Scriptable then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	-- Sempre o alvo atual (troca sozinho depois de um respawn ou de uma troca
	-- de jogador assistido; a suavização deixa a troca macia).
	local target: Vector3, extraDistance: number, mode: Mode = cameraTarget()
	updateYaw(mode, dt)
	if focus == nil then
		focus = target -- primeiro frame: começa já em cima do alvo
	else
		focus = (focus :: Vector3):Lerp(target, CameraMath.smoothAlpha(FOLLOW_SHARPNESS, dt))
	end

	local wanted = targetDistance + extraDistance
	distance += (wanted - distance) * CameraMath.smoothAlpha(ZOOM_SHARPNESS, dt)
	local height, back = CameraMath.offset(PITCH, distance)
	-- yaw = 0 é a câmera de sempre (recuo em +Z); a câmera do menu gira o recuo.
	local position = (focus :: Vector3) + Vector3.new(math.sin(yaw) * back, height, math.cos(yaw) * back)
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
	connectDevFreecam()
	connectZoom()
	RunService:BindToRenderStep("TopDownCamera", Enum.RenderPriority.Camera.Value + 1, update)
end

return CameraController
