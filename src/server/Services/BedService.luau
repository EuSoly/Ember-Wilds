--!strict
-- Cama (G8). `sleep` na cama (InteractService, já conferido) deita o jogador:
-- atributo Sleeping = true no personagem (olhos fechados em todos os clientes),
-- a raiz vai para a cama e o SurvivalService passa a usar os fatores da cama
-- (regenFactor / drainFactor). Dormindo ele ainda pode ser atacado.
--
-- Levanta quando: anda (a raiz se afasta de onde deitou, conferido num laço do
-- servidor), leva dano (HurtAt ou vida caindo), a cama some, ou morre/troca de
-- personagem. Atributos do personagem se leem por polling, nunca por
-- AttributeChanged. Quem dorme só existe aqui no servidor, por jogador.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InteractRules = require(ReplicatedStorage.Shared.Build.InteractRules)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local InteractService = require(script.Parent.InteractService)
local StructureService = require(script.Parent.StructureService)
local SurvivalService = require(script.Parent.SurvivalService)

local CHECK_INTERVAL = 0.2 -- segundos entre conferências de quem dorme
local LIE_HEIGHT = 3 -- studs acima do centro da cama onde a raiz fica
local WAKE_DISTANCE = 0.5 -- studs (plano XZ) de deslocamento que levantam
-- Logo depois de deitar o teleporte ainda pode estar chegando: a posição de
-- referência é reamostrada até esse tempo passar.
local SETTLE_TIME = 0.6

type Entry = StructureService.Entry
type Sleeper = {
	entry: Entry,
	character: Model,
	x: number, -- onde deitou (referência do movimento)
	z: number,
	since: number,
	hurtAt: any, -- HurtAt quando deitou
	health: any, -- vida quando deitou
}

local sleepers: { [Player]: Sleeper } = {}

local BedService = {}

local function rootOf(character: Model): BasePart?
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function wake(player: Player)
	local sleeper = sleepers[player]
	if sleeper == nil then
		return
	end
	sleepers[player] = nil
	SurvivalService.setSleep(player, nil)
	if sleeper.character.Parent ~= nil then
		sleeper.character:SetAttribute(StatNames.Sleeping, nil)
	end
end

local function lieDown(player: Player, entry: Entry)
	local bed = entry.def.bed
	local character = player.Character
	local root = if character then rootOf(character) else nil
	if bed == nil or character == nil or root == nil or sleepers[player] ~= nil then
		return
	end
	local target = entry.model:GetPivot().Position + Vector3.new(0, LIE_HEIGHT, 0)
	character:PivotTo(CFrame.new(target))
	sleepers[player] = {
		entry = entry,
		character = character,
		x = target.X,
		z = target.Z,
		since = os.clock(),
		hurtAt = character:GetAttribute(StatNames.HurtAt),
		health = player:GetAttribute(StatNames.Health),
	}
	character:SetAttribute(StatNames.Sleeping, true)
	SurvivalService.setSleep(player, bed)
end

local function onBed(player: Player, entry: Entry, action: number, _arg: number)
	if action == InteractRules.ACTIONS.sleep then
		lieDown(player, entry)
	end
end

-- true se o jogador deve levantar agora.
local function shouldWake(player: Player, sleeper: Sleeper, now: number): boolean
	local character = player.Character
	if character == nil or player.Parent ~= Players or character ~= sleeper.character or character.Parent == nil then
		return true
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = rootOf(character)
	if humanoid == nil or humanoid.Health <= 0 or root == nil then
		return true
	end
	if StructureService.entryOf(sleeper.entry.model) ~= sleeper.entry then
		return true
	end
	-- Dano: HurtAt novo, ou vida abaixo da de antes (a regeneração só sobe).
	if character:GetAttribute(StatNames.HurtAt) ~= sleeper.hurtAt then
		return true
	end
	local health = player:GetAttribute(StatNames.Health)
	if type(health) == "number" then
		if type(sleeper.health) == "number" and health < sleeper.health then
			return true
		end
		sleeper.health = health
	end
	local position = root.Position
	if now - sleeper.since < SETTLE_TIME then
		sleeper.x, sleeper.z = position.X, position.Z
		return false
	end
	local dx, dz = position.X - sleeper.x, position.Z - sleeper.z
	return dx * dx + dz * dz > WAKE_DISTANCE * WAKE_DISTANCE
end

function BedService.Start(_self)
	InteractService.register("bed", onBed)

	StructureService.onRemoved(function(entry: Entry)
		for player, sleeper in sleepers do
			if sleeper.entry == entry then
				wake(player)
			end
		end
	end)

	local function watch(player: Player)
		player.CharacterRemoving:Connect(function()
			wake(player)
		end)
	end
	Players.PlayerAdded:Connect(watch)
	Players.PlayerRemoving:Connect(function(player)
		wake(player)
	end)
	for _, player in Players:GetPlayers() do
		watch(player)
	end

	task.spawn(function()
		while true do
			task.wait(CHECK_INTERVAL)
			local now = os.clock()
			for player, sleeper in sleepers do
				local ok, wakeUp = pcall(shouldWake, player, sleeper, now)
				if not ok or wakeUp then
					wake(player)
				end
			end
		end
	end)
end

return BedService
