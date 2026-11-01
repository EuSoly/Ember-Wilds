--!strict
-- O golpe de coleta (G2). Quem segura o botão de usar (atributo Using), está
-- vivo e não tem comida na mão (comida o FoodService come) bate no recurso à
-- frente, no máximo um golpe a cada GatherRules.HIT_INTERVAL (o primeiro sai
-- na hora do aperto, se o último foi há mais que isso).
-- O golpe: acha o alvo (ResourceService + GatherRules.pickTarget), confere a
-- ferramenta e a reserva, dá o que couber no inventário, desconta da reserva
-- só o que entrou, soma pontos (ScoreService) e a estatística, e avisa os
-- jogadores perto para mostrarem o tranco/lasquinhas/som (Net.ResourceHit).
-- Avisos (picareta que falta, recurso vazio, inventário cheio) vão só para
-- quem bateu, no máximo um da mesma chave a cada NOTICE_EVERY.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require(ReplicatedStorage.Shared.Defs)
local GatherRules = require(ReplicatedStorage.Shared.Gather.GatherRules)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local CraftService = require(script.Parent.CraftService)
local InventoryService = require(script.Parent.InventoryService)
local ResourceService = require(script.Parent.ResourceService)
local ScoreService = require(script.Parent.ScoreService)
local StatsService = require(script.Parent.StatsService)
local Net = require(script.Parent.Parent.Net)

local CHECK_EVERY = 0.05 -- segundos entre conferências de quem está batendo
local NOTICE_EVERY = 2 -- segundos mínimos entre avisos iguais
local FX_RANGE = 100 -- studs: quem está a até isso do golpe vê o efeito
-- Folga da busca na grade: maior raio de colisão de um recurso (com variação).
local SEARCH_MARGIN = 5

local GatherService = {}

local nextHit: { [Player]: number } = {}
local lastNotice: { [Player]: { [string]: number } } = {}

local function notify(player: Player, key: string, itemId: string?)
	local now = os.clock()
	local sent = lastNotice[player]
	if sent == nil then
		sent = {}
		lastNotice[player] = sent
	end
	if sent[key] and now - sent[key] < NOTICE_EVERY then
		return
	end
	sent[key] = now
	Net.GatherNotice.Fire(player, { Key = key, ItemId = itemId })
end

local function sendFx(entry: ResourceService.Entry, hitX: number, hitZ: number, dirX: number, dirZ: number)
	local listeners = {}
	for _, other in Players:GetPlayers() do
		local character = other.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			local dx, dz = root.Position.X - hitX, root.Position.Z - hitZ
			if dx * dx + dz * dz <= FX_RANGE * FX_RANGE then
				table.insert(listeners, other)
			end
		end
	end
	if #listeners > 0 then
		Net.ResourceHit.FireList(listeners, {
			Resource = entry.model,
			X = hitX,
			Z = hitZ,
			DirX = dirX,
			DirZ = dirZ,
			Material = entry.gather.material,
		})
	end
end

local function hit(player: Player, character: Model, root: BasePart)
	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-3 then
		return
	end
	local dir = flat.Unit
	local px = root.Position.X + dir.X * GatherRules.HIT_REACH
	local pz = root.Position.Z + dir.Z * GatherRules.HIT_REACH
	local candidates = ResourceService.near(px, pz, GatherRules.HIT_RADIUS + SEARCH_MARGIN)
	local entry = GatherRules.pickTarget(candidates, px, pz, GatherRules.HIT_RADIUS)
	if entry == nil then
		return
	end

	-- Ponto do golpe na borda do recurso, do lado de quem bateu (lasquinhas).
	local toPlayer = Vector3.new(root.Position.X - entry.x, 0, root.Position.Z - entry.z)
	local side = if toPlayer.Magnitude > 1e-3 then toPlayer.Unit else -dir
	sendFx(entry, entry.x + side.X * entry.radius, entry.z + side.Z * entry.radius, dir.X, dir.Z)

	local gather = entry.gather
	local equipped = character:GetAttribute(StatNames.Equipped)
	local tool = if type(equipped) == "string" then Defs.Items[equipped] else nil
	local yield = GatherRules.yield(tool, gather)
	if yield == nil then
		notify(player, "gather.needTool", GatherRules.requiredPickaxe(Defs.Items, gather.hardness or 0))
		return
	end
	if entry.amount <= 0 then
		notify(player, "gather.empty")
		return
	end
	local wanted = math.min(yield, entry.amount)
	local given = wanted - InventoryService.give(player, gather.item, wanted)
	if given <= 0 then
		notify(player, "gather.full")
		return
	end
	ResourceService.take(entry, given)
	ScoreService.add(player, given * gather.points)
	StatsService.add(player, "resources_gathered", given, gather.item)
end

local function step()
	local now = os.clock()
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character == nil or character:GetAttribute(StatNames.Using) ~= true then
			continue
		end
		if CraftService.isCrafting(player) then
			continue
		end
		if (nextHit[player] or 0) > now then
			continue
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if character:FindFirstChildOfClass("Humanoid") == nil or root == nil or not root:IsA("BasePart") then
			continue
		end
		-- Comida na mão: o botão de usar come (FoodService), não coleta.
		local equipped = character:GetAttribute(StatNames.Equipped)
		local def = if type(equipped) == "string" then Defs.Items[equipped] else nil
		if def and def.food then
			continue
		end
		if def and (def.category == "armor" or def.category == "bag") then
			continue
		end
		nextHit[player] = GatherRules.nextHit(nextHit[player], now)
		local ok, err = pcall(hit :: any, player, character, root)
		if not ok then
			warn(`[GatherService] {player.Name}: {err}`)
		end
	end
end

function GatherService.Start(_self)
	Players.PlayerRemoving:Connect(function(player)
		nextHit[player] = nil
		lastNotice[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			step()
		end
	end)
end

return GatherService
