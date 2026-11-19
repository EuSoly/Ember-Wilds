-- Importa os modelos da praia do Elizeu (19/11/2026; Blender: assets/praia/Praia.blend,
-- importados no Studio como Workspace["Praia - Ember Wilds"]) para
-- ServerStorage.Assets.Resources, com os nomes que o MapService usa:
--   palm_1 (Palmeira alta), palm_2 (Coqueiro inclinado)      -> recurso palm (madeira)
--   sand_mound_1..3 (Areia baixa, dupla, com conchas)        -> enfeite
--   shell_1..2 (Concha espiral, leque)                        -> enfeite
-- Nas palmeiras põe um Attachment "Foot" no pé do tronco, achado pelos vértices
-- mais baixos da malha (o ResourceModels ancora o recurso ali). O original vai
-- para ServerStorage.ImportsOriginais.Praia. Rodar em Edit e salvar o place.
local AssetService = game:GetService("AssetService")
local ServerStorage = game:GetService("ServerStorage")

local SOURCE = workspace:FindFirstChild("Praia - Ember Wilds")
assert(SOURCE, 'falta Workspace["Praia - Ember Wilds"]')
local DEST = ServerStorage.Assets.Resources
local NAMES = {
	{ "Palmeira alta_Node", "palm_1", true },
	{ "Coqueiro inclinado_Node", "palm_2", true },
	{ "Areia baixa_Node", "sand_mound_1", false },
	{ "Areia dupla_Node", "sand_mound_2", false },
	{ "Areia com conchas_Node", "sand_mound_3", false },
	{ "Concha espiral_Node", "shell_1", false },
	{ "Concha leque_Node", "shell_2", false },
}
local FOOT_BAND = 0.6 -- studs acima do ponto mais baixo que contam como "pé"

-- Centro dos vértices mais baixos da malha, em coordenadas do mundo.
local function footOf(part: MeshPart): Vector3
	local mesh = AssetService:CreateEditableMeshAsync(Content.fromUri(part.MeshId))
	local scale = part.Size / part.MeshSize
	local points: { Vector3 } = {}
	local minY = math.huge
	for _, vertex in mesh:GetVertices() do
		local p = part.CFrame:PointToWorldSpace(mesh:GetPosition(vertex) * scale)
		table.insert(points, p)
		minY = math.min(minY, p.Y)
	end
	local sum, count = Vector3.zero, 0
	for _, p in points do
		if p.Y < minY + FOOT_BAND then
			sum += Vector3.new(p.X, minY, p.Z)
			count += 1
		end
	end
	return sum / count
end

for _, entry in NAMES do
	local node = SOURCE:FindFirstChild(entry[1])
	assert(node, `falta {entry[1]}`)
	local old = DEST:FindFirstChild(entry[2])
	if old then
		old:Destroy()
	end
	local model = node:Clone()
	model.Name = entry[2]
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
			d.CanTouch = false
			d.CanQuery = false
		end
	end
	if entry[3] then
		local part = model:FindFirstChildWhichIsA("MeshPart", true) :: MeshPart
		local mark = Instance.new("Attachment")
		mark.Name = "Foot"
		mark.Parent = part
		mark.WorldPosition = footOf(part)
	end
	model.Parent = DEST
end

local backup = ServerStorage:FindFirstChild("ImportsOriginais") or Instance.new("Folder")
backup.Name = "ImportsOriginais"
backup.Parent = ServerStorage
local previous = backup:FindFirstChild("Praia")
if previous then
	previous:Destroy()
end
SOURCE.Name = "Praia"
SOURCE.Parent = backup
print("[import-praia] pronto: salve o place")
