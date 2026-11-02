--!strict
-- Personagem do jogo = corpo simulado mínimo e invisível (CharacterBody), igual
-- para todos (mesmo hitbox no PvP; não há mais avatar do Roblox). O visual é
-- o boneco que cada cliente monta para os personagens com a tag Boneco.
-- - Init: registra o grupo de colisão dos bonecos (não colidem entre si) e
--   coloca o StarterCharacter em StarterPlayer antes do primeiro spawn.
-- - Todo personagem nasce sem pulo e sem rotação automática (quem gira é a
--   simulação de mira, FacingSim).
-- - hurt(): a função única de dano (combate e sobrevivência): marca HurtAt
--   para a careta, tira vida e, com a vida zerada, chama DeathService.kill.
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local ArmorRules = require(ReplicatedStorage.Shared.Survival.ArmorRules)
local CharacterBody = require(ReplicatedStorage.Shared.Models.CharacterBody)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local SurvivalConfig = require(ReplicatedStorage.Shared.SurvivalConfig)
local ArmorService = require(script.Parent.ArmorService)
local DeathService = require(script.Parent.DeathService)

local CharacterService = {}

-- "combat": golpes de jogadores e mobs (a armadura corta; careta sempre).
-- "survival": barras vazias (a armadura não protege; careta no máximo a cada
-- SurvivalConfig.HURT_FLASH_EVERY, senão o boneco piscaria sem parar).
export type HurtKind = "combat" | "survival"

-- Configuração comum a jogadores e bonecos de teste (DevBonecoService):
-- a tag faz o cliente montar o boneco visual, e o nome padrão do Roblox some
-- (o boneco visual tem a própria etiqueta).
function CharacterService.prepare(character: Model)
	CollectionService:AddTag(character, StatNames.BonecoTag)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
end

-- Dano num personagem: grava HurtAt (o visual de todos mostra "> <" e o flash)
-- e, se for de um jogador, tira `amount` do atributo Health do Player. Vida
-- zerada = DeathService.kill(player, causeKey) (causeKey = chave de Strings,
-- ex. "death.cause.hunger"). Bonecos de teste (sem jogador) só fazem a careta.
function CharacterService.hurt(character: Model, amount: number, causeKey: string, kind: HurtKind)
	-- `not (amount > 0)` também recusa NaN (NaN <= 0 seria false e passaria).
	if not (amount > 0) or character:FindFirstChildOfClass("Humanoid") == nil then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	if player and kind == "combat" then
		amount = ArmorRules.reduce(amount, ArmorService.modifiers(player))
	end

	local now = Workspace:GetServerTimeNow()
	local lastHurt = character:GetAttribute(StatNames.HurtAt)
	if kind == "combat" or type(lastHurt) ~= "number" or now - lastHurt >= SurvivalConfig.HURT_FLASH_EVERY then
		character:SetAttribute(StatNames.HurtAt, now)
	end

	if player then
		local current = player:GetAttribute(StatNames.Health)
		local health = if type(current) == "number" and current == current then current else StatNames.HealthMax
		health = math.max(health - amount, 0)
		player:SetAttribute(StatNames.Health, health)
		-- Só o personagem atual morre (um antigo, já trocado, não mata o novo).
		if health <= 0 and player.Character == character then
			DeathService.kill(player, causeKey)
		end
	end
end

local function setupCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	CharacterService.prepare(character)
	humanoid.AutoRotate = false
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = 0
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(setupCharacter)
	if player.Character then
		task.spawn(setupCharacter, player.Character)
	end
end

function CharacterService.Init(_self)
	-- Bonecos não colidem entre si (pedido de design): o grupo do corpo simulado
	-- só desliga a colisão consigo mesmo; com o mundo continua colidindo.
	local group = StatNames.BonecoCollisionGroup
	if not PhysicsService:IsCollisionGroupRegistered(group) then
		PhysicsService:RegisterCollisionGroup(group)
	end
	PhysicsService:CollisionGroupSetCollidable(group, group, false)

	-- Precisa estar em StarterPlayer antes do primeiro spawn para valer já nele.
	local old = StarterPlayer:FindFirstChild("StarterCharacter")
	if old then
		old:Destroy()
	end
	CharacterBody.build().Parent = StarterPlayer
end

function CharacterService.Start(_self)
	Players.PlayerAdded:Connect(setupPlayer)
	-- Jogadores que entraram antes deste Start (ex.: no Play Solo do Studio).
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
end

return CharacterService
