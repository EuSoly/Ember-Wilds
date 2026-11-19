-- Copia os modelos bottle_empty e bottle_full do pacote da fazenda
-- (ServerStorage.ImportsOriginais.DoWorkspace["farming-pack"] ou Workspace)
-- para ReplicatedStorage.Assets.Icons, no padrão de scripts/studio/import-icons.luau.
-- Rodar no Studio em Edit e salvar o place.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MARK = "IconeRelevo"
local IDS = { "bottle_empty", "bottle_full" }

local function folder(parent: Instance, name: string): Instance
	local found = parent:FindFirstChild(name)
	if found == nil then
		found = Instance.new("Folder")
		found.Name = name
		found.Parent = parent
	end
	return found
end

local assets = folder(ReplicatedStorage, "Assets")
local icons = folder(assets, "Icons")

local function stash(old: Instance)
	local backup = folder(ServerStorage, "IconesAntigos")
	local name = old.Name
	local n = 1
	while backup:FindFirstChild(name) do
		n += 1
		name = `{old.Name}_{n}`
	end
	old.Name = name
	old.Parent = backup
end

local function findSource(id: string): Instance?
	local imports = ServerStorage:FindFirstChild("ImportsOriginais")
	local fromWorkspace = imports and imports:FindFirstChild("DoWorkspace")
	local pack = (fromWorkspace and fromWorkspace:FindFirstChild("farming-pack"))
		or workspace:FindFirstChild("farming-pack")
	if pack then
		local direct = pack:FindFirstChild(id, true)
		if direct then
			return direct
		end
	end
	return workspace:FindFirstChild(id, true)
end

local made, missing = {}, {}
for _, id in IDS do
	local src = findSource(id)
	if src == nil then
		table.insert(missing, id)
		continue
	end
	local model: Model
	if src:IsA("Model") then
		model = src:Clone()
	elseif src:IsA("BasePart") then
		model = Instance.new("Model")
		local clone = src:Clone()
		clone.Parent = model
	else
		table.insert(missing, id)
		continue
	end
	model.Name = id
	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.Anchored = true
			desc.CanCollide, desc.CanQuery, desc.CanTouch = false, false, false
		end
	end
	local cf, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
	model:PivotTo(CFrame.new())
	model:SetAttribute(MARK, true)

	local old = icons:FindFirstChild(id)
	if old then
		if old:GetAttribute(MARK) then
			old:Destroy()
		else
			stash(old)
		end
	end
	model.Parent = icons
	table.insert(made, id)
end

local summary = `[import-bottles] {#made} ícones em Assets.Icons ({table.concat(made, ", ")})`
if #missing > 0 then
	summary ..= `\n[import-bottles] faltaram ({#missing}): {table.concat(missing, ", ")}`
end
print(summary)
return summary
