--!strict
-- Bots que parecem jogadores (spec docs/superpowers/specs/2026-11-20-bots-design.md,
-- guia docs/guia/bots.md). Até BotRules.MAX_BOTS por servidor, quantos faltam
-- para BotRules.TARGET_TOTAL com os jogadores (11 jogadores = 9 bots...).
-- - População: a cada POPULATION_EVERY, no máximo 1 entra ou sai. Sai o bot
--   mais longe de todos os jogadores, e só se nenhum jogador está a menos de
--   HIDE_DISTANCE dele (ninguém o vê sumir). Bot morto deixa a vaga esfriando
--   RESPAWN_DELAY s antes de outro nascer.
-- - Passo: andar/golpear a cada MOVE_TICK (raízes movidas de uma vez, como os
--   mobs), barras a cada SurvivalConfig.TICK, cérebro a cada THINK_EVERY (ou
--   FAR_THINK_EVERY sem jogador a FAR_RADIUS).
-- - Dano: CharacterService.onNonPlayerHurt → Actor.hurt.
-- Studio (barra de comandos do servidor):
-- - ServerStorage.DevBots:Invoke(n): força n bots (nil = volta ao automático);
-- - ServerStorage.DevBotInfo:Invoke(): nome, objetivo, vida, fome, frio, pontos;
-- - ServerStorage.DevKillBot:Invoke(nome?): mata um bot (o primeiro, sem nome);
-- - ServerStorage.DevBotCost:Invoke(segundos) -> ms médios por quadro gastos
--   pelos bots no servidor (também aparece como "BotService" no MicroProfiler).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage.Shared
local BotNames = require(Shared.Bots.BotNames)
local BotRules = require(Shared.Bots.BotRules)
local StatNames = require(Shared.StatNames)
local SurvivalConfig = require(Shared.SurvivalConfig)
local CharacterService = require(script.Parent.CharacterService)
local SpawnService = require(script.Parent.SpawnService)
local SurvivalService = require(script.Parent.SurvivalService)
local Actor = require(script.Actor)

local MOVE_TICK = 0.1
local THINK_EVERY = 0.5
local FAR_THINK_EVERY = 2
local FAR_RADIUS = 150
local HIDE_DISTANCE = 120
local RESPAWN_DELAY = 20

local BotService = {}

local bots: { Actor.Bot } = {}
local byModel: { [Model]: Actor.Bot } = {}
local cooling: { number } = {} -- os.clock() em que cada vaga de bot morto libera
local taken: { [string]: boolean } = {} -- nomes em uso
local nextId = 0
local forced: number? = nil -- DevBots
local rng = Random.new()

local function nextNumber(): number
	return rng:NextNumber()
end

local function nearestPlayerDistance(x: number, z: number): number
	local best = math.huge
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local dx, dz = root.Position.X - x, root.Position.Z - z
			best = math.min(best, math.sqrt(dx * dx + dz * dz))
		end
	end
	return best
end

local function spawnBot()
	nextId += 1
	local name = BotNames.pick(nextNumber, taken)
	taken[name] = true
	local spot = SpawnService.forestSpot(nil)
	local bot = Actor.new(-nextId, name, spot.X, spot.Z, Random.new(rng:NextInteger(1, 2 ^ 30)))
	table.insert(bots, bot)
	byModel[bot.model] = bot
end

local function forget(bot: Actor.Bot)
	local index = table.find(bots, bot)
	if index then
		table.remove(bots, index)
	end
	byModel[bot.model] = nil
	taken[bot.name] = nil
end

-- Tira um bot: o mais longe de todos os jogadores, se ninguém o vê.
local function removeOne(): boolean
	-- Vaga esfriando sai primeiro (não há corpo para sumir).
	if #cooling > 0 then
		table.remove(cooling, 1)
		return true
	end
	local farthest, farDistance = nil, -1
	for _, bot in bots do
		local d = nearestPlayerDistance(bot.x, bot.z)
		if d > farDistance then
			farthest, farDistance = bot, d
		end
	end
	if farthest == nil or farDistance < HIDE_DISTANCE then
		return false
	end
	forget(farthest)
	Actor.remove(farthest)
	return true
end

local function population()
	local clock = os.clock()
	-- Vagas que já esfriaram viram bot de novo pela conta normal.
	local kept: { number } = {}
	for _, untilAt in cooling do
		if untilAt > clock then
			table.insert(kept, untilAt)
		end
	end
	cooling = kept
	local players = #Players:GetPlayers()
	if players == 0 and forced == nil then
		return
	end
	local target = forced or BotRules.target(players, Players.MaxPlayers)
	local change = BotRules.populationStep(#bots + #cooling, target)
	if change > 0 then
		spawnBot()
	elseif change < 0 then
		removeOne()
	end
end

-- Bot morto: sai da lista e a vaga esfria.
local function sweepDead()
	for i = #bots, 1, -1 do
		local bot = bots[i]
		if bot.dead then
			forget(bot)
			table.insert(cooling, os.clock() + RESPAWN_DELAY)
		end
	end
end

local moveAcc, survivalAcc, populationAcc = 0, 0, 0
local costSeconds, costFrames = 0, 0 -- DevBotCost

local function step(dt: number)
	moveAcc += dt
	survivalAcc += dt
	populationAcc += dt
	if populationAcc >= BotRules.POPULATION_EVERY then
		populationAcc = 0
		population()
	end
	if #bots == 0 then
		return
	end
	if survivalAcc >= SurvivalConfig.TICK then
		local night = SurvivalService.isNight()
		for _, bot in bots do
			Actor.survive(bot, survivalAcc, night)
		end
		survivalAcc = 0
	end
	if moveAcc < MOVE_TICK then
		return
	end
	local elapsed = moveAcc
	moveAcc = 0
	local clock = os.clock()
	local now = Workspace:GetServerTimeNow()
	local parts: { BasePart } = {}
	local frames: { CFrame } = {}
	for _, bot in bots do
		if bot.dead then
			continue
		end
		if clock >= bot.nextThink then
			local far = nearestPlayerDistance(bot.x, bot.z) > FAR_RADIUS
			bot.nextThink = clock + (if far then FAR_THINK_EVERY else THINK_EVERY)
			Actor.think(bot, now)
		end
		local frame = Actor.step(bot, elapsed)
		if not bot.dead then
			table.insert(parts, bot.root)
			table.insert(frames, frame)
		end
	end
	if #parts > 0 then
		Workspace:BulkMoveTo(parts, frames, Enum.BulkMoveMode.FireCFrameChanged)
	end
	sweepDead()
end

local function heartbeat(dt: number)
	debug.profilebegin("BotService")
	local started = os.clock()
	step(dt)
	costSeconds += os.clock() - started
	costFrames += 1
	debug.profileend()
end

local function setupDev()
	if not RunService:IsStudio() then
		return
	end
	local function command(name: string, handler: (...any) -> ...any)
		local existing = ServerStorage:FindFirstChild(name)
		if existing then
			existing:Destroy()
		end
		local fn = Instance.new("BindableFunction")
		fn.Name = name
		fn.OnInvoke = handler
		fn.Parent = ServerStorage
	end
	command("DevBots", function(count: number?): number
		forced = if type(count) == "number" then math.clamp(math.floor(count), 0, 40) else nil
		-- Ajusta já, sem esperar as rodadas (o Studio quer ver na hora).
		local target = forced or BotRules.target(#Players:GetPlayers(), Players.MaxPlayers)
		while #bots < target do
			spawnBot()
		end
		while #bots > target do
			local bot = bots[#bots]
			forget(bot)
			Actor.remove(bot)
		end
		cooling = {}
		return #bots
	end)
	command("DevBotInfo", function(): { string }
		local lines = {}
		for _, bot in bots do
			local target = bot.target
			local inv = {}
			for id, count in Actor.counts(bot) do
				table.insert(inv, `{id}={count}`)
			end
			local resource = target and target.resource
			local where = if resource then `[{resource.gather.item} restam {resource.amount}] ` else ""
			where ..= `inv: {table.concat(inv, ",")} | `
			where ..= if target
				then string.format(
					"%s a %.1f (para em %.1f), sem progresso %.0f s",
					target.kind,
					math.sqrt((target.x - bot.x) ^ 2 + (target.z - bot.z) ^ 2),
					target.stop,
					os.clock() - bot.progressAt
				)
				else "sem alvo"
			table.insert(
				lines,
				string.format(
					"%s | %s | vida %d fome %d frio %d | pontos %d | %s | (%.0f, %.0f) %s",
					bot.name,
					bot.goal,
					bot.bars.health,
					bot.bars.hunger,
					bot.bars.cold,
					bot.score,
					tostring(bot.model:GetAttribute(StatNames.Equipped)),
					bot.x,
					bot.z,
					where
				)
			)
		end
		return lines
	end)
	command("DevBotCost", function(seconds: number?): number
		costSeconds, costFrames = 0, 0
		task.wait(seconds or 10)
		return if costFrames > 0 then costSeconds / costFrames * 1000 else 0
	end)
	command("DevKillBot", function(name: string?): boolean
		for _, bot in bots do
			if name == nil or bot.name == name then
				CharacterService.hurt(bot.model, 10000, "death.cause.player", "survival")
				return true
			end
		end
		return false
	end)
end

function BotService.Start(_self)
	CharacterService.onNonPlayerHurt(function(character, amount, _causeKey, kind, attacker)
		local bot = byModel[character]
		if bot then
			Actor.hurt(bot, amount, kind, attacker)
		end
	end)
	setupDev()
	RunService.Heartbeat:Connect(heartbeat)
end

return BotService
