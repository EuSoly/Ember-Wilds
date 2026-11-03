-- Transforma os modelos do world-pack do Elizeu (Workspace["mundo-completo"],
-- um Model com filhos Model "<id>_root") em templates que o jogo lê:
--
--   *_deposit_icon -> ServerStorage.Assets.Resources (recursos: rock_1, gold_vein_1,
--                     e os de diamante/ametista/reidite/esmeralda com o nome original,
--                     para o futuro)
--   *_viewport     -> ReplicatedStorage.Assets.Icons/<itemId> (ícone do item)
--   o resto        -> ReplicatedStorage.Assets.Structures/<itemId> (construções e estruturas)
--
-- Cada template: nome sem "_root", pivô no CENTRO DA BASE (centro X/Z da caixa e
-- Y mínimo, calculados da geometria, porque todos os "_root" importados têm o mesmo
-- pivô), na origem do mundo; peças Anchored e sem colisão/consulta/toque (o modelo é
-- só visual). PrimaryPart fica nil. As peças móveis (_panel_left, _lid, _rotor,
-- _flames, _core...) continuam peças separadas, com o nome original.
--
-- Modelos antigos de mesmo nome que este script não criou nunca são apagados: vão
-- para ServerStorage.ResourcesAntigos / EstruturasAntigas / IconesAntigos (e rock_2/rock_3
-- também). Rodar de novo substitui só o que o script criou (atributo "MundoCompleto");
-- um backup nunca é sobrescrito (nome repetido ganha sufixo _2, _3...).
-- Não apaga Workspace["mundo-completo"]. Rodar em Edit e salvar o place.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local SOURCE_NAME = "mundo-completo"
local MARK = "MundoCompleto"

-- Ids do world-pack que têm outro id no jogo.
local STRUCTURE_RENAMES = { big_fire = "big_campfire" }
local RESOURCE_RENAMES = { stone_deposit_icon = "rock_1", gold_deposit_icon = "gold_vein_1" }
-- Recursos antigos que saem de Assets.Resources (rock_1 e gold_vein_1 são trocados acima).
local OLD_RESOURCES = { "rock_1", "rock_2", "rock_3", "gold_vein_1" }

local SOURCE = workspace:FindFirstChild(SOURCE_NAME)
assert(SOURCE, `falta Workspace["{SOURCE_NAME}"]`)

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
local structures = folder(assets, "Structures")
local icons = folder(assets, "Icons")
local serverAssets = ServerStorage:FindFirstChild("Assets")
assert(serverAssets, "falta ServerStorage.Assets")
local resources = serverAssets:FindFirstChild("Resources")
assert(resources, "falta ServerStorage.Assets.Resources")

-- Backups (nunca sobrescritos: se o nome já existe, entra um sufixo numérico).
local BACKUP_OF = { [structures] = "EstruturasAntigas", [icons] = "IconesAntigos", [resources] = "ResourcesAntigos" }

local function stash(old: Instance, backupName: string)
	local backup = folder(ServerStorage, backupName)
	local name = old.Name
	local n = 1
	while backup:FindFirstChild(name) do
		n += 1
		name = `{old.Name}_{n}`
	end
	old.Name = name
	old.Parent = backup
end

-- Caixa do mundo, calculada dos cantos de cada peça (não depende do pivô do Model).
local function bounds(model: Model): (Vector3, Vector3)
	local lo = Vector3.one * math.huge
	local hi = Vector3.one * -math.huge
	for _, part in model:GetDescendants() do
		if not part:IsA("BasePart") then
			continue
		end
		local half = part.Size / 2
		for _, sx in { -1, 1 } do
			for _, sy in { -1, 1 } do
				for _, sz in { -1, 1 } do
					local corner = part.CFrame * Vector3.new(half.X * sx, half.Y * sy, half.Z * sz)
					lo = lo:Min(corner)
					hi = hi:Max(corner)
				end
			end
		end
	end
	return lo, hi
end

local function build(root: Model, name: string): Model
	local template = root:Clone()
	template.Name = name
	local lo, hi = bounds(template)
	assert(lo.X < math.huge, `{root.Name} não tem peças`)
	template.PrimaryPart = nil
	template.WorldPivot = CFrame.new((lo.X + hi.X) / 2, lo.Y, (lo.Z + hi.Z) / 2)
	template:PivotTo(CFrame.new())
	for _, part in template:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
			part.CanCollide, part.CanQuery, part.CanTouch = false, false, false
		end
	end
	template:SetAttribute(MARK, true)
	return template
end

-- Põe o template em `parent`. Um modelo anterior com o mesmo nome é apagado só se foi
-- criado por este script (tem a marca); se não, vai para o backup.
local function place(template: Model, parent: Instance)
	local old = parent:FindFirstChild(template.Name)
	if old then
		if old:GetAttribute(MARK) then
			old:Destroy()
		else
			stash(old, BACKUP_OF[parent])
		end
	end
	template.Parent = parent
end

-- 1) Constrói tudo antes de mexer em qualquer pasta (uma falha não deixa nada pela metade).
local jobs = {}
local taken = {}
local made = { structures = {}, resources = {}, icons = {} }
for _, root in SOURCE:GetChildren() do
	if not root:IsA("Model") or not string.match(root.Name, "_root$") then
		continue
	end
	local id = string.gsub(root.Name, "_root$", "")
	local kind, parent, name
	if string.match(id, "_deposit_icon$") then
		kind, parent, name = "resources", resources, RESOURCE_RENAMES[id] or id
	elseif string.match(id, "_viewport$") then
		kind, parent, name = "icons", icons, (string.gsub(id, "_viewport$", ""))
	else
		kind, parent, name = "structures", structures, STRUCTURE_RENAMES[id] or id
	end
	local key = `{kind}/{name}`
	assert(not taken[key], `dois modelos viram {key}: {taken[key]} e {root.Name}`)
	taken[key] = root.Name
	table.insert(jobs, { template = build(root, name), parent = parent })
	table.insert(made[kind], if name == id then id else `{id} -> {name}`)
end

-- 2) Recursos antigos que não serão substituídos por nome (rock_2, rock_3) saem de Resources.
for _, name in OLD_RESOURCES do
	local old = resources:FindFirstChild(name)
	if old and not old:GetAttribute(MARK) then
		stash(old, BACKUP_OF[resources])
	end
end

-- 3) Põe os novos.
for _, job in jobs do
	place(job.template, job.parent)
end

local lines = {}
for _, kind in { "structures", "resources", "icons" } do
	table.sort(made[kind])
	table.insert(lines, `[import-world] {kind} ({#made[kind]}): {table.concat(made[kind], ", ")}`)
end
local summary = table.concat(lines, "\n")
print(summary)
return summary
