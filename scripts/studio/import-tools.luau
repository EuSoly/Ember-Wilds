-- Importa ferramentas e outros itens de mão do Elizeu (MeshParts deitados,
-- vindos do Blender, numa pasta do Workspace) para ReplicatedStorage.Assets.Tools,
-- no formato do ToolModel: Tool com Handle (PrimaryPart) e Attachment "Grip"
-- (Y = para a cabeça/ponta, X = lado, Z = para cima).
--
-- É um ponto de partida: o eixo de cada modelo sai da geometria (direção
-- principal dos vértices no plano XZ; a cabeça é a ponta que aponta para
-- (-X, +Z), como no Blender) e a mão fica a GRIP_FRACTION do fim do cabo.
-- Tamanho do Blender (sem escala). O ajuste fino é na bancada
-- (scripts/studio/weapon-bench.luau): mexer no Item e captar.
--
-- Um modelo com o mesmo nome em Assets.Tools é guardado antes em
-- ServerStorage.ToolsAntigos (backup) e substituído. Rodar em Edit e salvar o place.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local SOURCE_NAME = "picaretas-e-ferramentas"
local GRIP_FRACTION = 0.15 -- fração do comprimento, a partir do fim do cabo
local TIP_HINT = Vector3.new(-1, 0, 1)

local SOURCE = workspace:FindFirstChild(SOURCE_NAME)
assert(SOURCE, `falta Workspace["{SOURCE_NAME}"]`)

local function readVertices(part: MeshPart): { Vector3 }
	local mesh = AssetService:CreateEditableMeshAsync(Content.fromUri(part.MeshId))
	local scale = part.Size / part.MeshSize
	local list = {}
	for _, id in mesh:GetVertices() do
		table.insert(list, mesh:GetPosition(id) * scale)
	end
	mesh:Destroy()
	return list
end

-- Eixo principal no plano XZ (virado para a cabeça), comprimento e ponto da mão.
local function gripOf(vertices: { Vector3 }): CFrame
	local cx, cz = 0, 0
	for _, v in vertices do
		cx += v.X
		cz += v.Z
	end
	cx /= #vertices
	cz /= #vertices
	local sxx, szz, sxz = 0, 0, 0
	for _, v in vertices do
		local dx, dz = v.X - cx, v.Z - cz
		sxx += dx * dx
		szz += dz * dz
		sxz += dx * dz
	end
	local angle = 0.5 * math.atan2(2 * sxz, sxx - szz)
	local forward = Vector3.new(math.cos(angle), 0, math.sin(angle))
	if forward:Dot(TIP_HINT) < 0 then
		forward = -forward
	end
	local side = forward:Cross(Vector3.yAxis).Unit

	local back, front, upSum = math.huge, -math.huge, 0
	for _, v in vertices do
		local a = v:Dot(forward)
		back = math.min(back, a)
		front = math.max(front, a)
		upSum += v.Y
	end
	local along = back + GRIP_FRACTION * (front - back)
	-- Centro lateral perto da mão (vértices até 10% em volta).
	local window = 0.1 * (front - back)
	local s, n = 0, 0
	for _, v in vertices do
		if math.abs(v:Dot(forward) - along) <= window then
			s += v:Dot(side)
			n += 1
		end
	end
	local position = forward * along + side * (if n > 0 then s / n else 0) + Vector3.yAxis * (upSum / #vertices)
	return CFrame.fromMatrix(position, side, forward)
end

local tools = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Tools")
local backup = ServerStorage:FindFirstChild("ToolsAntigos")
if backup == nil then
	backup = Instance.new("Folder")
	backup.Name = "ToolsAntigos"
	backup.Parent = ServerStorage
end

local made = {}
for _, part in SOURCE:GetChildren() do
	if not part:IsA("MeshPart") then
		continue
	end
	local old = tools:FindFirstChild(part.Name)
	if old then
		local previous = backup:FindFirstChild(part.Name)
		if previous then
			previous:Destroy()
		end
		old.Parent = backup
	end

	local tool = Instance.new("Tool")
	tool.Name = part.Name
	tool.RequiresHandle = false
	local handle = part:Clone()
	handle.Name = "Handle"
	handle.CFrame = CFrame.new()
	handle.Anchored = false
	handle.CanCollide, handle.CanQuery, handle.CanTouch = false, false, false
	handle.Massless = true
	handle.Parent = tool
	local grip = Instance.new("Attachment")
	grip.Name = "Grip"
	grip.CFrame = gripOf(readVertices(part))
	grip.Parent = handle
	tool.PrimaryPart = handle
	tool:SetAttribute("Tamanho", 1)
	tool:SetAttribute("Pegada", 0)
	tool.Parent = tools
	table.insert(made, part.Name)
end
table.sort(made)
print(`[import-tools] {#made}: {table.concat(made, ", ")}`)
return made
