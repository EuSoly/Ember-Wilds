--!strict
-- Personagem do jogo = corpo simulado mínimo e invisível (CharacterBody), igual
-- para todos (mesmo hitbox no PvP; não há mais avatar do Roblox). O visual é
-- o boneco que cada cliente monta para os personagens com a tag Boneco.
-- - Init: registra o grupo de colisão dos bonecos (não colidem entre si) e
--   coloca o StarterCharacter em StarterPlayer antes do primeiro spawn.
-- - Todo personagem nasce sem pulo e sem rotação automática (quem gira é a
--   simulação de mira, FacingSim).
-- - hurt(): a função única de dano (marca HurtAt para a careta e tira vida).
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local StarterPlayer = game:GetService("StarterPlayer")
local Workspace = game:GetService("Workspace")

local CharacterBody = require(ReplicatedStorage.Shared.Models.CharacterBody)
local StatNames = require(ReplicatedStorage.Shared.StatNames)

local CharacterService = {}

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
-- e, se for de um jogador, tira `amount` do atributo Health do Player.
-- Hoje só o comando de dev chama; nas fases G, combate/fome/frio.
function CharacterService.hurt(character: Model, amount: number)
	-- `not (amount > 0)` também recusa NaN (NaN <= 0 seria false e passaria).
	if not (amount > 0) or character:FindFirstChildOfClass("Humanoid") == nil then
		return
	end
	character:SetAttribute(StatNames.HurtAt, Workspace:GetServerTimeNow())
	local player = Players:GetPlayerFromCharacter(character)
	if player then
		local health = (player:GetAttribute(StatNames.Health) :: number?) or StatNames.StatusMax
		player:SetAttribute(StatNames.Health, math.max(health - amount, 0))
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
