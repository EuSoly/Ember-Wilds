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

local GhostRules = require(ReplicatedStorage.Shared.Survival.GhostRules)
local ArmorRules = require(ReplicatedStorage.Shared.Survival.ArmorRules)
local BuildRules = require(ReplicatedStorage.Shared.Build.BuildRules)
local TeamRules = require(ReplicatedStorage.Shared.Build.TeamRules)
local CharacterBody = require(ReplicatedStorage.Shared.Models.CharacterBody)
local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local SurvivalConfig = require(ReplicatedStorage.Shared.SurvivalConfig)
local ArmorService = require(script.Parent.ArmorService)
local DeathService = require(script.Parent.DeathService)
local LastAttacker = require(script.Parent.LastAttacker)
local TutorialService = require(script.Parent.TutorialService)

local CharacterService = {}

-- "player" e "mob": golpes (combate). A peça de cabeça tira a defesa dela
-- contra jogador ou contra mob (Starve: golpe − defesa, nunca abaixo de 0);
-- golpe zerado pela defesa não faz nada. Careta sempre que o golpe passa.
-- "survival": barras vazias (a armadura não protege; careta no máximo a cada
-- SurvivalConfig.HURT_FLASH_EVERY, senão o boneco piscaria sem parar).
export type HurtKind = "player" | "mob" | "survival"

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
-- zerada = DeathService.kill(player, causeKey, attacker) (causeKey = chave de
-- Strings, ex. "death.cause.hunger"; attacker = jogador que bateu, só no golpe
-- de jogador: quem dá o golpe final é quem matou). Bonecos de teste (sem
-- jogador) só fazem a careta.
local healthLostListeners: { (Player, number) -> () } = {}
local attackedListeners: { (Player, Player) -> () } = {}

-- Aviso depois que a vida de um jogador baixou (qualquer causa): player, quanto.
function CharacterService.onHealthLost(listener: (player: Player, amount: number) -> ())
	table.insert(healthLostListeners, listener)
end

-- Aviso quando um jogador acerta outro (antes de defesa e protetores: acertar
-- já conta). Usado pela quest Mãos Limpas.
function CharacterService.onPlayerAttacked(listener: (attacker: Player, victim: Player) -> ())
	table.insert(attackedListeners, listener)
end

function CharacterService.hurt(character: Model, amount: number, causeKey: string, kind: HurtKind, attacker: Player?)
	-- `not (amount > 0)` também recusa NaN (NaN <= 0 seria false e passaria).
	if not (amount > 0) or character:FindFirstChildOfClass("Humanoid") == nil then
		return
	end
	local player = Players:GetPlayerFromCharacter(character)
	-- Fantasma não leva dano (GhostService).
	if player and GhostRules.isGhostPlayer(player, Workspace:GetServerTimeNow()) then
		return
	end
	-- Tutorial: nada machuca o jogador protegido (jogador, bicho, espinho, fome...).
	if player and TutorialService.isProtected(player) then
		return
	end
	-- Acertou um jogador de verdade (não fantasma nem protegido): conta para a
	-- quest Mãos Limpas mesmo que a defesa zere o dano.
	if player and kind == "player" and attacker and attacker ~= player then
		for _, listener in attackedListeners do
			task.spawn(listener, attacker, player)
		end
	end
	-- Último jogador que acertou a vítima (vale 10 s para quem matou, CombatTag):
	-- queda, afogamento etc. no meio da luta dão o abate a quem bateu. Colega de
	-- time também conta.
	if player and kind == "player" and attacker and attacker ~= player then
		LastAttacker.record(player, attacker, Workspace:GetServerTimeNow())
	end
	-- Colega de time tira só 30% (Starve; TeamService resolve os aliados).
	if player and kind == "player" and attacker and attacker ~= player then
		if BuildRules.areAllies(attacker.UserId, player.UserId) then
			amount = TeamRules.teamDamage(amount)
		end
	end
	if player and kind ~= "survival" then
		-- Escudo na mão (Starve): soma a defesa com a da peça de cabeça.
		local heldId = character:GetAttribute(StatNames.Equipped)
		local held = if type(heldId) == "string" then Defs.Items[heldId] else nil
		amount = ArmorRules.reduce(amount, ArmorService.modifiers(player), kind, held)
		if amount <= 0 then
			return
		end
	end

	local now = Workspace:GetServerTimeNow()
	local lastHurt = character:GetAttribute(StatNames.HurtAt)
	if kind ~= "survival" or type(lastHurt) ~= "number" or now - lastHurt >= SurvivalConfig.HURT_FLASH_EVERY then
		character:SetAttribute(StatNames.HurtAt, now)
	end

	if player then
		local current = player:GetAttribute(StatNames.Health)
		local health = if type(current) == "number" and current == current then current else StatNames.HealthMax
		local before = health
		health = math.max(health - amount, 0)
		player:SetAttribute(StatNames.Health, health)
		if health < before then
			for _, listener in healthLostListeners do
				task.spawn(listener, player, before - health)
			end
		end
		-- Só o personagem atual morre (um antigo, já trocado, não mata o novo).
		if health <= 0 and player.Character == character then
			DeathService.kill(player, causeKey, attacker)
		end
	end
end

-- Último atacante jogador da vítima e a hora (GetServerTimeNow) do golpe.
function CharacterService.lastAttacker(player: Player): (Player?, number?)
	return LastAttacker.get(player)
end

local function setupCharacter(character: Model)
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid
	CharacterService.prepare(character)
	humanoid.AutoRotate = false
	humanoid.UseJumpPower = false
	humanoid.JumpHeight = 0
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		-- Personagem novo: o golpe do anterior não vale mais.
		LastAttacker.clear(player)
		setupCharacter(character)
	end)
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
	Players.PlayerRemoving:Connect(LastAttacker.clear)
	-- Jogadores que entraram antes deste Start (ex.: no Play Solo do Studio).
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
end

return CharacterService
