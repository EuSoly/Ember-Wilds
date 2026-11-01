--!strict
-- Fantasma da construção livre: com uma peça `placeable` na mão, mostra um bloco
-- translúcido no ponto à frente (o mesmo que o servidor escolhe), girado como a
-- peça sairá (o giro vem de BuildRotation), verde se parece livre e vermelho se
-- não. Uma faixa mais escura marca a "frente" da peça. É só uma dica: o servidor
-- decide de verdade (inclusive água, que o cliente não checa).
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
local Theme = require(Shared:WaitForChild("Theme"))
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

-- Raio da peça se o item é uma peça colocável; nil se não é.
local function radiusOfItem(itemId: unknown): number?
	if typeof(itemId) ~= "string" then
		return nil
	end
	local item = Defs.Items[itemId]
	if item == nil or item.category ~= "placeable" then
		return nil
	end
	local structure = item.structure
	return if structure then BuildRules.radiusOf(structure) else nil
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

-- O círculo (centro px, pz; raio radius) parece livre?
local function looksFree(px: number, pz: number, radius: number): boolean
	-- Peças já colocadas: o pivô fica no centro da peça.
	for _, instance in CollectionService:GetTagged(StatNames.StructureTag) do
		local x, z = pivotXZ(instance)
		if x and z then
			local otherRadius = radiusOfItem(instance:GetAttribute(StatNames.StructureItem)) or BuildRules.PIECE_RADIUS
			if BuildRules.circlesOverlap(px, pz, radius, x, z, otherRadius) then
				return false
			end
		end
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
	-- Jogadores (inclusive o próprio).
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

function BuildGhost.start()
	local ghost = makePart("BuildGhost")
	local front = makePart("Front")
	front.Parent = ghost
	local lastKey = ""
	local lastCheck = 0
	local free = false

	RunService.RenderStepped:Connect(function()
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		-- Polling de propósito: com Server Authority o AttributeChanged não
		-- dispara no personagem previsto local.
		local radius = if character then radiusOfItem(character:GetAttribute(StatNames.Equipped)) else nil
		if radius == nil or root == nil or not root:IsA("BasePart") then
			ghost.Parent = nil
			lastKey = ""
			return
		end

		local look = root.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		if flat.Magnitude < 1e-3 then
			return
		end
		flat = flat.Unit
		local px, pz = BuildRules.placePoint(root.Position.X, root.Position.Z, flat.X, flat.Z)
		local steps = vide.untrack(BuildRotation.steps)
		local yaw = BuildRules.facingYaw(px, pz, root.Position.X, root.Position.Z, steps)

		local key = `{math.floor(px * 4)},{math.floor(pz * 4)},{radius}`
		local now = os.clock()
		if key ~= lastKey or now - lastCheck >= REFRESH then
			lastKey = key
			lastCheck = now
			free = looksFree(px, pz, radius)
		end

		local side = radius * 2
		local color = if free then Theme.ui.success else Theme.ui.danger
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
