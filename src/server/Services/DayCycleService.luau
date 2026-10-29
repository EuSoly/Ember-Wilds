--!strict
-- Marca o início do ciclo de dia e noite. Servidor e clientes calculam a hora
-- com DayCycle.at(GetServerTimeNow() - CycleStart): nada precisa ser enviado
-- a cada segundo. A iluminação da noite entra na Fase 6.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local StatNames = require(ReplicatedStorage.Shared.StatNames)

local DayCycleService = {}

function DayCycleService.Init(_self)
	Workspace:SetAttribute(StatNames.CycleStart, Workspace:GetServerTimeNow())
end

return DayCycleService
