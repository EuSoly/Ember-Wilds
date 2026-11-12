--!strict
-- SÓ PARA DESENVOLVIMENTO (roda apenas no Studio). Barra de comandos do Studio,
-- lado SERVIDOR (p = game.Players:GetPlayers()[1]):
-- - ServerStorage.DevMissions:Invoke(p, "complete", 2, "daily_wood") -> boolean:
--   põe a missão no alvo (1 = Partida, 2 = diária, 3 = semanal; o id tem de
--   estar no sorteio ou ser uma chrono quest ativa).
-- - ServerStorage.DevMissions:Invoke(p, "nextDay") / "nextWeek": vira o dia ou a
--   semana deste jogador (sorteio novo, como na meia-noite).
-- - ServerStorage.DevMissions:Invoke(p, "reset"): zera as missões do perfil.
-- - ServerStorage.DevMissions:Invoke(p, "dump") -> string: as missões salvas e o
--   estado das chrono quests, em JSON.
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local MissionService = require(script.Parent.MissionService)

local DevMissionService = {}

function DevMissionService.Start(_self)
	if not RunService:IsStudio() then
		return
	end
	local command = Instance.new("BindableFunction")
	command.Name = "DevMissions"
	command.OnInvoke = function(player: Player, action: string, kind: number?, id: string?): any
		if action == "complete" and type(kind) == "number" and type(id) == "string" then
			return MissionService.devComplete(player, kind, id)
		elseif action == "nextDay" then
			MissionService.devAdvance(player, "daily")
			return true
		elseif action == "nextWeek" then
			MissionService.devAdvance(player, "weekly")
			return true
		elseif action == "reset" then
			MissionService.devReset(player)
			return true
		elseif action == "dump" then
			return HttpService:JSONEncode(MissionService.devDump(player))
		end
		return `ação desconhecida: {action}`
	end
	command.Parent = ServerStorage
end

return DevMissionService
