--!strict
-- SÓ PARA DESENVOLVIMENTO (roda apenas no Studio).
-- Comandos para testar o boneco (use na barra de comandos do Studio, lado servidor):
-- - ServerStorage.DevHurt:Invoke(player, 10): dano no jogador (careta + flash).
-- - ServerStorage.DevCosmetic:Invoke(player, "body_ember") -> boolean: troca a skin.
-- - ServerStorage.DevCrowd:Invoke(30) -> number: cria 30 bonecos de teste andando
--   em círculo, batendo, trocando o item na mão e levando dano (0 = só apaga).
--   São criados no servidor para testar o caminho real de replicação.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local BonecoConfig = require(ReplicatedStorage.Shared.BonecoConfig)
local CharacterBody = require(ReplicatedStorage.Shared.Models.CharacterBody)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local CharacterService = require(script.Parent.CharacterService)
local CosmeticService = require(script.Parent.CosmeticService)

local CROWD_FOLDER = "DevCrowd"
local CROWD_CENTER = Vector3.new(0, 0, 40)
local CROWD_RADIUS = 24
local CROWD_SKINS = { "body_default", "body_ember" }
local TICK = 0.2 -- segundos entre atualizações da multidão
local STEP_ANGLE = math.rad(20) -- quanto à frente no círculo cada boneco mira
local USE_PERIOD = 3 -- Using ligado metade do tempo (1,5 s) e desligado a outra metade
local EQUIP_PERIOD = 6 -- troca o item na mão a cada 6 s
local HURT_PERIOD = 5 -- dano a cada ~5 s

type Member = { model: Model, humanoid: Humanoid, root: BasePart, nextHurt: number }

local DevBonecoService = {}

local crowd: { Member } = {}
local crowdThread: thread? = nil

local function pointOnCircle(angle: number): Vector3
	return CROWD_CENTER + Vector3.new(math.cos(angle) * CROWD_RADIUS, 0, math.sin(angle) * CROWD_RADIUS)
end

local function clearCrowd()
	if crowdThread then
		task.cancel(crowdThread)
		crowdThread = nil
	end
	table.clear(crowd)
	local folder = Workspace:FindFirstChild(CROWD_FOLDER)
	if folder then
		folder:Destroy()
	end
end

local function setIfChanged(model: Model, name: string, value: any)
	if model:GetAttribute(name) ~= value then
		model:SetAttribute(name, value)
	end
end

-- Uma única thread move e anima todos os bonecos de teste.
local function runCrowd()
	local start = os.clock()
	while true do
		local now = os.clock()
		local t = now - start
		local using = t % USE_PERIOD < USE_PERIOD / 2
		local equipped = if math.floor(t / EQUIP_PERIOD) % 2 == 0 then "wood_pickaxe" else nil
		for _, member in crowd do
			if member.model.Parent == nil then
				continue
			end
			local offset = member.root.Position - CROWD_CENTER
			local angle = math.atan2(offset.Z, offset.X)
			member.humanoid:MoveTo(pointOnCircle(angle + STEP_ANGLE))
			setIfChanged(member.model, StatNames.Using, using)
			setIfChanged(member.model, StatNames.Equipped, equipped)
			if now >= member.nextHurt then
				CharacterService.hurt(member.model, 5)
				member.nextHurt = now + HURT_PERIOD + (math.random() - 0.5)
			end
		end
		task.wait(TICK)
	end
end

local function spawnCrowd(count: number): number
	clearCrowd()
	if count <= 0 then
		return 0
	end

	local folder = Instance.new("Folder")
	folder.Name = CROWD_FOLDER
	folder.Parent = Workspace

	local rootY = BonecoConfig.HIP_HEIGHT + BonecoConfig.ROOT_HEIGHT / 2
	for i = 1, count do
		local model = CharacterBody.build()
		model.Name = `Boneco {i}`
		local humanoid = model:FindFirstChildOfClass("Humanoid") :: Humanoid
		local root = model.PrimaryPart :: BasePart
		-- Sem jogador para girar pela mira: vira para onde anda.
		humanoid.AutoRotate = true

		local angle = (i - 1) / count * 2 * math.pi
		local position = pointOnCircle(angle) + Vector3.new(0, rootY, 0)
		model:PivotTo(CFrame.lookAt(position, pointOnCircle(angle + STEP_ANGLE) + Vector3.new(0, rootY, 0)))

		model:SetAttribute(StatNames.CosmeticPrefix .. "body", CROWD_SKINS[(i - 1) % #CROWD_SKINS + 1])
		CharacterService.prepare(model)
		model.Parent = folder

		-- Cada boneco leva dano num momento diferente.
		table.insert(crowd, {
			model = model,
			humanoid = humanoid,
			root = root,
			nextHurt = os.clock() + HURT_PERIOD * (i / count),
		})
	end

	crowdThread = task.spawn(runCrowd)
	return #crowd
end

local function newCommand(name: string, onInvoke: (...any) -> ...any)
	local command = Instance.new("BindableFunction")
	command.Name = name
	command.OnInvoke = onInvoke
	command.Parent = ServerStorage
end

function DevBonecoService.Start(_self)
	if not RunService:IsStudio() then
		return
	end

	newCommand("DevHurt", function(player: Player, amount: number)
		if player.Character then
			CharacterService.hurt(player.Character, amount)
		end
	end)

	newCommand("DevCosmetic", function(player: Player, cosmeticId: string): boolean
		return CosmeticService.equip(player, cosmeticId)
	end)

	newCommand("DevCrowd", function(count: number): number
		return spawnCrowd(math.floor(count or 0))
	end)
end

return DevBonecoService
