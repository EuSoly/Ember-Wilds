--!strict
-- Fantasma e pedra da ressurreição (GhostRules; docs/guia/ressurreicao.md).
-- Quem morre (DeathService.kill pergunta antes a tryGhost) com Coração de Dragão
-- no inventário ou vestindo a Coroa do Anjo, havendo alguma pedra no mundo, vira
-- fantasma: atributo GhostUntil no Player. O fantasma não leva dano nem muda as
-- barras, e não bate, coleta, constrói, come, veste nem crafta (os serviços olham
-- o atributo). Perto de uma pedra, Net.Resurrect volta com a vida e as barras
-- cheias, 1/3 dos pontos e sem os itens da lista. O tempo acabou: morte normal.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Defs = require(ReplicatedStorage.Shared.Defs)
local GhostRules = require(ReplicatedStorage.Shared.Survival.GhostRules)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local InventoryService = require(script.Parent.InventoryService)
local ScoreService = require(script.Parent.ScoreService)
local StructureService = require(script.Parent.StructureService)
local Net = require(script.Parent.Parent.Net)

local STONE_KIND = "resurrection"
local STEP = 0.25

type Ghost = { source: GhostRules.Source, untilAt: number, cause: string }

local GhostService = {}

local ghosts: { [Player]: Ghost } = {}
-- Já passou pelo fantasma nesta morte (o tempo acabou): morre de verdade.
local spent: { [Player]: boolean } = {}
-- Itens segurados e quando (para a coroa: o mais forte dos últimos MEMORY s).
local heldAt: { [Player]: { [string]: number } } = {}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function rootOf(player: Player): BasePart?
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function scoreOf(player: Player): number
	local score = player:GetAttribute(StatNames.Score)
	return if type(score) == "number" and score == score then score else 0
end

function GhostService.isGhost(player: Player): boolean
	return ghosts[player] ~= nil
end

local function hasHeart(player: Player): boolean
	local inv = InventoryService.get(player)
	if inv == nil then
		return false
	end
	for _, slot in inv.slots do
		if slot and slot.id == GhostRules.HEART and slot.count > 0 then
			return true
		end
	end
	return false
end

local function wearsCrown(player: Player): boolean
	local armorId = player:GetAttribute(StatNames.Armor)
	local def = if type(armorId) == "string" then Defs.Items[armorId] else nil
	return def ~= nil and def.armor ~= nil and def.armor.resurrect == true
end

local function recentlyHeld(player: Player): { Defs.ItemDef }
	local out: { Defs.ItemDef } = {}
	local map = heldAt[player]
	if map == nil then
		return out
	end
	local t = now()
	for itemId, at in map do
		local def = Defs.Items[itemId]
		if def and t - at <= GhostRules.MEMORY then
			table.insert(out, def)
		end
	end
	return out
end

-- Chamado pelo DeathService.kill antes de tudo: true = virou fantasma (não morre agora).
function GhostService.tryGhost(player: Player, causeKey: string, killer: Player?): boolean
	if ghosts[player] or spent[player] or rootOf(player) == nil then
		return false
	end
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not GhostRules.canBecomeGhost(causeKey, humanoid ~= nil and humanoid.Health > 0) then
		return false
	end
	if #StructureService.allOfKind(STONE_KIND) == 0 then
		return false
	end
	local found = GhostRules.source(hasHeart(player), wearsCrown(player))
	if found == nil then
		return false
	end
	local source = found
	local seconds = GhostRules.seconds(source, recentlyHeld(player))
	if source == "heart" and not InventoryService.take(player, GhostRules.HEART, 1) then
		return false
	end
	-- Quem matou ganha menos (10%) e não conta abate (Starve).
	if killer and killer ~= player and killer.Parent == Players and killer.Character then
		ScoreService.add(killer, GhostRules.ghostKillBonus(scoreOf(player)))
	end
	local untilAt = now() + seconds
	ghosts[player] = { source = source, untilAt = untilAt, cause = causeKey }
	player:SetAttribute(StatNames.GhostUntil, untilAt)
	player:SetAttribute(StatNames.Health, 1)
	return true
end

local function clear(player: Player)
	ghosts[player] = nil
	player:SetAttribute(StatNames.GhostUntil, nil)
end

-- Distância (studs) do jogador até a borda da pedra mais perto.
local function stoneDistance(position: Vector3): number
	local best = math.huge
	for _, entry in StructureService.allOfKind(STONE_KIND) do
		local d = math.sqrt((entry.x - position.X) ^ 2 + (entry.z - position.Z) ^ 2) - entry.radius
		best = math.min(best, d)
	end
	return best
end

local function onResurrect(player: Player)
	local ghost = ghosts[player]
	local root = rootOf(player)
	if ghost == nil or root == nil then
		return
	end
	if not GhostRules.canRevive(stoneDistance(root.Position), now(), ghost.untilAt) then
		return
	end
	-- Perde os itens da lista (do fim para o começo, sem pular slot).
	local inv = InventoryService.get(player)
	if inv then
		for index = inv.capacity, 1, -1 do
			local slot = inv.slots[index]
			local def = slot and Defs.Items[slot.id]
			if slot and def and GhostRules.loses(ghost.source, def) then
				InventoryService.takeAt(player, index, slot.count)
			end
		end
	end
	player:SetAttribute(StatNames.Score, GhostRules.revivedScore(scoreOf(player)))
	player:SetAttribute(StatNames.Health, StatNames.HealthMax)
	for _, bar in { StatNames.Hunger, StatNames.Cold, StatNames.Thirst, StatNames.Oxygen } do
		player:SetAttribute(bar, StatNames.StatusMax)
	end
	player:SetAttribute(StatNames.Heat, 0)
	clear(player)
end

local function step()
	local t = now()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local equipped = character and character:GetAttribute(StatNames.Equipped)
		if type(equipped) == "string" then
			local map = heldAt[player] or {}
			heldAt[player] = map
			map[equipped] = t
		end
	end
	for player, ghost in ghosts do
		if t >= ghost.untilAt or player.Character == nil then
			clear(player)
			if player.Parent == Players and player.Character then
				-- Require tardio: DeathService pergunta a este serviço (ciclo no topo).
				local DeathService = require(script.Parent.DeathService) :: any
				spent[player] = true
				DeathService.kill(player, ghost.cause, nil)
				spent[player] = nil
			end
		end
	end
end

function GhostService.Start(_self)
	Net.Resurrect.On(onResurrect)
	Players.PlayerRemoving:Connect(function(player)
		ghosts[player] = nil
		spent[player] = nil
		heldAt[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(STEP)
			step()
		end
	end)
end

return GhostService
