-- Ember Wilds: instalar os 16 ícones e o arbusto com 5 frutas independentes.
-- Em EDIT, importe os 3 FBXs sem unir malhas, selecione seus 3 Models no
-- Explorer e execute este código inteiro na Command Bar.
-- Mantém as importações no Workspace e guarda todos os moldes anteriores.
local RunService = game:GetService("RunService")
local Selection = game:GetService("Selection")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
assert(not RunService:IsRunning(), "Pare o Play antes de instalar os assets.")

local IDS = {
	"paper",
	"blue_thread",
	"black_wolf_fur",
	"white_wolf_fur",
	"blue_cube",
	"lava_cube",
	"dragon_orb",
	"lava_orb",
	"blue_gem",
	"green_gem",
	"orange_gem",
	"firefly",
	"pilot_glasses",
	"pitchfork_part",
	"water_bucket",
	"bucket",
}
local wanted = { Foliage = true }
for _, id in IDS do
	wanted[id] = true
end
for i = 1, 5 do
	wanted[string.format("Berry_%02d", i)] = true
end

local selected = Selection:Get()
assert(#selected > 0, "Selecione os Models dos três FBXs importados no Workspace.")
local found, seen = {}, {}
for _, container in selected do
	assert(
		container:IsDescendantOf(workspace) and (container:IsA("Model") or container:IsA("Folder")),
		"Selecione somente os Models/pastas importados dentro do Workspace."
	)
	for _, part in container:GetDescendants() do
		if part:IsA("MeshPart") and wanted[part.Name] and not seen[part] then
			assert(found[part.Name] == nil, "Peça duplicada na seleção: " .. part.Name)
			seen[part] = true
			found[part.Name] = part
		end
	end
end
for name in wanted do
	assert(found[name], "Falta " .. name .. ". Importe os 3 FBXs sem unir as malhas e selecione os três Models.")
end

local function existingFolder(parent, name)
	local folder = parent and parent:FindFirstChild(name)
	assert(folder == nil or folder:IsA("Folder"), name .. " precisa ser uma Folder.")
	return folder
end
local replicatedAssets = existingFolder(ReplicatedStorage, "Assets")
local oldIcons = existingFolder(replicatedAssets, "Icons")
local serverAssets = existingFolder(ServerStorage, "Assets")
local oldResources = existingFolder(serverAssets, "Resources")
local oldBush = oldResources and oldResources:FindFirstChild("berry_bush_1")
assert(oldBush == nil or oldBush:IsA("Model"), "O molde berry_bush_1 precisa ser Model.")

local function clonePart(source, name, parent)
	local part = source:Clone()
	assert(part, "A peça precisa ter Archivable habilitado: " .. source.Name)
	part.Name = name
	part.Anchored = true
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.Parent = parent
	return part
end
local function basePivot(model)
	local cf, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
	model:PivotTo(CFrame.new())
end
local function attributes(source, target)
	if source then
		for key, value in source:GetAttributes() do
			target:SetAttribute(key, value)
		end
	end
	target:SetAttribute("MissingItemsPack", "2026-11-12")
end

-- Preparar e validar tudo antes de substituir qualquer molde.
local icons = {}
for _, id in IDS do
	local model = Instance.new("Model")
	model.Name = id
	clonePart(found[id], id, model)
	basePivot(model)
	attributes(oldIcons and oldIcons:FindFirstChild(id), model)
	icons[#icons + 1] = model
end
local bush = Instance.new("Model")
bush.Name = "berry_bush_1"
clonePart(found.Foliage, "Foliage", bush)
for i = 1, 5 do
	local berry = clonePart(found[string.format("Berry_%02d", i)], "Berry", bush)
	berry:SetAttribute("HarvestIndex", i)
end
assert(#bush:GetChildren() == 6, "O arbusto precisa ter folhagem + 5 frutas.")
basePivot(bush)
if oldBush then
	local _, oldSize = oldBush:GetBoundingBox()
	local _, newSize = bush:GetBoundingBox()
	local factor = math.max(oldSize.X, oldSize.Z) / math.max(newSize.X, newSize.Z)
	assert(factor > 0 and factor < math.huge, "Escala inválida do arbusto anterior.")
	bush:ScaleTo(bush:GetScale() * factor)
	basePivot(bush)
end
attributes(oldBush, bush)

local function folder(parent, name)
	local value = parent:FindFirstChild(name)
	if value then
		return value
	end
	value = Instance.new("Folder")
	value.Name, value.Parent = name, parent
	return value
end
local iconDestination = folder(folder(ReplicatedStorage, "Assets"), "Icons")
local resourceDestination = folder(folder(ServerStorage, "Assets"), "Resources")
local backup = Instance.new("Folder")
backup.Name = "MissingItemsBackup_" .. game:GetService("HttpService"):GenerateGUID(false)
backup.Parent = ServerStorage
local changes = {}
local function install(model, destination)
	local old = destination:FindFirstChild(model.Name)
	changes[#changes + 1] = { model = model, old = old, destination = destination }
	if old then
		old.Parent = backup
	end
	model.Parent = destination
end
local ok, message = pcall(function()
	for _, model in icons do
		install(model, iconDestination)
	end
	install(bush, resourceDestination)
end)
if not ok then
	for i = #changes, 1, -1 do
		local change = changes[i]
		change.model.Parent = nil
		if change.old then
			change.old.Parent = change.destination
		end
	end
	error("Instalação desfeita: " .. tostring(message))
end
print("Instalados: 16 ícones + arbusto com 5 MeshParts chamados Berry. Backup: " .. backup:GetFullName())
print(
	"Os Models importados continuam no Workspace. Mova-os para fora do mapa ou remova-os após conferir. Salve o place."
)
print("O novo molde de arbusto será usado na próxima geração do mapa / próximo Play.")
