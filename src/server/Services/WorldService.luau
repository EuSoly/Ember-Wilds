--!strict
-- Monta o mundo. Por enquanto só um chão de teste com o verde da floresta e um
-- ponto de spawn; o gerador do mapa de verdade entra na Fase 6.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Palette = require(ReplicatedStorage.Shared.Palette)
local Theme = require(ReplicatedStorage.Shared.Theme)

local GROUND_SIZE = Vector3.new(256, 2, 256)

local WorldService = {}

function WorldService.Init(_self)
	local world = Instance.new("Folder")
	world.Name = "World"

	-- Topo do chão em Y = 0, para facilitar as contas de posição dos outros sistemas.
	local ground = Instance.new("Part")
	ground.Name = "TestGround"
	ground.Anchored = true
	ground.Size = GROUND_SIZE
	ground.Position = Vector3.new(0, -GROUND_SIZE.Y / 2, 0)
	ground.Color = Theme.color(Palette.biome.forest[1])
	ground.Material = Enum.Material.SmoothPlastic
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.Parent = world

	-- Spawn invisível: o jogador nasce no centro e cai no chão.
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = "Spawn"
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(0, 0.5, 0)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.Duration = 0 -- sem campo de força
	spawn.Parent = world

	world.Parent = Workspace
end

return WorldService
