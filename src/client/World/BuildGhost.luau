--!strict
-- Fantasma da construção: com uma peça `placeable` na mão, mostra um bloco
-- translúcido na célula-alvo (a mesma que o servidor escolhe), verde se ela
-- parece livre e vermelha se não. É só uma dica: o servidor decide de verdade
-- (inclusive água, que o cliente não checa).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BuildRules = require(Shared:WaitForChild("Build"):WaitForChild("BuildRules"))
local Defs = require(Shared:WaitForChild("Defs"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))

-- Mesma folga do servidor entre o corpo e a peça.
local PLAYER_MARGIN = 1.5
local THICKNESS = 0.3
-- Quantos studs o chão fica abaixo da raiz do boneco (aproximado).
local GROUND_BELOW_ROOT = 2.9
local TRANSPARENCY = 0.55
-- O teste de "livre" varre recursos e peças; refaz só a cada tanto.
local REFRESH = 0.15
-- Recursos além disto (studs, do centro da célula) nem são considerados.
local RESOURCE_RANGE = 12
local RESOURCE_MAX_RADIUS = 4

local BuildGhost = {}

local function makeGhost(): Part
	local ghost = Instance.new("Part")
	ghost.Name = "BuildGhost"
	ghost.Anchored = true
	ghost.CanCollide = false
	ghost.CanQuery = false
	ghost.CanTouch = false
	ghost.CastShadow = false
	ghost.Material = Enum.Material.SmoothPlastic
	ghost.Transparency = TRANSPARENCY
	return ghost
end

-- Tamanho em células se o item é uma peça colocável; nil se não é.
local function sizeOfItem(itemId: unknown): number?
	if typeof(itemId) ~= "string" then
		return nil
	end
	local item = Defs.Items[itemId]
	if item == nil or item.category ~= "placeable" then
		return nil
	end
	local structure = item.structure
	return if structure and structure.size then structure.size else 1
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

-- A célula (canto cx, cz, size×size) parece livre?
local function looksFree(cx: number, cz: number, size: number): boolean
	local cell = BuildRules.CELL
	local half = size * cell / 2
	local mine = {}
	for _, key in BuildRules.cellsOf(cx, cz, size) do
		mine[key] = true
	end
	-- Peças já colocadas: o pivô fica no centro da peça.
	for _, instance in CollectionService:GetTagged(StatNames.StructureTag) do
		local x, z = pivotXZ(instance)
		if x and z then
			local otherSize = sizeOfItem(instance:GetAttribute(StatNames.StructureItem)) or 1
			local otherHalf = otherSize * cell / 2
			local ox, oz = BuildRules.cellOf(x - otherHalf + 0.01, z - otherHalf + 0.01)
			for _, key in BuildRules.cellsOf(ox, oz, otherSize) do
				if mine[key] then
					return false
				end
			end
		end
	end
	-- Recursos: aproximado pelo tamanho do modelo (o servidor usa o raio de colisão).
	local centerX, centerZ = (cx * cell) + half, (cz * cell) + half
	for _, instance in CollectionService:GetTagged(StatNames.ResourceTag) do
		local x, z = pivotXZ(instance)
		if
			x
			and z
			and math.abs(x - centerX) <= half + RESOURCE_RANGE
			and math.abs(z - centerZ) <= half + RESOURCE_RANGE
		then
			if BuildRules.touches(x, z, cx, cz, size, math.min(extentOf(instance), RESOURCE_MAX_RADIUS)) then
				return false
			end
		end
	end
	-- Jogadores (inclusive o próprio).
	for _, player in Players:GetPlayers() do
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		if root and root:IsA("BasePart") then
			if BuildRules.touches(root.Position.X, root.Position.Z, cx, cz, size, PLAYER_MARGIN) then
				return false
			end
		end
	end
	return true
end

function BuildGhost.start()
	local ghost = makeGhost()
	local lastKey = ""
	local lastCheck = 0
	local free = false

	RunService.RenderStepped:Connect(function()
		local character = Players.LocalPlayer.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		-- Polling de propósito: com Server Authority o AttributeChanged não
		-- dispara no personagem previsto local.
		local size = if character then sizeOfItem(character:GetAttribute(StatNames.Equipped)) else nil
		if size == nil or root == nil or not root:IsA("BasePart") then
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
		local cx, cz = BuildRules.targetCell(root.Position.X, root.Position.Z, flat.X, flat.Z)

		local key = `{cx},{cz},{size}`
		local now = os.clock()
		if key ~= lastKey or now - lastCheck >= REFRESH then
			lastKey = key
			lastCheck = now
			free = looksFree(cx, cz, size)
		end

		local side = size * BuildRules.CELL
		local half = side / 2
		ghost.Size = Vector3.new(side, THICKNESS, side)
		ghost.Color = if free then Theme.ui.success else Theme.ui.danger
		ghost.Position = Vector3.new(
			cx * BuildRules.CELL + half,
			root.Position.Y - GROUND_BELOW_ROOT + THICKNESS / 2,
			cz * BuildRules.CELL + half
		)
		-- Parte local: não replica.
		ghost.Parent = Workspace
	end)
end

return BuildGhost
