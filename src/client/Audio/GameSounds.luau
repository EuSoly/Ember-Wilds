--!strict
-- Liga os efeitos sonoros ao que acontece no jogo, usando só o que o cliente
-- já recebe (nenhum tráfego novo):
-- - bichos: contadores MobAttack/MobHurt e MobDead na raiz (tag Mob);
-- - peças e caixas: atributos do modelo (vida, porta, madeira, estoque, baú,
--   goles do poço) e a peça aparecer/sumir perto (colocou/quebrou);
-- - o próprio jogador: inventário (pegou item), craft, sede, fantasma, vida
--   baixa (batimento) e a tela (morreu);
-- - bonecos (o BonecoRenderer avisa: golpe no ar, dano, mordida).
-- Tudo por polling: com Server Authority o AttributeChanged não é confiável
-- (ver World/StructureHealth). Só as peças perto do ouvido são lidas.
-- Quem toca é o SoundPlayer (cooldown e limite de sons). Outros pontos que
-- tocam som direto: World/GatherFx (golpe em recurso), World/WaterRipples
-- (passo na água), UI/Notifications (avisos), Audio/UiSounds (cliques),
-- DragState (largar) e Screens/DeathScreen (subiu de nível).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Audio = Shared:WaitForChild("Audio")
local ChestRules = require(Shared:WaitForChild("Build"):WaitForChild("ChestRules"))
local SoundConfig = require(Audio:WaitForChild("SoundConfig"))
local SoundRules = require(Audio:WaitForChild("SoundRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))

local Client = script.Parent.Parent
local ChestState = require(Client:WaitForChild("ChestState"))
local CraftState = require(Client:WaitForChild("CraftState"))
local CrateState = require(Client:WaitForChild("CrateState"))
local InventoryState = require(Client:WaitForChild("InventoryState"))
local ScreenState = require(Client:WaitForChild("ScreenState"))
local SoundPlayer = require(script.Parent:WaitForChild("SoundPlayer"))

local POLL_EVERY = 0.1 -- s (os atributos dos bichos mudam a 10 Hz)
local NEAR_EVERY = 1 -- s entre refazer a lista de peças perto
local NEAR_RADIUS = SoundConfig.ROLLOFF_MAX + 15 -- studs: peças lidas no polling
-- Peça que aparece/some a até esta distância foi colocada/quebrada. Fica
-- abaixo do raio mínimo do streaming (64), que traz e leva peças sem ninguém
-- ter construído nada.
local BUILD_RADIUS = 50
local SETTLE_SECONDS = 3 -- s depois de nascer em que peça nova não faz som
local DRINK_JUMP = 8 -- pontos de sede de uma vez = bebeu (a água do lago sobe aos poucos)
local CRAFT_DONE_SLACK = 0.3 -- s: craft que some perto do fim terminou (não foi cancelado)
local LOW_HEALTH = 0.25

local GameSounds = {}

local started = false
local player = Players.LocalPlayer

local function known(key: string): boolean
	return SoundConfig.sounds[key] ~= nil
end

local function numberOf(instance: Instance, name: string): number?
	local value = instance:GetAttribute(name)
	return if type(value) == "number" and value == value then value else nil
end

-- Bonecos (chamados pelo BonecoRenderer) --------------------------------

-- Um golpe começou (acerte ou não): o "vupt" do braço.
function GameSounds.characterSwing(_character: Model, position: Vector3)
	SoundPlayer.play("swing", position)
end

-- Um boneco levou dano agora: no próprio jogador é 2D (sempre se ouve).
function GameSounds.characterHurt(character: Model, position: Vector3)
	if character == player.Character then
		SoundPlayer.play("hurt")
	else
		SoundPlayer.play("hit_player", position)
	end
end

-- Um boneco começou a comer.
function GameSounds.characterEat(_character: Model, position: Vector3)
	SoundPlayer.play("eat", position)
end

-- Bichos ----------------------------------------------------------------

type MobSeen = { attack: number?, hurt: number?, dead: boolean }
local mobs: { [Instance]: MobSeen } = {}

local function pollMobs(listener: Vector3)
	for root in mobs do
		if root.Parent == nil then
			mobs[root] = nil
		end
	end
	for _, root in CollectionService:GetTagged(StatNames.MobTag) do
		if not root:IsA("BasePart") or not root:IsDescendantOf(Workspace) then
			continue
		end
		local position = root.Position
		local seen = mobs[root]
		if (position - listener).Magnitude > NEAR_RADIUS then
			-- Longe: esquece, para não disparar tudo de uma vez ao chegar perto.
			mobs[root] = nil
			continue
		end
		local attack = numberOf(root, StatNames.MobAttack) or 0
		local hurt = numberOf(root, StatNames.MobHurt) or 0
		local dead = root:GetAttribute(StatNames.MobDead) == true
		if seen == nil then
			mobs[root] = { attack = attack, hurt = hurt, dead = dead }
			continue
		end
		local id = root:GetAttribute(StatNames.MobId)
		local mobId = if type(id) == "string" then id else ""
		if dead and not seen.dead then
			SoundPlayer.play(SoundRules.mobKey(mobId, "death", known), position)
		elseif not dead then
			if SoundRules.bumped(seen.hurt, hurt) then
				-- O golpe (carne) e a voz do bicho, se ele tiver.
				SoundPlayer.play("hit_mob", position)
				SoundPlayer.play(SoundRules.mobKey(mobId, "hurt", known), position)
			end
			if SoundRules.bumped(seen.attack, attack) then
				SoundPlayer.play(SoundRules.mobKey(mobId, "attack", known), position)
			end
		end
		seen.attack, seen.hurt, seen.dead = attack, hurt, dead
	end
end

-- Peças e caixas ----------------------------------------------------------

type Piece = {
	position: Vector3,
	structure: boolean, -- false = caixa de itens
	near: boolean,
	health: number?,
	door: boolean,
	wood: number?,
	stock: number?,
	chest: number?,
	drinks: number?,
}
local pieces: { [Instance]: Piece } = {}
local nearPieces: { Instance } = {}
local settledAt = math.huge -- os.clock a partir do qual peça nova/sumida faz som

local function positionOf(instance: Instance): Vector3?
	if instance:IsA("Model") then
		return instance:GetPivot().Position
	elseif instance:IsA("BasePart") then
		return instance.Position
	end
	return nil
end

local function chestCountOf(instance: Instance): number
	local total = 0
	for i = 1, ChestRules.SLOTS do
		total += numberOf(instance, StatNames.chestCount(i)) or 0
	end
	return total
end

local function read(instance: Instance, piece: Piece)
	piece.health = numberOf(instance, StatNames.StructureHealth)
	piece.door = instance:GetAttribute(StatNames.DoorOpen) == true
	piece.wood = numberOf(instance, StatNames.Wood)
	piece.stock = numberOf(instance, StatNames.Stock)
	piece.chest = chestCountOf(instance)
	piece.drinks = numberOf(instance, StatNames.Drinks)
end

-- Jogando e já passado o tempo de assentar (ao nascer, as peças em volta
-- chegam todas de uma vez pelo streaming).
local function buildSoundsOn(): boolean
	return vide.untrack(ScreenState.current) == "playing" and os.clock() >= settledAt
end

local function closeEnough(position: Vector3): boolean
	return (position - SoundPlayer.listenerPosition()).Magnitude <= BUILD_RADIUS
end

local function track(instance: Instance, structure: boolean)
	local position = positionOf(instance)
	if position == nil or pieces[instance] then
		return
	end
	local piece: Piece = { position = position, structure = structure, near = false, door = false }
	pieces[instance] = piece
	if structure and buildSoundsOn() and closeEnough(position) then
		SoundPlayer.play("place", position)
	end
end

local function untrack(instance: Instance)
	local piece = pieces[instance]
	if piece == nil then
		return
	end
	pieces[instance] = nil
	if piece.structure and buildSoundsOn() and closeEnough(piece.position) then
		SoundPlayer.play("structure_break", piece.position)
	end
end

local function refreshNear(listener: Vector3)
	table.clear(nearPieces)
	for instance, piece in pieces do
		if instance.Parent == nil then
			pieces[instance] = nil
			continue
		end
		local near = (piece.position - listener).Magnitude <= NEAR_RADIUS
		if near then
			-- Entrou no alcance: lê sem tocar (o que mudou longe não conta).
			if not piece.near then
				read(instance, piece)
			end
			table.insert(nearPieces, instance)
		end
		piece.near = near
	end
end

local function pollPieces()
	for _, instance in nearPieces do
		local piece = pieces[instance]
		if piece == nil or instance.Parent == nil then
			continue
		end
		local position = piece.position
		local health = numberOf(instance, StatNames.StructureHealth)
		if health and piece.health and health < piece.health then
			SoundPlayer.play("hit_structure", position)
		end
		local door = instance:GetAttribute(StatNames.DoorOpen) == true
		if door ~= piece.door then
			SoundPlayer.play(if door then "door_open" else "door_close", position)
		end
		local wood = numberOf(instance, StatNames.Wood)
		if wood and wood > (piece.wood or 0) then
			SoundPlayer.play("machine_wood", position)
		end
		local stock = numberOf(instance, StatNames.Stock)
		if stock and piece.stock and stock < piece.stock then
			SoundPlayer.play("machine_collect", position)
		end
		local chest = chestCountOf(instance)
		if chest ~= (piece.chest or 0) then
			SoundPlayer.play("chest_item", position)
		end
		local drinks = numberOf(instance, StatNames.Drinks)
		if drinks and piece.drinks and drinks < piece.drinks then
			SoundPlayer.play("drink", position)
		end
		piece.health, piece.door, piece.wood = health, door, wood
		piece.stock, piece.chest, piece.drinks = stock, chest, drinks
	end
end

-- O próprio jogador ---------------------------------------------------------

local lastSlots: { [number]: InventoryState.Item }? = nil
local lastCraft: CraftState.Current? = nil
local lastThirst: number? = nil
local lastGhost: number? = nil
local lastScreen = "loading"
local lastOpen: Instance? = nil -- baú ou caixa aberto (perto) agora
local quietUntil = 0 -- os.clock até quando o inventário mudar não faz som

local function pollPlayer()
	local now = os.clock()
	local screen: string = vide.untrack(ScreenState.current) :: any
	if screen ~= lastScreen then
		if screen == "dead" then
			SoundPlayer.play("death")
		elseif screen == "playing" then
			-- Nasceu: o inventário chega inteiro e as peças em volta também.
			quietUntil = now + 1.5
			settledAt = now + SETTLE_SECONDS
		end
		lastScreen = screen
	end
	local isPlaying = screen == "playing"

	-- Craft: começou / terminou (sumir antes do fim = cancelado, sem som).
	local craft = vide.untrack(CraftState.current)
	if craft ~= lastCraft then
		local finished = false
		if craft and (lastCraft == nil or craft.id ~= lastCraft.id or craft.start ~= lastCraft.start) then
			SoundPlayer.play("craft_start")
		elseif craft == nil and lastCraft then
			if Workspace:GetServerTimeNow() >= lastCraft.finish - CRAFT_DONE_SLACK then
				SoundPlayer.play("craft_done")
				finished = true
			end
		end
		if finished then
			-- O item pronto entra no inventário: não soma o "pop" de pegar.
			quietUntil = math.max(quietUntil, now + 0.4)
		end
		lastCraft = craft
	end

	-- Inventário: entrou item = "pop" (coleta, caixa, baú, extrator...).
	local slots = vide.untrack(InventoryState.slots)
	if slots ~= lastSlots then
		if lastSlots and isPlaying and now >= quietUntil and SoundRules.gained(lastSlots, slots) > 0 then
			SoundPlayer.play("pickup")
		end
		lastSlots = slots
	end

	-- Chegou perto de um baú ou de uma caixa: abriu (a tampa e o painel).
	local open: Instance? = vide.untrack(ChestState.near) or vide.untrack(CrateState.near)
	if open ~= lastOpen then
		if open and isPlaying then
			SoundPlayer.play("chest_open")
		end
		lastOpen = open
	end

	-- Sede subiu de uma vez: bebeu (garrafa, poço).
	local thirst = numberOf(player, StatNames.Thirst)
	if thirst and lastThirst and isPlaying and now >= quietUntil and thirst - lastThirst >= DRINK_JUMP then
		SoundPlayer.play("drink")
	end
	lastThirst = thirst

	-- Fantasma: virou (morreu com chance de voltar) e voltou (ressuscitou).
	local ghost = numberOf(player, StatNames.GhostUntil)
	if isPlaying then
		if ghost and lastGhost == nil then
			SoundPlayer.play("death")
		elseif ghost == nil and lastGhost then
			SoundPlayer.play("resurrect")
		end
	end
	lastGhost = ghost

	-- Vida baixa: batimento em loop.
	local health = numberOf(player, StatNames.Health) or StatNames.HealthMax
	SoundPlayer.setLoop(
		"heartbeat",
		isPlaying and ghost == nil and SoundRules.heartbeat(health, StatNames.HealthMax, LOW_HEALTH)
	)
end

-- Liga tudo (chamado uma vez pelo AudioController).
function GameSounds.start()
	if started then
		return
	end
	started = true

	local function watch(tag: string, structure: boolean)
		CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
			track(instance, structure)
		end)
		CollectionService:GetInstanceRemovedSignal(tag):Connect(untrack)
		for _, instance in CollectionService:GetTagged(tag) do
			track(instance, structure)
		end
	end
	watch(StatNames.StructureTag, true)
	watch(StatNames.CrateTag, false)

	local sincePoll, sinceNear = 0, NEAR_EVERY
	RunService.Heartbeat:Connect(function(dt: number)
		sincePoll += dt
		sinceNear += dt
		if sincePoll < POLL_EVERY then
			return
		end
		sincePoll = 0
		local listener = SoundPlayer.listenerPosition()
		if sinceNear >= NEAR_EVERY then
			sinceNear = 0
			refreshNear(listener)
		end
		pollMobs(listener)
		pollPieces()
		pollPlayer()
	end)
end

return GameSounds
