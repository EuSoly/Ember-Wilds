--!strict
-- Localiza, organiza e clona as malhas 3D das skins de corpo, mochila, livro e caixa
-- importadas do Blender (export_roblox.py + SkinManifest).
--
-- Suporta tanto os modelos já organizados em ReplicatedStorage.Assets.{Skins,Bags,Books}
-- quanto os FBX recém-importados no Workspace (skins-corpo, skins-mochilas, skins-livros):
-- no boot do servidor no Studio, `organizeStudioImports` move tudo para ReplicatedStorage.Assets
-- e ajusta Neon, transparência e pivô a partir do SkinManifest.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local SkinManifest = require("../Defs/SkinManifest")

local SkinAssets = {}

local FOLDER_BY_PREFIX: { [string]: string } = {
	body = "Skins",
	bag = "Bags",
	book = "Books",
	crate = "Crates",
}

local function prefixOf(skinId: string): string?
	local prefix = string.match(skinId, "^([a-z]+)_")
	return if prefix and FOLDER_BY_PREFIX[prefix] then prefix else nil
end

-- Para corpo e mochila, a rotação de 180° no eixo Y alinha a frente (+Y do Blender) com -Z do Roblox.
-- Para livros, a malha importada (+Y capa, +Z topo) já fica com a capa de frente e o topo para cima
-- ao receber a inclinação de leitura do BookModel (TILT no eixo X), mantendo CFrame.identity.
local CORRECTION_BY_PREFIX: { [string]: CFrame } = {
	body = CFrame.Angles(0, math.pi, 0),
	bag = CFrame.Angles(0, math.pi, 0),
	book = CFrame.identity,
	crate = CFrame.Angles(0, math.pi, 0),
}

-- Caixas: o CrateModel clona Assets.Crates/<id> inteiro (sem passar pelo
-- clonePart), então a correção de frente já fica gravada na peça. A marca
-- evita girar de novo quando o organizador roda outra vez.
local BAKED_ATTRIBUTE = "SkinCorrectionBaked"

local partCache: { [string]: BasePart? } = {}

local function correctionFor(skinId: string): CFrame
	local prefix = prefixOf(skinId)
	return if prefix and CORRECTION_BY_PREFIX[prefix] then CORRECTION_BY_PREFIX[prefix] else CFrame.identity
end

-- Normaliza o nome de uma MeshPart importada no Studio (remove prefixo "Meshes/"
-- do Asset Manager ou sufixo ".001" do Blender se houver).
local function cleanMeshName(rawName: string): string?
	local stripped = string.gsub(rawName, "^.*[/\\]", "")
	stripped = string.gsub(stripped, "%.[0-9]+$", "")
	if SkinManifest.PARTS[stripped] ~= nil then
		return stripped
	end
	return nil
end

local function ensureFolder(parent: Instance, name: string): Folder
	local found = parent:FindFirstChild(name)
	if found and found:IsA("Folder") then
		return found
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function applyMaterialAndTexture(part: BasePart, info: SkinManifest.PartInfo)
	local sa = part:FindFirstChildOfClass("SurfaceAppearance")
	if sa and part:IsA("MeshPart") and part.TextureID == "" then
		pcall(function()
			if sa.ColorMap ~= "" then
				part.TextureID = sa.ColorMap
			end
		end)
	end
	if info.tipo == "neon" then
		part.Material = Enum.Material.Neon
		part.Transparency = 0
		if sa and part:IsA("MeshPart") and part.TextureID ~= "" then
			sa:Destroy()
		end
	elseif info.tipo == "translucido" then
		part.Material = Enum.Material.SmoothPlastic
		part.Transparency = math.clamp(1 - info.alpha, 0, 0.95)
		if sa and part:IsA("MeshPart") and part.TextureID ~= "" then
			sa:Destroy()
		end
	else
		part.Material = Enum.Material.SmoothPlastic
		part.Transparency = 0
	end
end

local function styleTemplatePart(part: BasePart, info: SkinManifest.PartInfo)
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	applyMaterialAndTexture(part, info)
	local c = info.center
	local rotation = part.CFrame.Rotation
	if prefixOf(info.skinId) == "crate" and part:GetAttribute(BAKED_ATTRIBUTE) ~= true then
		-- Mesma conta do clonePart (pivô * centro * correção * rotação importada).
		rotation = correctionFor(info.skinId) * rotation
		part:SetAttribute(BAKED_ATTRIBUTE, true)
	end
	part.CFrame = CFrame.new(c[1], c[2], c[3]) * rotation
end

-- Procura em Workspace, ReplicatedStorage e ServerStorage quaisquer MeshParts
-- dos FBX de skins (skins-corpo, skins-mochilas, skins-livros ou individuais)
-- e as organiza em ReplicatedStorage.Assets.{Skins,Bags,Books}/<skinId>/<partName>.
function SkinAssets.organizeStudioImports(): number
	local assets = ensureFolder(ReplicatedStorage, "Assets")
	local folders: { [string]: Folder } = {
		body = ensureFolder(assets, "Skins"),
		bag = ensureFolder(assets, "Bags"),
		book = ensureFolder(assets, "Books"),
		crate = ensureFolder(assets, "Crates"),
	}

	local foundParts: { { part: BasePart, name: string, info: SkinManifest.PartInfo } } = {}
	local containersToClean: { [Instance]: boolean } = {}

	local roots: { Instance } = { Workspace, assets }
	pcall(function()
		table.insert(roots, ServerStorage)
	end)

	for _, root in roots do
		for _, inst in root:GetDescendants() do
			if inst:IsA("MeshPart") then
				local clean = cleanMeshName(inst.Name)
				if clean then
					local info = SkinManifest.PARTS[clean]
					table.insert(foundParts, { part = inst :: BasePart, name = clean, info = info })
					-- Se veio de um Model importado no Workspace (ex. Workspace["skins-corpo"]),
					-- marca o container raiz no Workspace para limpeza depois de mover as peças.
					local top: Instance? = inst.Parent
					while top and top.Parent and top.Parent ~= Workspace and top.Parent ~= root do
						top = top.Parent
					end
					if top and top.Parent == Workspace and top:IsA("Model") then
						containersToClean[top] = true
					end
				end
			end
		end
	end

	local count = 0
	for _, item in foundParts do
		local info = item.info
		local prefix = prefixOf(info.skinId)
		local categoryFolder = if prefix then folders[prefix] else nil
		if categoryFolder == nil then
			continue
		end
		local skinModel = categoryFolder:FindFirstChild(info.skinId)
		if skinModel == nil or not skinModel:IsA("Model") then
			if skinModel then
				skinModel:Destroy()
			end
			local created = Instance.new("Model")
			created.Name = info.skinId
			created.WorldPivot = CFrame.identity
			created.Parent = categoryFolder
			skinModel = created
		end

		local existing = (skinModel :: Instance):FindFirstChild(item.name)
		if existing and existing ~= item.part then
			existing:Destroy()
		end

		item.part.Name = item.name
		styleTemplatePart(item.part, info)
		item.part.Parent = skinModel :: Instance
		partCache[item.name] = item.part
		count += 1
	end

	for container in containersToClean do
		local hasRemainingMesh = false
		for _, desc in container:GetDescendants() do
			if desc:IsA("BasePart") then
				hasRemainingMesh = true
				break
			end
		end
		if not hasRemainingMesh then
			container:Destroy()
		end
	end

	return count
end

local function indexAvailableParts()
	for _, root in { ReplicatedStorage, Workspace } do
		for _, inst in root:GetDescendants() do
			if inst:IsA("MeshPart") then
				local clean = cleanMeshName(inst.Name)
				if clean and partCache[clean] == nil then
					partCache[clean] = inst
				end
			end
		end
	end
end

local function resolveSkinId(skinId: string): string
	if skinId == "book_default" then
		return "book_pergaminho"
	end
	return skinId
end

function SkinAssets.findPart(skinId: string, partName: string): BasePart?
	skinId = resolveSkinId(skinId)
	local cached = partCache[partName]
	if cached and cached.Parent ~= nil then
		return cached
	end

	local prefix = prefixOf(skinId)
	local folderName = if prefix then FOLDER_BY_PREFIX[prefix] else nil
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = if assets and folderName then assets:FindFirstChild(folderName) else nil
	if folder then
		local skinModel = folder:FindFirstChild(skinId)
		local inside = if skinModel then skinModel:FindFirstChild(partName) else folder:FindFirstChild(partName)
		if inside and inside:IsA("BasePart") then
			partCache[partName] = inside
			return inside
		end
	end

	indexAvailableParts()
	local afterIndex = partCache[partName]
	if afterIndex and afterIndex.Parent ~= nil then
		return afterIndex
	end
	return nil
end

function SkinAssets.hasSkin(skinId: string?): boolean
	if skinId == nil then
		return false
	end
	skinId = resolveSkinId(skinId)
	local partNames = SkinManifest.PARTS_BY_SKIN[skinId]
	if partNames == nil then
		return false
	end
	for _, partName in partNames do
		if SkinAssets.findPart(skinId, partName) ~= nil then
			return true
		end
	end
	return false
end

function SkinAssets.clonePart(skinId: string, partName: string, pivotCFrame: CFrame): BasePart?
	skinId = resolveSkinId(skinId)
	local info = SkinManifest.PARTS[partName]
	if info == nil then
		return nil
	end
	local source = SkinAssets.findPart(skinId, partName)
	if source == nil then
		return nil
	end
	local clone = source:Clone()
	for _, child in clone:GetChildren() do
		if not child:IsA("SurfaceAppearance") then
			child:Destroy()
		end
	end
	clone.Name = partName
	clone.Anchored = false
	clone.CanCollide = false
	clone.CanQuery = false
	clone.CanTouch = false
	clone.Massless = true
	clone.CastShadow = false
	applyMaterialAndTexture(clone, info)
	local c = info.center
	local correction = correctionFor(skinId)
	clone.CFrame = pivotCFrame * CFrame.new(c[1], c[2], c[3]) * correction * source.CFrame.Rotation
	return clone
end

return SkinAssets
