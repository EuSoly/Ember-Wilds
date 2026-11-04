-- Bancada das estruturas (modelos do Elizeu), no Studio em EDIT (sem rodar o jogo).
-- Rodar na barra de comandos (ou pelo MCP) trocando MODE:
--   "montar": cria Workspace.BancadaEstruturas, uma estação por modelo de
--     ReplicatedStorage.Assets.Structures: um disco travado (Locked) do tamanho
--     do círculo da peça (BuildRules.radiusOf; sem item = PIECE_RADIUS) e o
--     "Visual" por cima, posto como o StructureModel põe no jogo (pivô no centro
--     do disco, no chão; telhado a ROOF_HEIGHT). Só o Visual se seleciona.
--   Ajuste: mova, gire e redimensione o Visual em relação ao disco.
--   "captar": para cada Visual que mudou (posição, giro ou tamanho), refaz o
--     modelo de Assets.Structures com o pivô no centro do disco (desfazendo a
--     altura do telhado), guarda o antigo em ServerStorage.EstruturasAntigas
--     (nunca sobrescreve) e confere remontando como o jogo. Depois salve o place.
--   "apagar": tira a bancada.
local MODE = "montar"

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local BuildRules = require(Shared.Build.BuildRules)
local Defs = require(Shared.Defs)

local BENCH = "BancadaEstruturas"
local BACKUP = "EstruturasAntigas"
local ORIGIN = Vector3.new(-630, 0, 520) -- perto do nascimento; longe da bancada das armas (z ~ 590)
local COLUMNS = 8
local DISC_THICKNESS = 0.2
local TOLERANCE = 5e-3
-- Ordem das fileiras por tipo de peça; o que não está aqui vai numa última fileira.
local KIND_ORDER = {
	"wall",
	"door",
	"spike",
	"spike_door",
	"station",
	"chest",
	"fire",
	"extractor",
	"furnace",
	"bridge",
	"roof",
	"sign",
	"well",
	"bed",
}

local structures = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Structures")

-- Definição da peça (só existe para ids que já são itens de construção).
local function structureDef(id: string)
	local item = Defs.Items[id]
	return item and item.structure
end

local function radiusOf(id: string): number
	local def = structureDef(id)
	return if def then BuildRules.radiusOf(def) else BuildRules.PIECE_RADIUS
end

-- Altura do pivô do modelo acima do chão, igual ao StructureModel.build.
local function liftOf(id: string): number
	local def = structureDef(id)
	return if def and BuildRules.layerOf(def.kind) == "roof" then BuildRules.ROOF_HEIGHT else 0
end

-- Centro do disco no chão (o pivô da peça no jogo, sem giro).
local function groundOf(disc: BasePart): CFrame
	return CFrame.new(disc.Position - Vector3.new(0, DISC_THICKNESS / 2, 0))
end

-- Como o StructureModel põe o template na peça: pivô do template no centro do
-- chão, mais a altura do telhado.
local function placeLikeGame(model: Model, ground: CFrame, id: string)
	model:PivotTo(ground * CFrame.new(0, liftOf(id), 0))
end

local function partsOf(model: Instance): { BasePart }
	local list = {}
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			table.insert(list, d)
		end
	end
	return list
end

local function visualOnly(model: Instance, locked: boolean)
	for _, part in partsOf(model) do
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		part.Locked = locked
	end
end

-- Maior diferença (posição, tamanho e giro) entre as peças de dois modelos iguais.
local function difference(a: Model, b: Model): number
	local pa, pb = partsOf(a), partsOf(b)
	if #pa ~= #pb then
		return math.huge
	end
	local worst = 0
	for i, part in pa do
		local other = pb[i]
		local _, turned = part.CFrame.Rotation:ToObjectSpace(other.CFrame.Rotation):ToAxisAngle()
		worst = math.max(
			worst,
			(part.Position - other.Position).Magnitude,
			(part.Size - other.Size).Magnitude,
			math.abs(turned)
		)
	end
	return worst
end

local function makeDisc(id: string, ground: Vector3): Part
	local radius = radiusOf(id)
	local disc = Instance.new("Part")
	disc.Name = "Disco"
	disc.Shape = Enum.PartType.Cylinder
	disc.Size = Vector3.new(DISC_THICKNESS, radius * 2, radius * 2) -- o eixo do cilindro é o X
	disc.CFrame = CFrame.new(ground + Vector3.new(0, DISC_THICKNESS / 2, 0)) * CFrame.Angles(0, 0, math.pi / 2)
	disc.Color = Color3.fromRGB(80, 160, 255)
	disc.Material = Enum.Material.SmoothPlastic
	disc.Transparency = 0.6
	disc.Anchored = true
	disc.CanCollide = false
	disc.CanTouch = false
	disc.Locked = true

	local gui = Instance.new("BillboardGui")
	gui.Size = UDim2.fromOffset(160, 24)
	gui.StudsOffset = Vector3.new(0, 1, 0)
	gui.AlwaysOnTop = true
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.3
	label.TextScaled = true
	label.Text = id
	label.Parent = gui
	gui.Parent = disc
	return disc
end

local function montar()
	local old = workspace:FindFirstChild(BENCH)
	if old then
		old:Destroy()
	end
	local bench = Instance.new("Model")
	bench.Name = BENCH

	-- Fileiras por tipo; dentro de cada uma, ids em ordem, quebrando a cada COLUMNS.
	local byKind: { [string]: { string } } = {}
	local maxRadius = BuildRules.PIECE_RADIUS
	for _, template in structures:GetChildren() do
		if not template:IsA("Model") then
			continue
		end
		local def = structureDef(template.Name)
		local kind = if def then def.kind else "outro"
		byKind[kind] = byKind[kind] or {}
		table.insert(byKind[kind], template.Name)
		maxRadius = math.max(maxRadius, radiusOf(template.Name))
	end
	local order = table.clone(KIND_ORDER)
	for kind in byKind do
		if not table.find(order, kind) and kind ~= "outro" then
			table.insert(order, kind)
		end
	end
	table.insert(order, "outro")
	local spacing = maxRadius * 2 + 3

	local row = 0
	for _, kind in order do
		local ids = byKind[kind]
		if ids == nil then
			continue
		end
		table.sort(ids)
		for index, id in ids do
			local template = structures:FindFirstChild(id) :: Model
			local column = (index - 1) % COLUMNS
			local line = row + (index - 1) // COLUMNS
			local ground = ORIGIN + Vector3.new(column * spacing, 0, -line * spacing)

			local station = Instance.new("Model")
			station.Name = id
			makeDisc(id, ground).Parent = station

			local visual = template:Clone()
			visual.Name = "Visual"
			visualOnly(visual, false)
			placeLikeGame(visual, CFrame.new(ground), id)
			visual.Parent = station
			station.Parent = bench
		end
		row += (#ids + COLUMNS - 1) // COLUMNS
	end

	bench.Parent = workspace
	local camera = workspace.CurrentCamera
	local center = ORIGIN + Vector3.new((COLUMNS - 1) * spacing / 2, 0, -(row - 1) * spacing / 2)
	camera.CFrame = CFrame.lookAt(center + Vector3.new(0, 60, 45), center)
	return `bancada montada: {#bench:GetChildren()} estruturas`
end

-- Guarda o template antigo em ServerStorage.EstruturasAntigas, sem sobrescrever.
local function backUp(template: Instance)
	local folder = ServerStorage:FindFirstChild(BACKUP)
	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = BACKUP
		folder.Parent = ServerStorage
	end
	local name = template.Name
	local n = 1
	while folder:FindFirstChild(name) do
		n += 1
		name = `{template.Name}_{n}`
	end
	template.Name = name
	template.Parent = folder
end

local function captar()
	local bench = workspace:FindFirstChild(BENCH)
	assert(bench, "monte a bancada antes (MODE = montar)")
	local changed, failed = {}, {}
	for _, station in bench:GetChildren() do
		local id = station.Name
		local template = structures:FindFirstChild(id)
		local visual = station:FindFirstChild("Visual")
		local disc = station:FindFirstChild("Disco")
		if template == nil or visual == nil or disc == nil then
			continue
		end
		local ground = groundOf(disc)

		-- O Visual mudou? Compara com o template posto como o jogo põe.
		local reference = template:Clone() :: Model
		placeLikeGame(reference, ground, id)
		local moved = difference(reference, visual :: Model)
		reference:Destroy()
		if moved <= TOLERANCE then
			continue
		end

		-- Refaz o template: pivô = centro do disco (desfaz a altura do telhado)
		-- e leva para a origem.
		local rebuilt = visual:Clone() :: Model
		rebuilt.Name = id
		rebuilt.WorldPivot = ground * CFrame.new(0, liftOf(id), 0)
		rebuilt:PivotTo(CFrame.new())
		visualOnly(rebuilt, false)
		for name, value in template:GetAttributes() do
			rebuilt:SetAttribute(name, value)
		end

		-- Confere remontando como o jogo e comparando com o Visual ajustado.
		local check = rebuilt:Clone()
		placeLikeGame(check, ground, id)
		local error_ = difference(check, visual :: Model)
		check:Destroy()
		if error_ > TOLERANCE then
			table.insert(failed, `{id} (erro {error_})`)
			rebuilt:Destroy()
			continue
		end

		local parent = template.Parent
		backUp(template)
		rebuilt.Parent = parent
		table.insert(changed, id)
	end
	table.sort(changed)
	local summary = if #changed == 0 then "nada mudou" else `gravados {#changed}: {table.concat(changed, ", ")}`
	if #failed > 0 then
		return `{summary}. CONFERENCIA FALHOU (nao gravados): {table.concat(failed, ", ")}`
	end
	if #changed == 0 then
		return summary
	end
	return `{summary}. Conferido remontando (tolerancia {TOLERANCE}). Antigos em ServerStorage.{BACKUP}. Salve o place.`
end

if MODE == "montar" then
	return montar()
elseif MODE == "captar" then
	return captar()
elseif MODE == "apagar" then
	local bench = workspace:FindFirstChild(BENCH)
	if bench then
		bench:Destroy()
	end
	return "bancada apagada"
end
error(`MODE desconhecido: {MODE}`)
