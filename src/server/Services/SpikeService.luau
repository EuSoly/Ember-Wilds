--!strict
-- O dano dos espinhos colocados (G4). Uma varredura só, a SPIKE_CHECK_EVERY
-- (5 Hz), em vez de Touched: para cada jogador vivo, os espinhos das células
-- em volta (StructureService.near); quem encosta (BuildRules.touches com
-- SPIKE_MARGIN) num espinho de quem não é seu aliado toma def.spikeDamage como
-- dano de combate (o capacete protege), causa "death.cause.spike". Cada
-- espinho fere cada vítima no máximo uma vez a cada BuildRules.SPIKE_INTERVAL,
-- por conta própria: entre três espinhos, toma dos três.
--
-- Fica fora do StructureService por causa do ciclo de módulos: o dano passa
-- pelo CharacterService, que pede o DeathService, que pede o StructureService
-- (para sumir com as peças do morto).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildRules = require(ReplicatedStorage.Shared.Build.BuildRules)
local CharacterService = require(script.Parent.CharacterService)
local StructureService = require(script.Parent.StructureService)

local SPIKE_CHECK_EVERY = 0.2 -- segundos (5 Hz)
-- Studs: a raiz do jogador a até isso do quadrado da célula do espinho =
-- encostou. A caixa do modelo do espinho tem ~3,43 de lado; quem encosta de
-- frente fica com o centro a 3,43/2 + 1,5 (raio do corpo) ≈ 3,215 do centro
-- dele, ou seja, ~1,215 fora da célula (meia célula = 2). Margem = raio do
-- corpo 1,5 + 0,3 de folga = 1,8 (com 1, quem encosta de frente nunca era ferido).
local SPIKE_MARGIN = 1.8
local SPIKE_CAUSE = "death.cause.spike"

local SpikeService = {}

-- Espinho → vítima → os.clock() do último dano dele nela.
local lastHit: { [StructureService.Entry]: { [Player]: number } } = {}

local function step()
	local now = os.clock()
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
			if not BuildRules.touches(px, pz, entry.cx, entry.cz, entry.def.size or 1, SPIKE_MARGIN) then
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
