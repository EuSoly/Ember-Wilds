--!strict
-- Pré-carregamento das artes (só no cliente). As malhas e imagens só baixam na
-- primeira vez que aparecem na tela, e era isso que fazia as skins e o livro
-- demorarem a aparecer (10/11/2026). Aqui elas são baixadas antes, com
-- ContentProvider:PreloadAsync, em lotes e nesta ordem:
--   ui        imagens da interface (Shared/*Images)
--   tools     ferramentas e ícones (livro, hotbar)
--   world     estruturas e bichos
--   bags, books, crates, skins   cosméticos
-- A tela de carregamento (ReplicatedFirst/Loading) liga isto e espera só os
-- grupos que bloqueiam (BLOCKING: interface, ferramentas e ícones; decisão do
-- Elizeu, 10/11/2026, para não perder jogador no carregamento), com a contagem
-- deles na barra; o resto continua em segundo plano (o menu mostra a contagem
-- e os quadradinhos das skins piscam até a arte chegar). Quem abre uma tela pode pedir prioridade para um grupo (prioritize),
-- que passa na frente da fila. O mesmo módulo é usado pela tela de carregamento
-- e pelo resto do cliente (mesmo require), então o estado é um só.
--
-- Malhas vão pela peça (MeshPart/SpecialMesh), uma por MeshId: PreloadAsync
-- trata id solto como imagem, e id de malha falha com "Asset type does not
-- match requested type" (visto no Studio em 10/11/2026). Imagens e texturas
-- vão por id.
local ContentProvider = game:GetService("ContentProvider")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local AssetIds = require(script.Parent:WaitForChild("AssetIds"))

local BATCH = 50 -- itens por PreloadAsync (a contagem anda a cada lote)
local IMAGE_MODULES = { "HudImages", "UiImages", "ShopImages", "BookImages", "RarityImages", "RankingImages" }
-- grupo -> pastas de ReplicatedStorage.Assets
local FOLDERS: { { name: string, folders: { string } } } = {
	{ name = "tools", folders = { "Tools", "Icons" } },
	{ name = "world", folders = { "Structures", "Mobs" } },
	{ name = "bags", folders = { "Bags" } },
	{ name = "books", folders = { "Books" } },
	{ name = "crates", folders = { "Crates" } },
	{ name = "skins", folders = { "Skins" } },
}

-- Grupos que a tela de carregamento espera (o resto vai em segundo plano).
local BLOCKING: { [string]: true } = { ui = true, tools = true }

-- Um grupo: peças com malha e ids de imagem ainda na fila, quantos tinha e
-- quantos já baixaram.
type Entry = { name: string, items: { any }, count: number, done: number }

local AssetPreloader = {}

local queue: { Entry } = {}
local all: { Entry } = {} -- todos os grupos (a fila vai esvaziando)
local loaded = 0
local total = 0
local started = false
local finished = false

-- Peças com malha (uma por MeshId) e ids de imagem de uma pasta.
local function collect(root: Instance, parts: { Instance }, images: { string }, seenMesh: { [string]: true })
	local function addImage(id: string?)
		if id and id ~= "" and AssetIds.isAsset(id) then
			table.insert(images, id)
		end
	end
	for _, d in root:GetDescendants() do
		if d:IsA("MeshPart") then
			if d.MeshId ~= "" and not seenMesh[d.MeshId] then
				seenMesh[d.MeshId] = true
				table.insert(parts, d)
			end
			addImage(d.TextureID)
		elseif d:IsA("SpecialMesh") then
			if d.MeshId ~= "" and not seenMesh[d.MeshId] then
				seenMesh[d.MeshId] = true
				table.insert(parts, d)
			end
			addImage(d.TextureId)
		elseif d:IsA("SurfaceAppearance") then
			addImage(d.ColorMap)
			addImage(d.NormalMap)
			addImage(d.MetalnessMap)
			addImage(d.RoughnessMap)
		elseif d:IsA("Decal") or d:IsA("ParticleEmitter") then
			addImage((d :: any).Texture)
		elseif d:IsA("ImageLabel") or d:IsA("ImageButton") then
			addImage(d.Image)
		end
	end
end

-- Os grupos na ordem de prioridade, sem repetir malhas nem imagens.
local function build(): { Entry }
	local shared = ReplicatedStorage:WaitForChild("Shared")
	local ui: { string } = {}
	for _, name in IMAGE_MODULES do
		local module = shared:FindFirstChild(name)
		if module and module:IsA("ModuleScript") then
			local ok, value = pcall(require, module)
			if ok and type(value) == "table" then
				for _, id in AssetIds.fromTable(value) do
					table.insert(ui, id)
				end
			end
		end
	end
	local imageGroups: { AssetIds.Group } = { { name = "ui", ids = ui } }
	local partGroups: { { Instance } } = { {} }
	local seenMesh: { [string]: true } = {}
	local assets = ReplicatedStorage:WaitForChild("Assets", 10)
	for _, entry in FOLDERS do
		local parts: { Instance } = {}
		local images: { string } = {}
		if assets then
			for _, folderName in entry.folders do
				local folder = assets:FindFirstChild(folderName)
				if folder then
					collect(folder, parts, images, seenMesh)
				end
			end
		end
		table.insert(imageGroups, { name = entry.name, ids = images })
		table.insert(partGroups, parts)
	end
	local out: { Entry } = {}
	for index, group in AssetIds.merge(imageGroups) do
		local items: { any } = table.clone(partGroups[index])
		for _, id in group.ids do
			table.insert(items, id)
		end
		table.insert(out, { name = group.name, items = items, count = #items, done = 0 })
	end
	return out
end

local function nextBatch(): ({ any }?, Entry?)
	while queue[1] and #queue[1].items == 0 do
		table.remove(queue, 1)
	end
	local group = queue[1]
	if group == nil then
		return nil, nil
	end
	local batch: { any } = {}
	while #batch < BATCH and #group.items > 0 do
		table.insert(batch, table.remove(group.items))
	end
	return batch, group
end

-- Começa a baixar tudo (uma vez só); roda numa thread própria.
function AssetPreloader.start()
	if started then
		return
	end
	started = true
	task.spawn(function()
		-- A lista só depois de o jogo carregar: antes, a pasta Assets ainda está
		-- chegando e a lista sai incompleta (o total mudava a cada vez no Studio).
		if not game:IsLoaded() then
			game.Loaded:Wait()
		end
		queue = build()
		all = table.clone(queue)
		for _, group in queue do
			total += #group.items
		end
		while true do
			local batch, group = nextBatch()
			if batch == nil or group == nil then
				break
			end
			-- O lote conta quando termina, deu certo ou não (um id quebrado não
			-- pode travar a contagem). Por lote, e não pelo callback: o callback
			-- vem por conteúdo, e uma peça com malha e textura chamaria duas vezes.
			pcall(function()
				ContentProvider:PreloadAsync(batch)
			end)
			loaded = math.min(loaded + #batch, total)
			group.done += #batch
		end
		loaded = total
		finished = true
	end)
end

-- Passa o grupo `name` para a frente da fila (ex. ao abrir os Cosméticos).
function AssetPreloader.prioritize(name: string)
	for index, group in queue do
		if group.name == name then
			if index > 1 then
				table.remove(queue, index)
				table.insert(queue, 1, group)
			end
			return
		end
	end
end

function AssetPreloader.loaded(): number
	return loaded
end

function AssetPreloader.total(): number
	return total
end

-- true enquanto há lista montada e ainda falta baixar (a contagem tem sentido).
function AssetPreloader.counting(): boolean
	return total > 0 and not finished
end

function AssetPreloader.finished(): boolean
	return finished
end

local function blockingSums(): (number, number)
	local done, count = 0, 0
	for _, group in all do
		if BLOCKING[group.name] then
			done += group.done
			count += group.count
		end
	end
	return done, count
end

-- Quantas artes dos grupos que bloqueiam já baixaram, e de quantas.
function AssetPreloader.blockingLoaded(): number
	return (blockingSums())
end

function AssetPreloader.blockingTotal(): number
	local _, count = blockingSums()
	return count
end

-- true enquanto a lista dos que bloqueiam está montada e ainda falta baixar.
function AssetPreloader.blockingCounting(): boolean
	local done, count = blockingSums()
	return count > 0 and done < count
end

-- true quando os grupos que bloqueiam já baixaram (a tela de carregamento pode sair).
function AssetPreloader.blockingFinished(): boolean
	if finished then
		return true
	end
	local done, count = blockingSums()
	return #all > 0 and done >= count
end

return AssetPreloader
