--!strict
-- Câmera do menu: quem está sem personagem vivo (no menu ou na tela de morte)
-- "assiste" um jogador vivo aleatório. O servidor escolhe o alvo e grava o
-- UserId no atributo SpectateTarget do Player (0 = ninguém); o cliente só segue
-- o que o atributo diz (CameraController).
--
-- Também aponta o foco de streaming (Player.ReplicationFocus) para a raiz do
-- alvo, senão o mapa em volta dele não chegaria ao cliente; sem alvo, para uma
-- âncora invisível no centro do mapa. Jogador vivo: SpectateTarget = 0 e foco nil
-- (o streaming volta a seguir o próprio personagem).
--
-- O alvo troca a cada SWITCH_SECONDS (uma única thread) e, entre as trocas, só
-- muda se o atual morrer ou sair. Bonecos de teste não contam (não são jogadores).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local StatNames = require(ReplicatedStorage.Shared.StatNames)
local WorldConfig = require(ReplicatedStorage.Shared.WorldConfig)

local SWITCH_SECONDS = 8

local SpectateService = {}

local anchor: Part
local refreshQueued = false

local function rootOf(player: Player): BasePart?
	local character = player.Character
	if character == nil then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid == nil or humanoid.Health <= 0 then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function aliveOthers(viewer: Player): { Player }
	local list: { Player } = {}
	for _, other in Players:GetPlayers() do
		-- Parent ~= Players: está saindo (o PlayerRemoving ainda não terminou).
		if other ~= viewer and other.Parent == Players and rootOf(other) ~= nil then
			table.insert(list, other)
		end
	end
	return list
end

local function setTarget(viewer: Player, target: Player?)
	local userId = if target then target.UserId else 0
	if viewer:GetAttribute(StatNames.SpectateTarget) ~= userId then
		viewer:SetAttribute(StatNames.SpectateTarget, userId)
	end
	local focus: Instance = if target then rootOf(target) :: BasePart else anchor
	if viewer.ReplicationFocus ~= focus then
		viewer.ReplicationFocus = focus
	end
end

-- Recalcula o alvo de todos. rotate = true na troca periódica: escolhe outro
-- (diferente do atual, se houver mais de um vivo); false = só corrige quem
-- ficou sem alvo válido.
local function refreshAll(rotate: boolean)
	for _, viewer in Players:GetPlayers() do
		if rootOf(viewer) ~= nil then
			-- Vivo: joga com a própria câmera e o próprio streaming.
			if viewer:GetAttribute(StatNames.SpectateTarget) ~= 0 then
				viewer:SetAttribute(StatNames.SpectateTarget, 0)
			end
			if viewer.ReplicationFocus ~= nil then
				viewer.ReplicationFocus = nil
			end
			continue
		end

		local candidates = aliveOthers(viewer)
		local currentId = viewer:GetAttribute(StatNames.SpectateTarget)
		local current: Player? = nil
		for _, candidate in candidates do
			if candidate.UserId == currentId then
				current = candidate
			end
		end

		if current ~= nil and not rotate then
			setTarget(viewer, current) -- mantém (atualiza o foco se a raiz mudou)
		elseif #candidates == 0 then
			setTarget(viewer, nil)
		else
			local pool = candidates
			if current ~= nil and #candidates > 1 then
				pool = {}
				for _, candidate in candidates do
					if candidate ~= current then
						table.insert(pool, candidate)
					end
				end
			end
			setTarget(viewer, pool[math.random(1, #pool)])
		end
	end
end

-- Vários eventos no mesmo quadro (morreu + personagem removido) viram um só.
local function queueRefresh()
	if refreshQueued then
		return
	end
	refreshQueued = true
	task.defer(function()
		refreshQueued = false
		refreshAll(false)
	end)
end

local function setupCharacter(character: Model)
	queueRefresh()
	local humanoid = character:WaitForChild("Humanoid", 10) :: Humanoid?
	if humanoid then
		humanoid.Died:Connect(queueRefresh)
	end
end

local function setupPlayer(player: Player)
	player:SetAttribute(StatNames.SpectateTarget, 0)
	player.CharacterAdded:Connect(setupCharacter)
	player.CharacterRemoving:Connect(queueRefresh)
	-- A morte (DeathService.kill) zera player.Character antes de destruir o
	-- corpo: reagir à propriedade troca os alvos na hora.
	player:GetPropertyChangedSignal("Character"):Connect(queueRefresh)
	if player.Character then
		task.spawn(setupCharacter, player.Character)
	end
	queueRefresh()
end

function SpectateService.Start(_self)
	-- Âncora do foco de streaming sem alvo: centro da floresta (SPAWN), invisível e sem
	-- colisão/consulta/toque (não atrapalha nada no mundo).
	anchor = Instance.new("Part")
	anchor.Name = "SpectateAnchor"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.CanTouch = false
	anchor.Transparency = 1
	anchor.Size = Vector3.new(1, 1, 1)
	anchor.Position = Vector3.new(WorldConfig.SPAWN.x, WorldConfig.SPAWN.y, WorldConfig.SPAWN.z)
	anchor.Parent = Workspace

	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	Players.PlayerRemoving:Connect(queueRefresh)

	task.spawn(function()
		while true do
			task.wait(SWITCH_SECONDS)
			refreshAll(true)
		end
	end)
end

return SpectateService
