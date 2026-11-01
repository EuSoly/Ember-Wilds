--!strict
-- Modelos provisórios das peças de construção (G4): blocos feitos de peças na
-- cor do tier do item (sem tier = madeira), um formato por tipo (kind) da
-- peça; a fogueira usa o CampfireModel. Quando os modelos do Elizeu chegarem,
-- trocar o visual = mexer só neste arquivo.
-- Pivô no centro do quadrado da peça, no chão (Y = 0). Tudo ancorado e com
-- CanTouch = false (o espinho é conferido por varredura, não por Touched).
-- Sai com o que o tipo oferece: estação (CraftStation + Station) e calor
-- (HeatSource + HeatRadius/BurnRadius). Dono, vida e a tag de construção quem
-- grava é o StructureService. (Só roda no Roblox: cria instâncias.)
local BuildRules = require("../Build/BuildRules")
local CampfireModel = require("./CampfireModel")
local Defs = require("../Defs")
local Palette = require("../Palette")
local StatNames = require("../StatNames")
local Theme = require("../Theme")

type StructureDef = Defs.StructureDef

local StructureModel = {}

-- Transparência das peças da porta aberta (fechada = opaca).
local OPEN_TRANSPARENCY = 0.7
local WALL_HEIGHT = 4
-- Lado do miolo que colide do espinho: menor que a célula para quem encosta
-- nele ficar a menos de 1 stud da borda da célula (a varredura usa margem 1;
-- o corpo tem 3 de largura).
local SPIKE_CORE = 1.6

local function newPart(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Model): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.CanTouch = false
	part.Parent = parent
	return part
end

-- Enfeite: não colide nem entra em raycast.
local function decor(part: Part): Part
	part.CanCollide = false
	part.CanQuery = false
	return part
end

local function darker(color: Color3): Color3
	return color:Lerp(Color3.new(0, 0, 0), 0.35)
end

-- Cada builder monta as peças no modelo (centro do chão na origem) e devolve
-- a peça principal (vira o PrimaryPart).
type Builder = (model: Model, side: number, color: Color3) -> Part

local builders: { [string]: Builder } = {}

builders.wall = function(model, side, color)
	local block =
		newPart("Block", Vector3.new(side, WALL_HEIGHT, side), CFrame.new(0, WALL_HEIGHT / 2, 0), color, model)
	decor(
		newPart(
			"Cap",
			Vector3.new(side + 0.2, 0.3, side + 0.2),
			CFrame.new(0, WALL_HEIGHT - 0.15, 0),
			darker(color),
			model
		)
	)
	return block
end

-- Porta: um bloco do tamanho da parede com uma folha mais escura nas duas
-- faces. Todas as peças colidem (fechada); StructureModel.setOpen solta.
builders.door = function(model, side, color)
	local block =
		newPart("Block", Vector3.new(side, WALL_HEIGHT, side), CFrame.new(0, WALL_HEIGHT / 2, 0), color, model)
	local leaf = Vector3.new(side * 0.5, WALL_HEIGHT * 0.8, 0.2)
	for i, z in { -1, 1 } do
		local panel = newPart("Leaf" .. i, leaf, CFrame.new(0, leaf.Y / 2, z * (side / 2 + 0.1)), darker(color), model)
		panel.CanQuery = false
	end
	return block
end

builders.spike = function(model, _side, color)
	local core = newPart(
		"Core",
		Vector3.new(SPIKE_CORE, SPIKE_CORE, SPIKE_CORE),
		CFrame.new(0, SPIKE_CORE / 2, 0) * CFrame.Angles(0, math.rad(45), 0),
		darker(color),
		model
	)
	-- Pontas saindo do miolo para os lados e para cima (só enfeite).
	for i = 1, 4 do
		local yaw = math.rad(45 + 90 * i)
		local tilt = CFrame.Angles(0, yaw, 0) * CFrame.Angles(math.rad(25), 0, 0)
		local cframe = CFrame.new(0, SPIKE_CORE * 0.6, 0) * tilt * CFrame.new(0, 0, -1.2)
		decor(newPart("Tip" .. i, Vector3.new(0.35, 0.35, 2.4), cframe, color, model))
	end
	decor(newPart("TipTop", Vector3.new(0.35, 1.6, 0.35), CFrame.new(0, SPIKE_CORE + 0.6, 0), color, model))
	return core
end

-- Bancada: tampo em cima de um corpo que colide.
builders.station = function(model, side, color)
	local body = newPart("Body", Vector3.new(side * 0.8, 1.8, side * 0.6), CFrame.new(0, 0.9, 0), darker(color), model)
	body.Material = Enum.Material.WoodPlanks
	local top = decor(newPart("Top", Vector3.new(side * 0.9, 0.4, side * 0.7), CFrame.new(0, 2, 0), color, model))
	top.Material = Enum.Material.WoodPlanks
	return body
end

builders.chest = function(model, side, color)
	local box = newPart("Box", Vector3.new(side * 0.7, 2, side * 0.6), CFrame.new(0, 1, 0), color, model)
	box.Material = Enum.Material.WoodPlanks
	decor(newPart("Lid", Vector3.new(side * 0.74, 0.4, side * 0.64), CFrame.new(0, 2.1, 0), darker(color), model))
	decor(newPart("Lock", Vector3.new(0.5, 0.6, 0.2), CFrame.new(0, 1.6, -side * 0.3 - 0.1), Theme.tier.gold, model))
	return box
end

local function colorOf(itemId: string): Color3
	local item = Defs.Items[itemId]
	local tier = item and item.tier and Defs.Tiers[item.tier]
	if tier then
		return Theme.color(tier.color)
	end
	return Theme.color(Palette.biome.forest[3])
end

-- Fogueira: o modelo da G1 (já sai com calor e estação "fire"); o raio do
-- calor vem dos dados (a fogueira grande esquenta mais longe).
local function buildFire(def: StructureDef): Model
	local model = CampfireModel.build()
	if def.heatRadius then
		model:SetAttribute(StatNames.HeatRadius, def.heatRadius)
	end
	return model
end

function StructureModel.build(itemId: string, def: StructureDef): Model
	local model: Model
	if def.kind == "fire" then
		model = buildFire(def)
	else
		model = Instance.new("Model")
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		local side = (def.size or 1) * BuildRules.CELL
		local main = builders[def.kind](model, side, colorOf(itemId))
		model.PrimaryPart = main
		-- Pivô no chão, no centro (com PrimaryPart, o pivô do modelo é o dela).
		main.PivotOffset = main.CFrame:Inverse()
	end
	model.Name = itemId
	if def.station then
		model:AddTag(StatNames.CraftStationTag)
		model:SetAttribute(StatNames.Station, def.station)
	end
	if def.kind == "door" then
		model:SetAttribute(StatNames.DoorOpen, false)
	end
	return model
end

-- Abre (true) ou fecha a porta: aberta, nenhuma peça colide e todas ficam
-- semitransparentes.
function StructureModel.setOpen(model: Model, open: boolean)
	model:SetAttribute(StatNames.DoorOpen, open)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.CanCollide = not open
			part.Transparency = if open then OPEN_TRANSPARENCY else 0
		end
	end
end

return StructureModel
