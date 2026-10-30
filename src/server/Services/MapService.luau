--!strict
-- Lê o mapa desenhado no Studio (Workspace.Map), espalha os recursos e monta
-- os modelos. Pastas combinadas (ver docs/guia/mapa.md):
-- - Map/Water e Map/NoSpawn: onde não nasce recurso (a água também deixa lento);
-- - Map/Zones: peças invisíveis com o atributo ZoneType (Defs/ResourceZones);
-- - Map/Resources: marcadores com o atributo ResourceId (e Variant opcional):
--   viram o modelo padrão do recurso, na posição e rotação do marcador.
-- O espalhamento é determinístico (WorldConfig.SEED): o mapa sai igual em
-- toda partida. Peça com forma ou atributo errado gera aviso e é ignorada.
-- Sem Workspace.Map, não há recursos (o WorldService cria o chão de teste).
-- Em qualquer caso, garante um SpawnLocation no WorldConfig.SPAWN.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local WorldConfig = require(ReplicatedStorage.Shared.WorldConfig)
local MapShapes = require(ReplicatedStorage.Shared.World.MapShapes)
local Scatter = require(ReplicatedStorage.Shared.World.Scatter)
local Shapes = require(ReplicatedStorage.Shared.World.Shapes)
local ResourceModels = require(ReplicatedStorage.Shared.Models.ResourceModels)
local ResourceService = require(script.Parent.ResourceService)

local MAP_NAME = "Map"
local RESOURCES_FOLDER = "Resources"
local SPAWN_NAME = "Spawn"
local VARIANT_ATTRIBUTE = "Variant"

local MapService = {}

local hasMap = false

-- Peça puramente de marcação (zona, caminho, marcador de recurso): some no jogo.
local function hideMarker(part: BasePart)
	part.Transparency = 1
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
end

-- Lê as formas de todas as peças de uma pasta do mapa. `onShape` recebe cada
-- peça aceita; as outras geram aviso com o caminho da peça.
local function readShapes(folder: Instance?, onShape: (BasePart, Shapes.Shape) -> ())
	if folder == nil then
		return
	end
	for _, descendant in folder:GetDescendants() do
		if descendant:IsA("BasePart") then
			local shape, reason = MapShapes.fromPart(descendant)
			if shape then
				onShape(descendant, shape)
			else
				warn(`[MapService] {descendant:GetFullName()} ignorada: {reason}`)
			end
		end
	end
end

local function readZones(folder: Instance?): { Scatter.Zone }
	local zones: { Scatter.Zone } = {}
	readShapes(folder, function(part, shape)
		hideMarker(part)
		local zoneType = part:GetAttribute(StatNames.ZoneType)
		local def = if type(zoneType) == "string" then Defs.ResourceZones[zoneType] else nil
		if def == nil then
			warn(`[MapService] {part:GetFullName()}: ZoneType "{zoneType}" não existe em Defs/ResourceZones`)
			return
		end
		table.insert(zones, { shape = shape, densities = def.densities })
	end)
	return zones
end

-- Esconde todas as peças de um marcador (pode ser uma peça ou um modelo).
local function hideAll(marker: Instance)
	if marker:IsA("BasePart") then
		hideMarker(marker)
	end
	for _, descendant in marker:GetDescendants() do
		if descendant:IsA("BasePart") then
			hideMarker(descendant)
		end
	end
end

-- Recursos colocados à mão: o primeiro objeto de cada ramo com ResourceId vira
-- um recurso fixo (os de dentro dele não contam de novo).
local function readFixed(folder: Instance?): { Scatter.Placement }
	local fixed: { Scatter.Placement } = {}
	if folder == nil then
		return fixed
	end
	local function visit(instance: Instance)
		local resourceId = instance:GetAttribute(StatNames.ResourceId)
		if resourceId == nil then
			for _, child in instance:GetChildren() do
				visit(child)
			end
			return
		end
		hideAll(instance)
		if type(resourceId) ~= "string" or Defs.Resources[resourceId] == nil then
			warn(`[MapService] {instance:GetFullName()}: ResourceId "{resourceId}" não existe em Defs/Resources`)
			return
		end
		local cframe: CFrame
		if instance:IsA("Model") then
			cframe = instance:GetPivot()
		elseif instance:IsA("BasePart") then
			cframe = instance.CFrame
		else
			warn(`[MapService] {instance:GetFullName()}: ResourceId só vale em Part ou Model`)
			return
		end
		local variant = instance:GetAttribute(VARIANT_ATTRIBUTE)
		table.insert(fixed, {
			resourceId = resourceId,
			x = cframe.Position.X,
			z = cframe.Position.Z,
			variant = if type(variant) == "number" then variant else 1,
			yaw = MapShapes.yawOf(cframe),
		})
	end
	for _, child in folder:GetChildren() do
		visit(child)
	end
	return fixed
end

-- Monta os modelos em Workspace.Resources. Devolve quantos montou.
local function buildResources(placements: { Scatter.Placement }, folder: Folder): number
	local built = 0
	for _, placement in placements do
		local def = Defs.Resources[placement.resourceId]
		local jitter = if def and def.sizeJitter then def.sizeJitter else 0
		local scale = Scatter.sizeFactor(placement.x, placement.z, jitter)
		local model = ResourceModels.build(placement.resourceId, placement.variant, scale)
		if model then
			model:PivotTo(CFrame.new(placement.x, 0, placement.z) * CFrame.Angles(0, placement.yaw, 0))
			model.Parent = folder
			if def then
				-- Reserva e alvo do golpe de coleta.
				ResourceService.register(model, def, placement.x, placement.z, scale)
			end
			built += 1
		end
	end
	return built
end

-- Um SpawnLocation no centro da floresta, a menos que o mapa já tenha o seu.
local function ensureSpawn()
	-- Qualquer SpawnLocation no Workspace conta (ex. um que veio do template do place).
	if Workspace:FindFirstChildWhichIsA("SpawnLocation", true) then
		return
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Name = SPAWN_NAME
	spawn.Anchored = true
	spawn.Neutral = true
	spawn.Size = Vector3.new(6, 1, 6)
	spawn.Position = Vector3.new(WorldConfig.SPAWN.x, 0.5, WorldConfig.SPAWN.z)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.CanQuery = false
	spawn.CanTouch = false
	spawn.Duration = 0 -- sem campo de força
	spawn.Parent = Workspace
end

-- true se o place tem um mapa desenhado (Workspace.Map).
function MapService.hasMap(): boolean
	return hasMap
end

function MapService.Init(_self)
	local map = Workspace:FindFirstChild(MAP_NAME)
	hasMap = map ~= nil
	ensureSpawn()
	if map == nil then
		return
	end

	local started = os.clock()

	-- Água e caminhos: o espalhador não põe recurso neles.
	local blockers: { Shapes.Shape } = {}
	readShapes(map:FindFirstChild("Water"), function(part, shape)
		-- Dá para atravessar a água andando (a lentidão vem do WaterSim).
		part.CanCollide = false
		-- Opaca: água transparente é desenhada por cima das etiquetas (nome do
		-- jogador, bolha de ar) e as deixa apagadas (visto no Studio em 29/10).
		part.Transparency = 0
		table.insert(blockers, shape)
	end)
	readShapes(map:FindFirstChild("NoSpawn"), function(part, shape)
		hideMarker(part)
		table.insert(blockers, shape)
	end)

	local zones = readZones(map:FindFirstChild("Zones"))
	local fixed = readFixed(map:FindFirstChild("Resources"))
	local generated = Scatter.generate({
		zones = zones,
		blockers = blockers,
		fixed = fixed,
		resources = Defs.Resources,
		seed = WorldConfig.SEED,
		minPassage = WorldConfig.MIN_PASSAGE,
	})

	local folder = Instance.new("Folder")
	folder.Name = RESOURCES_FOLDER
	folder.Parent = Workspace
	local built = buildResources(fixed, folder) + buildResources(generated, folder)

	if RunService:IsStudio() then
		local ms = math.floor((os.clock() - started) * 1000)
		print(`[MapService] {built} recursos ({#fixed} à mão + {#generated} espalhados) em {ms} ms`)
	end
end

return MapService
