-- Transforma os ícones em relevo importados (food.fbx e mob-drops.fbx, ver
-- docs/guia/icones-itens.md) em ReplicatedStorage.Assets.Icons/<itemId>, que o
-- ItemIcon mostra no slot no lugar das iniciais.
--
-- Procura no Workspace qualquer MeshPart cujo nome seja um id da lista abaixo
-- (o importador do Studio põe os itens dentro de um Model "food"/"mob-drops").
-- Cada ícone vira um Model com o nome do id, com o pivô no centro da base, na
-- origem; peça Anchored e sem colisão/consulta/toque (só visual).
--
-- Ícones antigos de mesmo nome que este script não criou vão para
-- ServerStorage.IconesAntigos (nunca são apagados). Rodar de novo substitui só o
-- que o script criou (atributo "IconeRelevo"). Os Models importados no Workspace
-- são apagados quando ficam vazios. Rodar em Edit e salvar o place.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MARK = "IconeRelevo"

-- 16 comidas + 19 drops de mobs (manifest.json de cada pasta).
local IDS = {
	-- assets/resources/food
	"berry", "wheat", "flour", "bread", "sandwich", "cookies", "cake", "cooked_meat",
	"cooked_fish", "pumpkin", "tomato", "carrot", "watermelon", "garlic", "cactus", "aloe_vera",
	-- assets/resources/mob-drops
	"rabbit_fur", "wolf_fur", "winter_fur", "boar_fur", "kraken_skin", "thread", "crab_claws",
	"crab_sticks", "piranha_scales", "hawk_feather", "penguin_feather", "vulture_feather",
	"flame", "mammoth_fur", "raw_meat", "fish", "dragon_heart", "lava_heart", "sandworm_juice",
}
local WANTED = {}
for _, id in IDS do
	WANTED[id] = true
end

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

-- 1) Acha as peças (uma por id; repetida = erro, para não escolher às cegas).
local found: { [string]: MeshPart } = {}
local containers: { [Instance]: boolean } = {}
for _, inst in workspace:GetDescendants() do
	if inst:IsA("MeshPart") and WANTED[inst.Name] then
		assert(found[inst.Name] == nil, `dois MeshParts "{inst.Name}" no Workspace; apague um`)
		found[inst.Name] = inst
		local top = inst.Parent
		if top and top ~= workspace then
			while top.Parent and top.Parent ~= workspace do
				top = top.Parent
			end
			containers[top] = true
		end
	end
end

-- 2) Monta os Models antes de mexer no Assets (falha não deixa nada pela metade).
local made, missing = {}, {}
local jobs: { Model } = {}
for _, id in IDS do
	local part = found[id]
	if part == nil then
		table.insert(missing, id)
		continue
	end
	local model = Instance.new("Model")
	model.Name = id
	local clone = part:Clone()
	clone.Anchored = true
	clone.CanCollide, clone.CanQuery, clone.CanTouch = false, false, false
	clone.Parent = model
	-- Pivô no centro da base (o FBX vem com a face de cima para +Y).
	local cf, size = model:GetBoundingBox()
	model.WorldPivot = CFrame.new(cf.Position - Vector3.new(0, size.Y / 2, 0))
	model:PivotTo(CFrame.new())
	model:SetAttribute(MARK, true)
	table.insert(jobs, model)
	table.insert(made, id)
end

-- 3) Troca no Assets.Icons.
for _, model in jobs do
	local old = icons:FindFirstChild(model.Name)
	if old then
		if old:GetAttribute(MARK) then
			old:Destroy()
		else
			stash(old)
		end
	end
	model.Parent = icons
end

-- 4) Apaga o que foi importado (as peças já foram copiadas).
for _, id in made do
	found[id]:Destroy()
end
for container in containers do
	if container.Parent and not container:FindFirstChildWhichIsA("BasePart", true) then
		container:Destroy()
	end
end

local summary = `[import-icons] {#made} ícones em Assets.Icons`
if #missing > 0 then
	summary ..= `\n[import-icons] faltaram ({#missing}): {table.concat(missing, ", ")}`
end
print(summary)
return summary
