-- Importa as espadas e lanças do Elizeu (MeshParts deitados em
-- Workspace["espadas-e-lancas"], vindos do Blender) para
-- ReplicatedStorage.Assets.Tools, no formato que o ToolModel usa: Tool com
-- Handle (PrimaryPart) e Attachment "Grip" (Y = para a frente, na direção da
-- ponta; X = lado; Z = para cima, a face de cima do modelo continua para cima).
--
-- O eixo sai da geometria (EditableMesh): direção principal dos vértices da
-- arma de MADEIRA de cada tipo, no plano XZ (no Blender todas do tipo estão no
-- mesmo ângulo); a ponta é a que aponta para (-X, +Z). Onde a mão segura:
--   espada: no meio do cabo (entre o fim do cabo e a guarda, o trecho mais largo
--     da metade de trás);
--   lança: GRIP_SPEAR do comprimento a partir do fim da haste.
-- Escala: um fator por tipo, para a de madeira ficar com TARGET_LENGTH studs;
-- as outras mantêm a proporção do Blender.
--
-- Substitui os modelos com o mesmo nome (os provisórios de madeira/pedra/ouro).
-- Rodar no Studio (Edit, barra de comandos ou MCP) e salvar o place.
local AssetService = game:GetService("AssetService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SOURCE = workspace:FindFirstChild("espadas-e-lancas")
assert(SOURCE, 'falta Workspace["espadas-e-lancas"]')

local TARGET_LENGTH = { sword = 3.6, spear = 5.6 } -- studs, da madeira
local GRIP_SPEAR = 0.28 -- fração do comprimento, a partir do fim da haste
local TIP_HINT = Vector3.new(-1, 0, 1) -- para onde as pontas apontam no Blender
local SLICES = 40

type Shape = {
	forward: Vector3, -- unitário, no plano XZ, para a ponta
	side: Vector3, -- unitário, forward × up
	back: number, -- projeção mínima em forward (fim do cabo)
	length: number,
	gripAlong: number, -- projeção em forward onde a mão segura
	gripSide: number, -- projeção em side no meio do cabo
	gripUp: number, -- altura média
}

local function kindOf(name: string): string?
	if name:match("_sword$") then
		return "sword"
	elseif name:match("_spear$") then
		return "spear"
	end
	return nil
end

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

-- Eixo principal dos vértices no plano XZ, virado para a ponta.
local function axisOf(vertices: { Vector3 }): Vector3
	-- Média e covariância no plano XZ.
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
	-- Eixo principal (maior autovalor) da matriz 2×2.
	local angle = 0.5 * math.atan2(2 * sxz, sxx - szz)
	local forward = Vector3.new(math.cos(angle), 0, math.sin(angle))
	if forward:Dot(TIP_HINT) < 0 then
		forward = -forward
	end
	return forward
end

-- Comprimento e onde a mão segura, ao longo de `forward` (o eixo da arma de
-- madeira do mesmo tipo: no Blender todas do tipo estão no mesmo ângulo, e as
-- curvas, como a de dragão e a pirata, enganariam o eixo próprio).
local function shapeOf(vertices: { Vector3 }, kind: string, forward: Vector3): Shape
	local up = Vector3.yAxis
	local side = forward:Cross(up).Unit

	local back, front = math.huge, -math.huge
	for _, v in vertices do
		local a = v:Dot(forward)
		back = math.min(back, a)
		front = math.max(front, a)
	end
	local length = front - back

	-- Largura (em side) de cada fatia ao longo do comprimento.
	local lo, hi, sum, count = {}, {}, {}, {}
	for i = 1, SLICES do
		lo[i], hi[i], sum[i], count[i] = math.huge, -math.huge, 0, 0
	end
	local upSum = 0
	for _, v in vertices do
		local i = math.clamp(math.floor((v:Dot(forward) - back) / length * SLICES) + 1, 1, SLICES)
		local s = v:Dot(side)
		lo[i] = math.min(lo[i], s)
		hi[i] = math.max(hi[i], s)
		sum[i] += s
		count[i] += 1
		upSum += v.Y
	end

	local gripFraction
	if kind == "sword" then
		-- Guarda = fatia mais larga da metade de trás; a mão fica no meio do cabo.
		local guard, widest = math.floor(SLICES / 2), -1
		for i = 1, math.floor(SLICES / 2) do
			if count[i] > 0 and hi[i] - lo[i] > widest then
				widest = hi[i] - lo[i]
				guard = i
			end
		end
		gripFraction = (guard - 1) / SLICES / 2
	else
		gripFraction = GRIP_SPEAR
	end

	-- Centro lateral do cabo perto da mão (média das fatias vizinhas).
	local gi = math.clamp(math.floor(gripFraction * SLICES) + 1, 1, SLICES)
	local s, n = 0, 0
	for i = math.max(1, gi - 1), math.min(SLICES, gi + 1) do
		s += sum[i]
		n += count[i]
	end

	return {
		forward = forward,
		side = side,
		back = back,
		length = length,
		gripAlong = back + gripFraction * length,
		gripSide = if n > 0 then s / n else 0,
		gripUp = upSum / #vertices,
	}
end

local function build(part: MeshPart, shape: Shape, factor: number): Tool
	local tool = Instance.new("Tool")
	tool.Name = part.Name
	tool.RequiresHandle = false

	local handle = part:Clone()
	handle.Name = "Handle"
	handle.Size = part.Size * factor
	handle.CFrame = CFrame.new()
	handle.Anchored = false
	handle.CanCollide, handle.CanQuery, handle.CanTouch = false, false, false
	handle.Massless = true
	handle.Parent = tool

	local position = (shape.forward * shape.gripAlong + shape.side * shape.gripSide + Vector3.yAxis * shape.gripUp)
		* factor
	local grip = Instance.new("Attachment")
	grip.Name = "Grip"
	-- X = lado, Y = para a ponta; Z = X × Y = para cima.
	grip.CFrame = CFrame.fromMatrix(position, shape.side, shape.forward)
	grip.Parent = handle

	tool.PrimaryPart = handle
	tool:SetAttribute("Length", shape.length * factor)
	return tool
end

-- Eixo de cada tipo (pela de madeira), formas no tamanho do Blender e o fator
-- de escala de cada tipo (a de madeira fica com TARGET_LENGTH).
local axis: { [string]: Vector3 } = {}
local factor: { [string]: number } = {}
for kind in TARGET_LENGTH do
	local wood = SOURCE:FindFirstChild(`wood_{kind}`)
	assert(wood and wood:IsA("MeshPart"), `falta wood_{kind}`)
	local vertices = readVertices(wood)
	axis[kind] = axisOf(vertices)
	factor[kind] = TARGET_LENGTH[kind] / shapeOf(vertices, kind, axis[kind]).length
end

local shapes: { [MeshPart]: Shape } = {}
for _, part in SOURCE:GetChildren() do
	local kind = part:IsA("MeshPart") and kindOf(part.Name)
	if kind then
		shapes[part] = shapeOf(readVertices(part), kind, axis[kind])
	end
end

local tools = ReplicatedStorage:WaitForChild("Assets"):WaitForChild("Tools")
local made = {}
for part, shape in shapes do
	local kind = kindOf(part.Name) :: string
	-- Reimportar mantém o Tamanho já escolhido no Studio (1 na primeira vez).
	local old = tools:FindFirstChild(part.Name)
	local scale = old and old:GetAttribute("Tamanho")
	if old then
		old:Destroy()
	end
	local tool = build(part, shape, factor[kind])
	tool:SetAttribute("Tamanho", if type(scale) == "number" then scale else 1)
	tool.Parent = tools
	table.insert(made, part.Name)
end
table.sort(made)
print(`[import-weapons] {#made} armas: {table.concat(made, ", ")}`)
return made
