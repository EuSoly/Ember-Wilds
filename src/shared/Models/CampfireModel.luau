--!strict
-- Modelo provisório de fogueira (só peças): círculo de pedras, duas toras
-- cruzadas e uma chama laranja com a luz de fogo (FireLight). Sem colisão.
-- Esquenta: sai com a tag HeatSource e o atributo HeatRadius (o
-- SurvivalService sobe o frio de quem está perto). Por enquanto só o comando
-- de dev DevCampfire usa; a fogueira construível chega na fase de construção
-- e só precisa deste mesmo modelo (ou da mesma tag e atributo).
-- Pivô no centro, no chão (Y = 0). (Só roda no Roblox: cria instâncias.)
local FireLight = require("./FireLight")
local Palette = require("../Palette")
local StatNames = require("../StatNames")
local SurvivalConfig = require("../SurvivalConfig")
local Theme = require("../Theme")

local CampfireModel = {}

local RING_RADIUS = 1.6
local STONE_COUNT = 6
local STONE_SIZE = 0.9
local LOG_LENGTH = 2.6
local LOG_THICKNESS = 0.5
local FLAME_SIZE = 1.1

local function newPart(name: string, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end

function CampfireModel.build(): Model
	local model = Instance.new("Model")
	model.Name = "Campfire"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic

	local stoneColor = Theme.color(Palette.tier.stone)
	for i = 1, STONE_COUNT do
		local angle = (i / STONE_COUNT) * 2 * math.pi
		local stone = newPart(
			"Stone",
			Vector3.one * STONE_SIZE,
			CFrame.new(math.cos(angle) * RING_RADIUS, STONE_SIZE * 0.3, math.sin(angle) * RING_RADIUS),
			stoneColor
		)
		stone.Shape = Enum.PartType.Ball
		stone.Parent = model
	end

	-- Toras cruzadas: o cilindro do Roblox tem o eixo em X.
	local logColor = Theme.color(Palette.biome.forest[3])
	for i, yaw in { math.rad(35), math.rad(-35) } do
		local log = newPart(
			"Log" .. i,
			Vector3.new(LOG_LENGTH, LOG_THICKNESS, LOG_THICKNESS),
			CFrame.new(0, LOG_THICKNESS / 2 + (i - 1) * 0.2, 0) * CFrame.Angles(0, yaw, 0),
			logColor
		)
		log.Shape = Enum.PartType.Cylinder
		log.Parent = model
	end

	local flame = newPart(
		"Flame",
		Vector3.one * FLAME_SIZE,
		CFrame.new(0, LOG_THICKNESS + FLAME_SIZE * 0.4, 0),
		Theme.color(Palette.biome.nightFire[4])
	)
	flame.Shape = Enum.PartType.Ball
	flame.Material = Enum.Material.Neon
	flame.Parent = model
	FireLight.attach(flame)

	model.PrimaryPart = flame
	-- Pivô no chão, no centro (com PrimaryPart, o pivô do modelo é o dela).
	flame.PivotOffset = flame.CFrame:Inverse()
	model:AddTag(StatNames.HeatSourceTag)
	model:SetAttribute(StatNames.HeatRadius, SurvivalConfig.CAMPFIRE_RADIUS)
	model:SetAttribute(StatNames.BurnRadius, SurvivalConfig.BURN_RADIUS)
	return model
end

return CampfireModel
