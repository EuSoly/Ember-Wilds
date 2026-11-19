-- Praia e mar em volta da floresta (lançamento, 19/11/2026). Rodar no Studio em
-- Edit (barra de comando ou MCP) e salvar o place. Pode rodar de novo: refaz tudo.
--
-- O que faz:
-- 1. Guarda os chãos dos biomas futuros (Winter, Desert, Lava) e o Ocean antigo
--    em ServerStorage.ImportsOriginais.BiomasFuturos (voltam quando o bioma abrir).
-- 2. Praia de BEACH_WIDTH studs em volta da floresta, pintada como as margens
--    dos lagos (Map/Ground/Coast_*, imagens do scripts/groundmap) + marcadores
--    Sand em Map/NoSpawn/Praia (a pá cava areia, nada nasce, não se planta).
-- 3. Cobre tudo em volta com chão de mar (Map/Ground/Ocean_*), até bem além da
--    barreira, para a câmera (vê ~100 studs) nunca achar o fim.
-- 4. Cria a água do mar (Map/Water/Mar, Painted = invisível, só a forma): quem
--    entra nada devagar e gasta fôlego, como num lago.
-- 5. Leva as paredes invisíveis (Map/Borders) para SEA_MARGIN studs da praia.
--
-- As medidas precisam bater com WorldConfig (BIOMES.forest, BEACH_WIDTH, SEA_MARGIN).

local ServerStorage = game:GetService("ServerStorage")
local ChangeHistoryService = game:GetService("ChangeHistoryService")

local FOREST = { minX = -1110, maxX = -150, minZ = 150, maxZ = 1110 } -- WorldConfig.BIOMES.forest
local BEACH_WIDTH = 60 -- WorldConfig.BEACH_WIDTH
local SEA_MARGIN = 150 -- WorldConfig.SEA_MARGIN: da beira da praia até a barreira
local OCEAN_REACH = 600 -- da floresta até o fim do chão de mar (bem além da barreira)
local OCEAN_COLOR = Color3.fromHex("1f6f9f") -- a cor do Ocean antigo
local SAND_COLOR = Color3.fromHex("d6b26c") -- só a cor dos marcadores no Studio
local SAND_MARK = 45 -- studs de areia da beira da água para dentro (marcadores)
local TILE = 240 -- lado de cada pedaço pintado (igual aos Forest_*)
local RES = 1024 -- pixels de cada imagem da costa
-- Pixels de cada borda que ficam de fora (sem linha na emenda). 1 bastava de
-- perto, mas de longe as versões reduzidas da imagem ainda misturavam o mar.
local PAD = 4
-- Imagens da costa (ColorMap de cada Coast_<ix>_<iz>), enviadas em 19/11/2026 (2º envio, nonce=1: o 1º travou na moderação).
local COAST_IMAGES: { [string]: string } = {
	["-1_-1"] = "rbxassetid://74791546363642",
	["0_-1"] = "rbxassetid://77193647890941",
	["1_-1"] = "rbxassetid://113306184103394",
	["2_-1"] = "rbxassetid://121396178939162",
	["3_-1"] = "rbxassetid://107678253873005",
	["4_-1"] = "rbxassetid://131744398868356",
	["-1_0"] = "rbxassetid://75464944742144",
	["4_0"] = "rbxassetid://70487425946923",
	["-1_1"] = "rbxassetid://93218625925095",
	["4_1"] = "rbxassetid://95807118698734",
	["-1_2"] = "rbxassetid://77553756041065",
	["4_2"] = "rbxassetid://136733518334607",
	["-1_3"] = "rbxassetid://98756115779841",
	["4_3"] = "rbxassetid://106540733273827",
	["-1_4"] = "rbxassetid://132818259743240",
	["0_4"] = "rbxassetid://127270044621827",
	["1_4"] = "rbxassetid://108386195759839",
	["2_4"] = "rbxassetid://110084088071988",
	["3_4"] = "rbxassetid://121571783647398",
	["4_4"] = "rbxassetid://82130588734750",
}
local WALL_HEIGHT = 60
local WALL_THICKNESS = 4

local LAND = { -- floresta + praia = WorldConfig.LAND
	minX = FOREST.minX - BEACH_WIDTH,
	maxX = FOREST.maxX + BEACH_WIDTH,
	minZ = FOREST.minZ - BEACH_WIDTH,
	maxZ = FOREST.maxZ + BEACH_WIDTH,
}

local map = workspace:WaitForChild("Map")
local ground = map:WaitForChild("Ground")
local water = map:WaitForChild("Water")
local noSpawn = map:WaitForChild("NoSpawn")
local borders = map:WaitForChild("Borders")

local recording = ChangeHistoryService:TryBeginRecording("Praia e mar em volta da floresta")

-- 1. Biomas futuros e o oceano antigo saem do mundo (backup no ServerStorage).
local imports = ServerStorage:FindFirstChild("ImportsOriginais") or Instance.new("Folder")
imports.Name = "ImportsOriginais"
imports.Parent = ServerStorage
local future = imports:FindFirstChild("BiomasFuturos") or Instance.new("Folder")
future.Name = "BiomasFuturos"
future.Parent = imports
for _, name in { "Winter", "Desert", "Lava", "Ocean" } do
	local part = ground:FindFirstChild(name)
	if part then
		part.Parent = future
	end
end
for _, child in ground:GetChildren() do
	local prefix = string.sub(child.Name, 1, 6)
	if prefix == "Ocean_" or prefix == "Beach_" then -- Beach_* = praia lisa antiga
		child:Destroy()
	end
end

local function flat(name: string, minX: number, maxX: number, minZ: number, maxZ: number, y: number, height: number): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Size = Vector3.new(maxX - minX, height, maxZ - minZ)
	part.Position = Vector3.new((minX + maxX) / 2, y, (minZ + maxZ) / 2)
	return part
end

-- As 4 faixas de um anel entre `inner` e `outer` (norte e sul pegam os cantos).
local function ring(inner, outer, make: (string, number, number, number, number) -> ())
	make("Norte", outer.minX, outer.maxX, outer.minZ, inner.minZ)
	make("Sul", outer.minX, outer.maxX, inner.maxZ, outer.maxZ)
	make("Oeste", outer.minX, inner.minX, inner.minZ, inner.maxZ)
	make("Leste", inner.maxX, outer.maxX, inner.minZ, inner.maxZ)
end

-- 2. Praia pintada, igual às margens dos lagos: um anel de 20 pedaços
-- Coast_<ix>_<iz> de 240 studs (ix, iz de -1 a 4, fora do miolo da floresta),
-- cópias do Forest_0_0 (textura de grama por cima) com a imagem da costa no
-- ColorMap. As imagens saem de `lune run forest coast serve` (scripts/groundmap).
for _, child in ground:GetChildren() do
	if string.sub(child.Name, 1, 6) == "Coast_" then
		child:Destroy()
	end
end
-- Os Forest_* da borda tinham textura de grama nas faces de lado (de quando ali
-- era o fim do mapa): encostadas na costa, elas desenhavam uma linha escura na
-- emenda (achado em 19/11). Só a de cima (Top) fica.
for _, child in ground:GetChildren() do
	if string.sub(child.Name, 1, 7) == "Forest_" then
		for _, texture in child:GetChildren() do
			if texture:IsA("Texture") and texture.Face ~= Enum.NormalId.Top then
				texture:Destroy()
			end
		end
	end
end
local template = ground:FindFirstChild("Forest_0_0") :: BasePart
for iz = -1, 4 do
	for ix = -1, 4 do
		if ix >= 0 and ix <= 3 and iz >= 0 and iz <= 3 then
			continue
		end
		local key = `{ix}_{iz}`
		local tile = template:Clone()
		tile.Name = "Coast_" .. key
		for _, child in tile:GetChildren() do
			-- Só a imagem e a grama de cima (textura de lado faz linha na emenda).
			if child.Name ~= "ColorMap" and child.Name ~= "Top" then
				child:Destroy()
			end
		end
		tile.Position = Vector3.new(FOREST.minX + (ix + 0.5) * TILE, template.Position.Y, FOREST.minZ + (iz + 0.5) * TILE)
		-- Texture no lugar do Decal: o Roblox repete a imagem e o filtro mistura
		-- a borda com o lado oposto (aqui o mar fundo), o que fazia uma linha
		-- escura na emenda com a floresta (visto em 19/11). Esticada PAD pixels
		-- além da peça, a borda nunca encosta no outro lado.
		local decal = tile:FindFirstChild("ColorMap")
		if decal then
			decal:Destroy()
		end
		local colorMap = Instance.new("Texture")
		colorMap.Name = "ColorMap"
		colorMap.Face = Enum.NormalId.Top
		colorMap.ZIndex = 1
		colorMap.Texture = COAST_IMAGES[key] or ""
		colorMap.StudsPerTileU = TILE * RES / (RES - 2 * PAD)
		colorMap.StudsPerTileV = colorMap.StudsPerTileU
		colorMap.OffsetStudsU = colorMap.StudsPerTileU * PAD / RES
		colorMap.OffsetStudsV = colorMap.OffsetStudsU
		colorMap.Parent = tile
		tile.Parent = ground
	end
end

-- Marcadores de areia: da beira da água até SAND_MARK studs terra adentro (a
-- areia pintada tem 38 a 50): a pá cava areia e não se planta. Ficam em
-- Map/Sand (não no NoSpawn): ali nascem as palmeiras e enfeites da zona
-- "beach" (MapService, 19/11).
for _, folder in { noSpawn, map:FindFirstChild("Sand") } do
	local oldBeach = folder and folder:FindFirstChild("Praia")
	if oldBeach then
		oldBeach:Destroy()
	end
end
local sandFolder = map:FindFirstChild("Sand") or Instance.new("Folder")
sandFolder.Name = "Sand"
sandFolder.Parent = map
local beachMarks = Instance.new("Folder")
beachMarks.Name = "Praia"
beachMarks:SetAttribute("Sand", true)
local sandInner = {
	minX = LAND.minX + SAND_MARK,
	maxX = LAND.maxX - SAND_MARK,
	minZ = LAND.minZ + SAND_MARK,
	maxZ = LAND.maxZ - SAND_MARK,
}
ring(sandInner, LAND, function(name, minX, maxX, minZ, maxZ)
	local part = flat(name, minX, maxX, minZ, maxZ, 0.3, 0.2)
	part.CanCollide = false
	part.Transparency = 0.6
	part.Color = SAND_COLOR
	part:SetAttribute("Sand", true)
	part.Parent = beachMarks
end)
beachMarks.Parent = sandFolder

-- Zonas "beach" (palmeiras, montinhos de areia e conchas: Defs/ResourceZones)
-- na faixa de areia, a 4 studs da água e sem os cantos (a costa pintada é
-- redonda ali e o recurso cairia na água desenhada).
local zones = map:WaitForChild("Zones")
local oldZones = zones:FindFirstChild("Praia")
if oldZones then
	oldZones:Destroy()
end
local beachZones = Instance.new("Folder")
beachZones.Name = "Praia"
local zoneInner = sandInner
local zoneOuter = { minX = LAND.minX + 4, maxX = LAND.maxX - 4, minZ = LAND.minZ + 4, maxZ = LAND.maxZ - 4 }
local function zoneStrip(name: string, minX: number, maxX: number, minZ: number, maxZ: number)
	local part = flat(name, minX, maxX, minZ, maxZ, 0.4, 0.3)
	part.CanCollide = false
	part.Transparency = 0.7
	part.Color = Color3.fromHex("e8c070")
	part:SetAttribute("ZoneType", "beach")
	part.Parent = beachZones
end
zoneStrip("Norte", zoneInner.minX, zoneInner.maxX, zoneOuter.minZ, zoneInner.minZ)
zoneStrip("Sul", zoneInner.minX, zoneInner.maxX, zoneInner.maxZ, zoneOuter.maxZ)
zoneStrip("Oeste", zoneOuter.minX, zoneInner.minX, zoneInner.minZ, zoneInner.maxZ)
zoneStrip("Leste", zoneInner.maxX, zoneOuter.maxX, zoneInner.minZ, zoneInner.maxZ)
beachZones.Parent = zones

-- 3. Chão de mar em 4 placas (o Roblox limita peça a 2048 de lado). Topo em
-- -0,2: abaixo do chão da terra (0), sem brigar com ele.
local cx, cz = (FOREST.minX + FOREST.maxX) / 2, (FOREST.minZ + FOREST.maxZ) / 2
local tile = (FOREST.maxX - FOREST.minX) / 2 + OCEAN_REACH -- 2 × 2 placas cobrem tudo
for i, offset in { Vector2.new(-1, -1), Vector2.new(1, -1), Vector2.new(-1, 1), Vector2.new(1, 1) } do
	local part = flat("Ocean_" .. i, 0, tile, 0, tile, -1.2, 2)
	part.Position = Vector3.new(cx + offset.X * tile / 2, -1.2, cz + offset.Y * tile / 2)
	part.CanCollide = true
	part.Material = Enum.Material.SmoothPlastic
	part.Color = OCEAN_COLOR
	part.Parent = ground
end

-- 4. Água do mar: anel da beira da praia até um pouco além da barreira.
local oldSea = water:FindFirstChild("Mar")
if oldSea then
	oldSea:Destroy()
end
local sea = Instance.new("Folder")
sea.Name = "Mar"
-- Painted: o MapService esconde as peças (o mar já aparece no chão Ocean_*).
sea:SetAttribute("Painted", true)
local reach = SEA_MARGIN + 40
local seaOuter = { minX = LAND.minX - reach, maxX = LAND.maxX + reach, minZ = LAND.minZ - reach, maxZ = LAND.maxZ + reach }
ring(LAND, seaOuter, function(name, minX, maxX, minZ, maxZ)
	local part = flat(name, minX, maxX, minZ, maxZ, 0.2, 0.2)
	part.CanCollide = false
	part.Transparency = 1
	part.Parent = sea
end)
sea.Parent = water

-- 5. Paredes invisíveis a SEA_MARGIN da beira da praia.
local outer = {
	minX = LAND.minX - SEA_MARGIN,
	maxX = LAND.maxX + SEA_MARGIN,
	minZ = LAND.minZ - SEA_MARGIN,
	maxZ = LAND.maxZ + SEA_MARGIN,
}
local width = outer.maxX - outer.minX + WALL_THICKNESS * 2
local depth = outer.maxZ - outer.minZ + WALL_THICKNESS * 2
local walls = {
	North = { Vector3.new(width, WALL_HEIGHT, WALL_THICKNESS), Vector3.new(cx, WALL_HEIGHT / 2, outer.minZ - WALL_THICKNESS / 2) },
	South = { Vector3.new(width, WALL_HEIGHT, WALL_THICKNESS), Vector3.new(cx, WALL_HEIGHT / 2, outer.maxZ + WALL_THICKNESS / 2) },
	West = { Vector3.new(WALL_THICKNESS, WALL_HEIGHT, depth), Vector3.new(outer.minX - WALL_THICKNESS / 2, WALL_HEIGHT / 2, cz) },
	East = { Vector3.new(WALL_THICKNESS, WALL_HEIGHT, depth), Vector3.new(outer.maxX + WALL_THICKNESS / 2, WALL_HEIGHT / 2, cz) },
}
for name, spec in walls do
	local wall = borders:FindFirstChild(name) or Instance.new("Part")
	wall.Name = name
	wall.Anchored = true
	wall.CanCollide = true
	wall.Transparency = 1
	wall.CastShadow = false
	wall.Size = spec[1]
	wall.CFrame = CFrame.new(spec[2])
	wall.Parent = borders
end

if recording then
	ChangeHistoryService:FinishRecording(recording, Enum.FinishRecordingOperation.Commit)
end
print("[mar-em-volta] pronto: salve o place")
