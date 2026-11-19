-- Em Edit, importe areia-e-terra.fbx sem unir malhas, selecione seu Model
-- no Explorer e execute este arquivo inteiro na Command Bar.
assert(not game:GetService("RunService"):IsRunning(), "Pare o Play antes de importar.")
local ids = { "sand", "ground" }
local found, seen = {}, {}
local selection = game:GetService("Selection"):Get()
assert(#selection > 0, "Selecione o Model importado no Workspace.")
for _, root in selection do
	assert(root:IsDescendantOf(workspace), "Selecione somente a importação no Workspace.")
	for _, part in root:GetDescendants() do
		if part:IsA("MeshPart") and table.find(ids, part.Name) and not seen[part] then
			assert(not found[part.Name], "Peça duplicada: " .. part.Name)
			found[part.Name], seen[part] = part, true
		end
	end
end
for _, id in ids do
	assert(found[id], "Falta a malha " .. id)
end
local rs = game:GetService("ReplicatedStorage")
local assets = rs:FindFirstChild("Assets")
local icons = assets and assets:FindFirstChild("Icons")
assert(not assets or assets:IsA("Folder"), "Assets precisa ser Folder.")
assert(not icons or icons:IsA("Folder"), "Icons precisa ser Folder.")
local prepared = {}
for _, id in ids do
	local model = Instance.new("Model")
	model.Name = id
	local part = assert(found[id]:Clone(), "Ative Archivable na malha " .. id)
	part.Anchored = true
	part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
	part.Parent = model
	local cf, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
	model:PivotTo(CFrame.new())
	model:SetAttribute("IconeGiro", Vector3.new(0, 180, 0))
	local old = icons and icons:FindFirstChild(id)
	if old then
		for key, value in old:GetAttributes() do
			model:SetAttribute(key, value)
		end
	end
	model:SetAttribute("SoilIconsPack", "2026-11-12")
	table.insert(prepared, model)
end
local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name, f.Parent = name, parent
	end
	return f
end
icons = folder(folder(rs, "Assets"), "Icons")
local backup = Instance.new("Folder")
backup.Name = "SoilIconsBackup_" .. game:GetService("HttpService"):GenerateGUID(false)
backup.Parent = game:GetService("ServerStorage")
for _, model in prepared do
	local old = icons:FindFirstChild(model.Name)
	if old then
		old.Parent = backup
	end
	model.Parent = icons
end
print("Areia e terra instaladas em Assets.Icons. Originais importados mantidos no Workspace; salve o place.")
print("Backup: " .. backup:GetFullName() .. ". Definições de itens/receitas não foram alteradas.")
