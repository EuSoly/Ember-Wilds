--!strict
-- O dano dos espinhos colocados (G4). Uma varredura só, a SPIKE_CHECK_EVERY
-- (5 Hz), em vez de Touched: para cada jogador vivo, os espinhos por perto
-- (StructureService.near); quem encosta (BuildRules.touchesCircle no círculo
-- da peça, com SPIKE_MARGIN) num espinho de quem não é seu aliado toma
-- def.spikeDamage como dano de combate (o capacete protege), causa "death.cause.spike". Cada
-- espinho fere cada vítima no máximo uma vez a cada BuildRules.SPIKE_INTERVAL,
-- por conta própria: entre três espinhos, toma dos três.
-- Mobs vivos no chão (MobService) também levam o espinho (corpo = mob.radius),
-- no mesmo intervalo por par espinho/mob, sem pontos (MobService.damage, sem autor).
--
-- Fica fora do StructureService por causa do ciclo de módulos: o dano passa
-- pelo CharacterService, que pede o DeathService, que pede o StructureService
-- (para sumir com as peças do morto).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildRules = require(ReplicatedStorage.Shared.Build.BuildRules)
local CharacterService = require(script.Parent.CharacterService)
local MobService = require(script.Parent.MobService)
local StructureService = require(script.Parent.StructureService)

local SPIKE_CHECK_EVERY = 0.2 -- segundos (5 Hz)
-- Studs: a raiz do jogador a até isso da borda do círculo do espinho (raio
-- BuildRules.radiusOf, 2 no padrão) = encostou. O corpo encosta no círculo
-- quando a distância dos centros chega a raio + BuildRules.PLAYER_RADIUS
-- (2 + 1,5 = 3,5); mais 0,3 de folga para quem encosta de frente (a raiz
-- oscila e a varredura é a 5 Hz) = 1,8, ou seja, fere a até 3,8 do centro.
-- (As pontas do modelo vão a ~1,7 do centro: o círculo cobre o espinho todo.)
local SPIKE_MARGIN = BuildRules.PLAYER_RADIUS + 0.3
local SPIKE_CAUSE = "death.cause.spike"

local SpikeService = {}

-- Espinho → vítima → os.clock() do último dano dele nela.
local lastHit: { [StructureService.Entry]: { [Player]: number } } = {}

-- Mob → espinho → os.clock() do último dano dele no mob.
local mobLastHit: { [MobService.Mob]: { [StructureService.Entry]: number } } = {}

local function stepMobs(now: number)
	-- Morto ou sumido: solta o mob da tabela (trim do MobService não avisa).
	for mob in mobLastHit do
		if mob.dead then
			mobLastHit[mob] = nil
		end
	end
	for _, mob in MobService.list() do
		if mob.flying or mob.dead then
			continue
		end
		for _, entry in StructureService.near(mob.x, mob.z, mob.radius) do
			local damage = entry.def.spikeDamage
			if entry.def.kind ~= "spike" or damage == nil then
				continue
			end
			if not BuildRules.touchesCircle(mob.x, mob.z, entry.x, entry.z, entry.radius, mob.radius) then
				continue
			end
			local hits = mobLastHit[mob]
			if hits == nil then
				hits = {}
				mobLastHit[mob] = hits
			end
			local last = hits[entry]
			if last and now - last < BuildRules.SPIKE_INTERVAL then
				continue
			end
			hits[entry] = now
			MobService.damage(mob, damage, nil)
			if mob.dead then
				mobLastHit[mob] = nil
				break
			end
		end
	end
end

local function step()
	local now = os.clock()
	stepMobs(now)
	for _, victim in Players:GetPlayers() do
		local character = victim.Character
		if character == nil or character:FindFirstChildOfClass("Humanoid") == nil then
			continue
		end
		local root = character:FindFirstChild("HumanoidRootPart")
		if root == nil or not root:IsA("BasePart") then
			continue
		end
		local px, pz = root.Position.X, root.Position.Z
		for _, entry in StructureService.near(px, pz, SPIKE_MARGIN) do
			local damage = entry.def.spikeDamage
			if entry.def.kind ~= "spike" or damage == nil then
				continue
			end
			if BuildRules.areAllies(entry.owner.UserId, victim.UserId) then
				continue
			end
			if not BuildRules.touchesCircle(px, pz, entry.x, entry.z, entry.radius, SPIKE_MARGIN) then
				continue
			end
			local hits = lastHit[entry]
			if hits == nil then
				hits = {}
				lastHit[entry] = hits
			end
			local last = hits[victim]
			if last and now - last < BuildRules.SPIKE_INTERVAL then
				continue
			end
			hits[victim] = now
			CharacterService.hurt(character, damage, SPIKE_CAUSE, "combat")
			-- Morreu: o personagem já foi removido, os outros espinhos param aqui.
			if victim.Character ~= character then
				break
			end
		end
	end
end

function SpikeService.Start(_self)
	StructureService.onRemoved(function(entry)
		lastHit[entry] = nil
		for _, hits in mobLastHit do
			hits[entry] = nil
		end
	end)
	MobService.onDeath(function(mob)
		mobLastHit[mob] = nil
	end)
	Players.PlayerRemoving:Connect(function(player)
		for _, hits in lastHit do
			hits[player] = nil
		end
	end)
	task.spawn(function()
		while true do
			task.wait(SPIKE_CHECK_EVERY)
			local ok, err = pcall(step :: any)
			if not ok then
				warn(`[SpikeService] {err}`)
			end
		end
	end)
end

return SpikeService
