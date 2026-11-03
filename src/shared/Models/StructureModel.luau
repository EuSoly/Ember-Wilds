--!strict
-- Modelos das peças de construção. O colisor é o de sempre (G4): blocos feitos
-- de peças na cor do tier do item (sem tier = madeira), um formato por tipo
-- (kind) da peça; a fogueira usa o CampfireModel. Se existir o modelo do
-- Elizeu (G8, ReplicatedStorage.Assets.Structures/<itemId>), o colisor fica
-- invisível (os enfeites dele saem) e uma cópia do modelo vai por cima, só
-- visual; sem o modelo (Lune, outro place), fica o provisório de hoje.
-- Pivô no centro do quadrado da peça, no chão (Y = 0); o StructureService gira
-- só o pivô (yaw da peça). Tudo ancorado e com
-- CanTouch = false (o espinho é conferido por varredura, não por Touched).
-- Sai com o que o tipo oferece: estação (CraftStation + Station) e calor
-- (HeatSource + HeatRadius/BurnRadius). Dono, vida e a tag de construção quem
-- grava é o StructureService. (Só roda no Roblox: cria instâncias.)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local BuildRules = require("../Build/BuildRules")
local CampfireModel = require("./CampfireModel")
local Defs = require("../Defs")
local DoorSlide = require("../Build/DoorSlide")
local FireLight = require("./FireLight")
local Palette = require("../Palette")
local StatNames = require("../StatNames")
local Theme = require("../Theme")

type StructureDef = Defs.StructureDef

local StructureModel = {}

-- Transparência das peças da porta provisória aberta (fechada = opaca).
local OPEN_TRANSPARENCY = 0.7
-- Nome da cópia do modelo do Elizeu dentro da peça.
local VISUAL_NAME = "Visual"
-- Atributo de cada folha da porta do Elizeu: o CFrame dela fechada, relativo
-- ao pivô da peça (gravado na montagem, com a peça ainda na origem).
local PANEL_CLOSED = "PanelClosed"
local PANEL_SUFFIXES = { "_panel_left", "_panel_right" }
local FLAMES_SUFFIX = "_flames"
-- Folhas deslizando ao abrir/fechar (curto: o colisor muda na hora).
local SLIDE_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
local WALL_HEIGHT = 4
-- Lado do miolo que colide do espinho (menor que o círculo da peça). A
-- varredura do SpikeService usa o círculo da peça (raio 2), que cobre o
-- espinho inteiro (~1,7 do centro às pontas): se crescer aqui, confira SPIKE_MARGIN lá.
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
-- a peça principal (vira o PrimaryPart). É também o colisor da peça com o
-- modelo do Elizeu; tipo novo pode reaproveitar um (ex. builders.x = builders.station).
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

-- Porta com espinhos: mesmo corpo da porta (as folhas deslizam igual).
builders.spike_door = builders.door

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

-- Provisórios (colisor = bloco da bancada pelo raio da peça): extrator, fornalha,
-- ponte, telhado, placa, poço e cama. Ponte e telhado mudam na tarefa 13.
for _, kind in { "extractor", "furnace", "bridge", "roof", "sign", "well", "bed" } do
	builders[kind] = builders.station
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

-- Uma cópia do modelo do Elizeu para o item, ou nil se não houver template.
local function cloneVisual(itemId: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local structures = assets and assets:FindFirstChild("Structures")
	local template = structures and structures:FindFirstChild(itemId)
	if template == nil or not template:IsA("Model") then
		return nil
	end
	local visual = template:Clone()
	visual.Name = VISUAL_NAME
	-- Só visual, mesmo que o template venha diferente.
	for _, part in visual:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
		end
	end
	return visual
end

-- Com o modelo do Elizeu por cima: o provisório fica só com o colisor (a peça
-- principal e as que colidem), invisível; os enfeites saem.
local function hidePlaceholder(model: Model)
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		if part == model.PrimaryPart or part.CanCollide then
			part.Transparency = 1
			part.CastShadow = false
		else
			part:Destroy()
		end
	end
end

-- Primeira peça do modelo cujo nome termina com `suffix`, ou nil.
local function findBySuffix(model: Model, suffix: string): BasePart?
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") and string.sub(part.Name, -#suffix) == suffix then
			return part
		end
	end
	return nil
end

-- A luz do fogo sai da chama provisória (invisível) e vai para as chamas do
-- modelo do Elizeu. Sem chamas no template, a luz fica onde está.
local function moveFireLight(model: Model, visual: Model)
	local flames = findBySuffix(visual, FLAMES_SUFFIX)
	local primary = model.PrimaryPart
	if flames == nil or primary == nil then
		return
	end
	local old = FireLight.find(primary)
	if old then
		old:Destroy()
	end
	primary:RemoveTag(StatNames.FireLightTag)
	FireLight.attach(flames)
end

-- Portas deslizam as folhas: a porta comum e a com espinhos.
local function isDoorKind(kind: string): boolean
	return kind == "door" or kind == "spike_door"
end

-- Medida da caixa da peça (girada por `cframe`) nos eixos X e Z de quem a contém.
local function footprint(cframe: CFrame, size: Vector3): (number, number)
	local x, y, z = cframe.XVector, cframe.YVector, cframe.ZVector
	return math.abs(x.X) * size.X + math.abs(y.X) * size.Y + math.abs(z.X) * size.Z,
		math.abs(x.Z) * size.X + math.abs(y.Z) * size.Y + math.abs(z.Z) * size.Z
end

-- Grava em cada folha da porta do Elizeu onde ela fica fechada (relativo ao
-- pivô da peça, que ainda está na origem).
local function rememberPanels(model: Model, visual: Model)
	local pivot = model:GetPivot()
	for _, part in visual:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		for _, suffix in PANEL_SUFFIXES do
			if string.sub(part.Name, -#suffix) == suffix then
				part:SetAttribute(PANEL_CLOSED, pivot:ToObjectSpace(part.CFrame))
			end
		end
	end
end

function StructureModel.build(itemId: string, def: StructureDef): Model
	local model: Model
	if def.kind == "fire" then
		model = buildFire(def)
	else
		model = Instance.new("Model")
		model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
		-- Bloco provisório quadrado com o lado do diâmetro do círculo da peça.
		local side = BuildRules.radiusOf(def) * 2
		local main = builders[def.kind](model, side, colorOf(itemId))
		model.PrimaryPart = main
		-- Pivô no chão, no centro (com PrimaryPart, o pivô do modelo é o dela).
		main.PivotOffset = main.CFrame:Inverse()
	end
	model.Name = itemId
	local visual = cloneVisual(itemId)
	if visual then
		hidePlaceholder(model)
		-- Pivô do template (centro da base) no pivô da peça (centro do chão).
		visual:PivotTo(model:GetPivot())
		visual.Parent = model
		if def.kind == "fire" then
			moveFireLight(model, visual)
		elseif isDoorKind(def.kind) then
			rememberPanels(model, visual)
		end
	end
	if def.station then
		model:AddTag(StatNames.CraftStationTag)
		model:SetAttribute(StatNames.Station, def.station)
	end
	if isDoorKind(def.kind) then
		model:SetAttribute(StatNames.DoorOpen, false)
	end
	return model
end

-- Folha da porta do Elizeu desliza até a posição aberta (ou fechada), relativa
-- ao pivô atual da peça.
local function slidePanel(part: BasePart, pivot: CFrame, open: boolean)
	local closed = part:GetAttribute(PANEL_CLOSED)
	if typeof(closed) ~= "CFrame" then
		return
	end
	local target = closed
	if open then
		local sizeX, sizeZ = footprint(closed, part.Size)
		local dx, dz = DoorSlide.offset(closed.X, closed.Z, sizeX, sizeZ)
		target = CFrame.new(dx, 0, dz) * closed
	end
	-- Um tween novo na mesma propriedade cancela o anterior (abre/fecha rápido).
	TweenService:Create(part, SLIDE_INFO, { CFrame = pivot * target }):Play()
end

-- Abre (true) ou fecha a porta: aberta, nenhuma peça colide. Provisória: todas
-- ficam semitransparentes. Com o modelo do Elizeu: o colisor (invisível) solta
-- e as folhas deslizam para fora; o modelo continua opaco.
function StructureModel.setOpen(model: Model, open: boolean)
	model:SetAttribute(StatNames.DoorOpen, open)
	local visual = model:FindFirstChild(VISUAL_NAME)
	if visual == nil then
		for _, part in model:GetDescendants() do
			if part:IsA("BasePart") then
				part.CanCollide = not open
				part.Transparency = if open then OPEN_TRANSPARENCY else 0
			end
		end
		return
	end
	-- O colisor são as peças filhas diretas (o visual nunca colide).
	for _, part in model:GetChildren() do
		if part:IsA("BasePart") then
			part.CanCollide = not open
		end
	end
	local pivot = model:GetPivot()
	for _, part in visual:GetDescendants() do
		if part:IsA("BasePart") then
			slidePanel(part, pivot, open)
		end
	end
end

return StructureModel
