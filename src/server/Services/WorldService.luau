--!strict
-- Chão de teste: só existe quando o place NÃO tem um mapa desenhado
-- (Workspace.Map, ver MapService e docs/guia/mapa.md). Fica centrado no
-- WorldConfig.SPAWN, onde o boneco nasce. O SpawnLocation é do MapService.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Palette = require(ReplicatedStorage.Shared.Palette)
local Theme = require(ReplicatedStorage.Shared.Theme)
local WorldConfig = require(ReplicatedStorage.Shared.WorldConfig)

local GROUND_SIZE = Vector3.new(WorldConfig.size, 2, WorldConfig.size)

local WorldService = {}

function WorldService.Init(_self)
	if Workspace:FindFirstChild("Map") then
		return
	end

	local world = Instance.new("Folder")
	world.Name = "World"

	-- Topo do chão em Y = 0, para facilitar as contas de posição dos outros sistemas.
	local ground = Instance.new("Part")
	ground.Name = "TestGround"
	ground.Anchored = true
	ground.Size = GROUND_SIZE
	ground.Position = Vector3.new(WorldConfig.SPAWN.x, -GROUND_SIZE.Y / 2, WorldConfig.SPAWN.z)
	ground.Color = Theme.color(Palette.biome.forest[1])
	ground.Material = Enum.Material.SmoothPlastic
	ground.TopSurface = Enum.SurfaceType.Smooth
	ground.CastShadow = false -- uma placa enorme fazendo sombra em si mesma pisca
	ground.Parent = world

	world.Parent = Workspace
end

return WorldService
