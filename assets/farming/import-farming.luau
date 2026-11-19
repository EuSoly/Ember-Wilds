-- Em EDIT: importe farming-pack.fbx SEM unir malhas, selecione o Model
-- importado no Explorer e execute este arquivo inteiro na Command Bar.
-- Instala somente modelos/atributos. Não implementa rega, receitas ou timers.
assert(not game:GetService("RunService"):IsRunning(), "Pare o Play antes da importação.")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local crops = { "berry", "wheat", "pumpkin", "thorn", "carrot", "tomato", "watermelon", "aloe_vera", "garlic" }
local harvestCounts =
	{ berry = 5, wheat = 3, pumpkin = 1, thorn = 0, carrot = 3, tomato = 3, watermelon = 1, aloe_vera = 1, garlic = 3 }
local harvestWhole = { carrot = true, garlic = true, aloe_vera = true }
local specs = {}
for _, crop in crops do
	for stage = 1, 4 do
		local roles = {}
		if stage < 4 or not harvestWhole[crop] then
			table.insert(roles, "Foliage")
		end
		if stage == 4 then
			for i = 1, harvestCounts[crop] do
				table.insert(roles, string.format("Harvest_%02d", i))
			end
		end
		table.insert(
			specs,
			{
				id = string.format("%s_stage_%02d", crop, stage),
				kind = "plant",
				crop = crop,
				stage = stage,
				roles = roles,
			}
		)
	end
	table.insert(specs, { id = crop .. "_seeds", kind = "seed", crop = crop, roles = { "Icon" } })
end
for _, id in { "bottle_empty", "bottle_full", "ice_cube" } do
	table.insert(specs, { id = id, kind = "supply", roles = { "Icon" } })
end
table.insert(specs, { id = "planter_box", kind = "structure", roles = { "Frame", "Soil" } })
assert(#specs == 49)

local wanted, found, seen = {}, {}, {}
for _, spec in specs do
	wanted[spec.id .. "__Origin"] = true
	for _, role in spec.roles do
		wanted[spec.id .. "__" .. role] = true
	end
end
local selection = game:GetService("Selection"):Get()
assert(#selection > 0, "Selecione o Model importado de farming-pack.fbx no Workspace.")
for _, container in selection do
	assert(
		container:IsDescendantOf(workspace) and (container:IsA("Model") or container:IsA("Folder")),
		"Selecione somente Models/pastas importados no Workspace."
	)
	for _, part in container:GetDescendants() do
		if part:IsA("MeshPart") and wanted[part.Name] and not seen[part] then
			assert(found[part.Name] == nil, "Peça duplicada: " .. part.Name)
			found[part.Name], seen[part] = part, true
		end
	end
end
for name in wanted do
	assert(found[name], "Falta " .. name .. ". Importe o arquivo completo sem unir as malhas.")
end

local function checkFolder(parent, name)
	local f = parent and parent:FindFirstChild(name)
	assert(f == nil or f:IsA("Folder"), "Destino incompatível: " .. name)
	return f
end
local oldAssets = checkFolder(ReplicatedStorage, "Assets")
checkFolder(oldAssets, "Icons")
checkFolder(oldAssets, "Structures")
local oldFarming = checkFolder(oldAssets, "Farming")
for _, crop in crops do
	checkFolder(oldFarming, crop)
end

-- Preserve the explicit shared origin. Never recenter a crop by its bounds.
local prepared = {}
for _, spec in specs do
	local marker = found[spec.id .. "__Origin"]
	local model = Instance.new("Model")
	model.Name = if spec.kind == "plant" then string.format("stage_%02d", spec.stage) else spec.id
	model:SetAttribute("AssetId", spec.id)
	model:SetAttribute("FarmArtVersion", "2026-11-12")
	if spec.crop then
		model:SetAttribute("CropId", spec.crop)
	end
	if spec.stage then
		model:SetAttribute("GrowthStage", spec.stage)
	end
	if spec.kind == "structure" then
		model:SetAttribute("SoilHeight", 0.54 * marker.Size.Y / 0.04)
		model:SetAttribute("PlantAreaWidth", 3.4 * marker.Size.X / 0.04)
	end
	for _, role in spec.roles do
		local source = found[spec.id .. "__" .. role]
		local clone = source:Clone()
		assert(clone, "Ative Archivable na peça " .. source.Name)
		clone.Name = role
		clone.Anchored = true
		clone.CanCollide, clone.CanTouch, clone.CanQuery = false, false, false
		local index = string.match(role, "^Harvest_(%d+)$")
		if index then
			clone.Name = if spec.crop == "berry" then "Berry" else "Harvest"
			clone:SetAttribute("HarvestIndex", tonumber(index))
			clone:SetAttribute("Harvestable", true)
		end
		clone.Parent = model
	end
	model.WorldPivot = CFrame.new(marker.Position)
	model:PivotTo(CFrame.new())
	table.insert(prepared, { model = model, spec = spec })
end

local function folder(parent, name)
	local f = parent:FindFirstChild(name)
	if not f then
		f = Instance.new("Folder")
		f.Name, f.Parent = name, parent
	end
	return f
end
local assets = folder(ReplicatedStorage, "Assets")
local farming = folder(assets, "Farming")
local icons, structures = folder(assets, "Icons"), folder(assets, "Structures")
local backup = Instance.new("Folder")
backup.Name = "FarmingBackup_" .. game:GetService("HttpService"):GenerateGUID(false)
backup.Parent = ServerStorage
local changes = {}
local ok, err = pcall(function()
	for _, entry in prepared do
		local spec, model = entry.spec, entry.model
		local dest = if spec.kind == "plant"
			then folder(farming, spec.crop)
			elseif spec.kind == "structure" then structures
			else icons
		local old = dest:FindFirstChild(model.Name)
		table.insert(changes, { model = model, old = old, dest = dest })
		if old then
			old.Parent = backup
		end
		model.Parent = dest
	end
end)
if not ok then
	for i = #changes, 1, -1 do
		local change = changes[i]
		change.model.Parent = nil
		if change.old then
			change.old.Parent = change.dest
		end
	end
	error("Importação desfeita: " .. tostring(err))
end
print("Fazenda instalada: 36 estágios, 9 sementes, 3 itens de água/gelo e 1 canteiro.")
print("Partes colhíveis separadas; pivôs preservados; marcadores Origin excluídos dos moldes.")
print("Backup: " .. backup:GetFullName() .. ". Os Models originais permanecem no Workspace para conferência.")
print(
	"Estes são assets. As receitas e a lógica de crescimento/rega/colheita ainda precisam ser implementadas. Salve o place."
)
