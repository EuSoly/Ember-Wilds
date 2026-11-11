--!strict
-- Máquina de esmeralda (EmeraldRules; docs/guia/construcao.md): a cada segundo
-- dá ao dono vivo os pontos da máquina (750 por minuto, como pontos da vida).
-- Destruída por outra pessoa, o dono morre; quebrada pelo dono (ou aliado) ou
-- removida com vida (o dono morreu ou saiu), não. Uma por jogador: maxPerPlayer.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BuildRules = require(ReplicatedStorage.Shared.Build.BuildRules)
local EmeraldRules = require(ReplicatedStorage.Shared.Build.EmeraldRules)
local GhostRules = require(ReplicatedStorage.Shared.Survival.GhostRules)
local DeathService = require(script.Parent.DeathService)
local ScoreService = require(script.Parent.ScoreService)
local StructureService = require(script.Parent.StructureService)

local KIND = "emerald_machine"
local STEP = 1 -- segundos
local CAUSE = "death.cause.emerald"

local EmeraldService = {}

-- Fração de ponto que ficou para o próximo passo, por dono.
local carry: { [Player]: number } = {}

local function alive(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

local function step()
	for _, entry in StructureService.allOfKind(KIND) do
		local owner = entry.owner
		-- Fantasma não ganha pontos da máquina (escolha nossa; a spec não fala).
		if
			owner.Parent == Players
			and alive(owner)
			and not GhostRules.isGhostPlayer(owner, Workspace:GetServerTimeNow())
		then
			local whole, rest = EmeraldRules.split((carry[owner] or 0) + EmeraldRules.pointsFor(STEP))
			carry[owner] = rest
			if whole > 0 then
				ScoreService.add(owner, whole)
			end
		end
	end
end

function EmeraldService.Start(_self)
	StructureService.onRemoved(function(entry)
		if entry.def.kind ~= KIND then
			return
		end
		local owner = entry.owner
		carry[owner] = nil
		local hitter = entry.lastHitBy
		local byAlly = hitter ~= nil and BuildRules.areAllies(hitter.UserId, owner.UserId)
		if EmeraldRules.killsOwner(entry.health, byAlly) and owner.Parent == Players and alive(owner) then
			DeathService.kill(owner, CAUSE)
		end
	end)
	Players.PlayerRemoving:Connect(function(player)
		carry[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(STEP)
			step()
		end
	end)
end

return EmeraldService
