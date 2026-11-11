--!strict
-- Fantasma da construção: com uma peça `placeable` na mão, mostra o MODELO da
-- peça translúcido (StructureModel.build, o mesmo do servidor) no ponto à frente
-- (o mesmo que o servidor escolhe), girado como a peça sairá (o giro vem de
-- BuildRotation), pintado de verde se parece livre e vermelho se não (Highlight).
-- Peça de chão/teto com snap encaixa na grade da vizinha mais perto
-- (BuildRules.snapPlacement, a mesma conta do servidor). Sem modelo, volta ao
-- bloco com a faixa da frente. É só uma dica: o servidor decide de verdade. A água é a mesma regra do servidor (WaterSim.isWaterAt +
-- BuildRules.waterAllows: ponte só na água, o resto nunca).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local BuildRules = require(Shared:WaitForChild("Build"):WaitForChild("BuildRules"))
local Defs = require(Shared:WaitForChild("Defs"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local StructureModel = require(Shared:WaitForChild("Models"):WaitForChild("StructureModel"))
local Theme = require(Shared:WaitForChild("Theme"))
local WaterSim = require(Shared:WaitForChild("Simulation"):WaitForChild("WaterSim"))
local BuildRotation = require(script.Parent.Parent:WaitForChild("BuildRotation"))

local THICKNESS = 0.3
local TRANSPARENCY = 0.55
-- O teste de "livre" varre recursos e peças; refaz só a cada tanto.
local REFRESH = 0.15
-- Recursos além disto (studs, do centro da peça) nem são considerados.
local RESOURCE_RANGE = 12
local RESOURCE_MAX_RADIUS = 4
-- Faixa da frente: comprimento (fração do raio) e espessura, em studs.
local FRONT_LENGTH = 0.5
local FRONT_WIDTH = 0.4
-- Modelo do fantasma: transparência das partes e do preenchimento do Highlight.
local MODEL_TRANSPARENCY = 0.45
local FILL_TRANSPARENCY = 0.6

local BuildGhost = {}

local function makePart(name: string): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = TRANSPARENCY
	return part
end

-- A peça do item se ele é uma peça colocável; nil se não é.
local function structureOf(itemId: unknown): Defs.StructureDef?
	if typeof(itemId) ~= "string" then
		return nil
	end
	local item = Defs.Items[itemId]
	if item == nil or item.category ~= "placeable" then
		return nil
	end
	return item.structure
end

local function pivotXZ(instance: Instance): (number?, number?)
	if instance:IsA("PVInstance") then
		local position = instance:GetPivot().Position
		return position.X, position.Z
	end
	return nil, nil
end

local function extentOf(instance: Instance): number
	if instance:IsA("Model") then
		local size = instance:GetExtentsSize()
		return math.max(size.X, size.Z) / 2
	elseif instance:IsA("BasePart") then
		return math.max(instance.Size.X, instance.Size.Z) / 2
	end
	return 0
end

-- Nenhum jogador (inclusive o próprio) sobrepondo o círculo?
local function looksFreeOfPlayers(px: number, pz: number, radius: number): boolean
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			if
				BuildRules.circlesOverlap(px, pz, radius, root.Position.X, root.Position.Z, BuildRules.PLAYER_RADIUS)
			then
				return false
			end
		end
	end
	return true
end

-- O círculo (centro px, pz; raio radius) de uma peça `kind` parece livre? As
-- mesmas camadas do servidor (BuildRules.layerOf): o telhado só vê telhados, a
-- ponte só pontes e jogadores.
local function looksFree(kind: string, px: number, pz: number, radius: number): boolean
	if not BuildRules.waterAllows(kind, WaterSim.isWaterAt(px, pz)) then
		return false
	end
	local layer = BuildRules.layerOf(kind)
	-- Peças já colocadas: o pivô fica no centro da peça.
	for _, instance in CollectionService:GetTagged(StatNames.StructureTag) do
		local x, z = pivotXZ(instance)
		-- Longe demais para tocar: nem lê o atributo.
		if x and z and math.abs(x - px) <= radius + RESOURCE_RANGE and math.abs(z - pz) <= radius + RESOURCE_RANGE then
			local other = structureOf(instance:GetAttribute(StatNames.StructureItem))
			local otherKind = if other then other.kind else "wall"
			local otherRadius = if other then BuildRules.radiusOf(other) else BuildRules.PIECE_RADIUS
			if
				BuildRules.blocksPlacement(kind, otherKind)
				and BuildRules.circlesOverlap(px, pz, radius, x, z, otherRadius)
			then
				return false
			end
		end
	end
	if layer == "roof" then
		return true
	end
	if layer ~= "solid" then
		return looksFreeOfPlayers(px, pz, radius)
	end
	-- Recursos: o raio de colisão que o servidor publica; sem ele, aproxima
	-- pelo tamanho do modelo.
	for _, instance in CollectionService:GetTagged(StatNames.ResourceTag) do
		local x, z = pivotXZ(instance)
		if x and z and math.abs(x - px) <= radius + RESOURCE_RANGE and math.abs(z - pz) <= radius + RESOURCE_RANGE then
			local published = instance:GetAttribute(StatNames.ResourceRadius)
			local resourceRadius = if typeof(published) == "number"
				then published
				else math.min(extentOf(instance), RESOURCE_MAX_RADIUS)
			if BuildRules.circlesOverlap(px, pz, radius, x, z, resourceRadius) then
				return false
			end
		end
	end
	return looksFreeOfPlayers(px, pz, radius)
end

-- Peças de chão/teto (snap) já colocadas perto de (px, pz), da mesma camada.
local function snapNeighbors(def: Defs.StructureDef, px: number, pz: number): { BuildRules.SnapNeighbor }
	local layer = BuildRules.layerOf(def.kind)
	local range = 2 * BuildRules.radiusOf(def) + BuildRules.SNAP_RANGE + RESOURCE_MAX_RADIUS
	local out: { BuildRules.SnapNeighbor } = {}
	for _, instance in CollectionService:GetTagged(StatNames.StructureTag) do
		if instance:IsA("PVInstance") then
			local pivot = instance:GetPivot()
			local x, z = pivot.Position.X, pivot.Position.Z
			if math.abs(x - px) <= range and math.abs(z - pz) <= range then
				local other = structureOf(instance:GetAttribute(StatNames.StructureItem))
				if other and other.snap and BuildRules.layerOf(other.kind) == layer then
					local _, yaw = pivot:ToOrientation()
					table.insert(out, { x = x, z = z, yaw = math.deg(yaw), radius = BuildRules.radiusOf(other) })
				end
			end
		end
	end
	return out
end

-- Modelo da peça como fantasma: translúcido, sem colisão nem tags (senão o
-- jogo acharia uma bancada, ponte ou telhado de verdade ali). nil sem modelo.
local function ghostModel(itemId: string, def: Defs.StructureDef): (Model?, Highlight?)
	local ok, built = pcall(StructureModel.build, itemId, def)
	if not ok then
		return nil, nil
	end
	local model = built :: Model
	for _, instance in { model :: Instance, unpack(model:GetDescendants()) } do
		for _, tag in CollectionService:GetTags(instance) do
			CollectionService:RemoveTag(instance, tag)
		end
		if instance:IsA("BasePart") then
			instance.Anchored = true
			instance.CanCollide = false
			instance.CanQuery = false
			instance.CanTouch = false
			instance.CastShadow = false
			instance.Transparency = math.max(instance.Transparency, MODEL_TRANSPARENCY)
		elseif instance:IsA("Script") or instance:IsA("LocalScript") then
			instance:Destroy()
		end
	end
	model.Name = "BuildGhost"
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = FILL_TRANSPARENCY
	highlight.OutlineTransparency = 0.2
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Parent = model
	return model, highlight
end

function BuildGhost.start()
	local ghost = makePart("BuildGhost")
	local front = makePart("Front")
	front.Parent = ghost
	local lastRadius = 0
	local lastCheck = 0
	local free = false
	-- Modelo do fantasma da peça na mão (refeito ao trocar de item).
	local modelItem: string? = nil
	local model: Model? = nil
	local highlight: Highlight? = nil
	local function clearModel()
		if model then
			model:Destroy()
		end
		model, highlight, modelItem = nil, nil, nil
	end

	RunService.RenderStepped:Connect(function()
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		-- Polling de propósito: com Server Authority o AttributeChanged não
		-- dispara no personagem previsto local.
		local equipped = if character then character:GetAttribute(StatNames.Equipped) else nil
		local structure = structureOf(equipped)
		if structure == nil or root == nil or not root:IsA("BasePart") then
			ghost.Parent = nil
			clearModel()
			lastRadius = 0
			return
		end
		local itemId = equipped :: string
		if modelItem ~= itemId then
			clearModel()
			modelItem = itemId
			model, highlight = ghostModel(itemId, structure)
		end

		local look = root.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 1e-3 then
			return
		end
		flat = flat.Unit
		local radius = BuildRules.radiusOf(structure)
		local px, pz = BuildRules.placePoint(root.Position.X, root.Position.Z, flat.X, flat.Z)
		local steps = vide.untrack(BuildRotation.steps)
		local yaw = BuildRules.facingYaw(px, pz, root.Position.X, root.Position.Z, steps)
		if structure.snap then
			px, pz, yaw = BuildRules.snapPlacement(px, pz, yaw, flat.X, flat.Z, snapNeighbors(structure, px, pz))
		end

		-- Refaz o teste só a cada REFRESH (ou ao trocar de peça): a varredura
		-- é cara para rodar todo quadro.
		local now = os.clock()
		if radius ~= lastRadius or now - lastCheck >= REFRESH then
			lastRadius = radius
			lastCheck = now
			free = looksFree(structure.kind, px, pz, radius)
		end

		local color = if free then Theme.ui.success else Theme.ui.danger
		-- Com modelo: só ele (o bloco some). Parte local: não replica.
		if model and highlight then
			ghost.Parent = nil
			highlight.FillColor = color
			highlight.OutlineColor = color
			model:PivotTo(CFrame.new(px, 0, pz) * CFrame.Angles(0, math.rad(yaw), 0))
			model.Parent = Workspace
			return
		end
		local side = radius * 2
		-- O topo do chão do mapa é Y = 0.
		local cframe = CFrame.new(px, THICKNESS / 2, pz) * CFrame.Angles(0, math.rad(yaw), 0)
		ghost.Size = Vector3.new(side, THICKNESS, side)
		ghost.Color = color
		ghost.CFrame = cframe
		-- A frente é o -Z da peça (LookVector); a faixa fica rente à borda.
		front.Size = Vector3.new(radius * FRONT_LENGTH, THICKNESS + 0.04, FRONT_WIDTH)
		front.Color = color:Lerp(Color3.new(0, 0, 0), 0.5)
		front.CFrame = cframe * CFrame.new(0, 0, -(radius - FRONT_WIDTH / 2))
		-- Parte local: não replica.
		ghost.Parent = Workspace
	end)
end

return BuildGhost
