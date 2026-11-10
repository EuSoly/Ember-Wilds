--!strict
-- Pinta o chão da floresta (Map/Ground/Forest) numa imagem só: grama com tons
-- que mudam devagar, grama escura perto da água, areia em volta da água e a
-- mata fechada mais escura. Uma imagem pintada não tem as bordas duras nem o
-- "pisca" das peças sobrepostas (visto no Studio em 10/11/2026).
--
-- Uso (Lune, na pasta scripts/groundmap):
--   lune run forest            -> grava forest.png (chão e água), 1024x1024
--   lune run forest serve      -> grava e serve em http://localhost:34999/forest.png
--     (o upload_image do Studio MCP só sobe imagem por URL)
-- A água vem de water.txt, exportado do Studio (Map/Water):
--   d x z raio            (disco)
--   b x z largura comprimento angulo   (bloco; angulo = atan2(look.X, look.Z) em graus)
-- Se a água mudar no mapa, exporte de novo, rode e troque a imagem do Decal.
local fs = require("@lune/fs")
local net = require("@lune/net")
local process = require("@lune/process")
local serde = require("@lune/serde")

-- Área da peça Forest: centro (-630, 630), 960 x 960.
local X0, Z0, SIZE = -1110, 150, 960
local RES = 1024 -- pixels da imagem
local CELL = 3 -- studs por célula da grade grossa (campos suaves)
local N = SIZE // CELL + 2
local MAXD = 80 -- studs: mais longe que isso da água conta como "longe"

local DENSE = { x0 = -1100, x1 = -780, z0 = 160, z1 = 500 } -- zona DenseNorthWest
local BAY = { x = -240, z = 778 } -- baía: praia mais larga
local QUARRY = { x0 = -450, x1 = -160, z0 = 700, z1 = 1100 } -- zona Quarry

type RGB = { number }
local function hex(s: string): RGB
	return {
		tonumber(s:sub(1, 2), 16) :: number,
		tonumber(s:sub(3, 4), 16) :: number,
		tonumber(s:sub(5, 6), 16) :: number,
	}
end
-- Cores (também as da água) um pouco mais vivas que o alvo: a textura de grama por cima (meio
-- transparente) e a luz do jogo puxam para o cinza.
local GRASS_LIGHT = hex("8fd957")
local GRASS_MID = hex("74c845")
local GRASS_DEEP = hex("5db53a")
local GRASS_DARK = hex("3f9a2f") -- perto da água
local GRASS_DENSE = hex("3f922e") -- mata fechada
local SAND = hex("e8bb62")
local SAND_WET = hex("cf9a45")
-- Manchas de grama: umas mais amareladas, outras mais fundas.
local PATCH_YELLOW = hex("b2d85a")
local PATCH_DEEP = hex("4fae3e")
-- Pedreira: terra e cascalho, com grama seca na transição.
local DRY_GRASS = hex("a9b552")
local DIRT = hex("a88a62")
local GRAVEL = hex("a69f91")
local DIRT_DARK = hex("87704f")

-- Ruído de valor suave (determinístico).
local function hash(ix: number, iz: number, seed: number): number
	local n = math.sin(ix * 127.1 + iz * 311.7 + seed * 74.7) * 43758.5453
	return n - math.floor(n)
end
local function smooth(t: number): number
	return t * t * (3 - 2 * t)
end
local function noise(x: number, z: number, seed: number): number
	local ix, iz = math.floor(x), math.floor(z)
	local fx, fz = smooth(x - ix), smooth(z - iz)
	local a = hash(ix, iz, seed)
	local b = hash(ix + 1, iz, seed)
	local c = hash(ix, iz + 1, seed)
	local d = hash(ix + 1, iz + 1, seed)
	return (a + (b - a) * fx) + ((c + (d - c) * fx) - (a + (b - a) * fx)) * fz
end
-- Cada oitava vem girada, para o ruído não mostrar a grade quadrada.
local function fbm(x: number, z: number, seed: number): number
	local x2, z2 = (x * 0.8 - z * 0.6) * 2.1, (x * 0.6 + z * 0.8) * 2.1
	local x3, z3 = (x * 0.28 + z * 0.96) * 4.3, (-x * 0.96 + z * 0.28) * 4.3
	return noise(x, z, seed) * 0.55 + noise(x2, z2, seed + 1) * 0.3 + noise(x3, z3, seed + 2) * 0.15
end
local function smoothstep(e0: number, e1: number, x: number): number
	local t = math.clamp((x - e0) / (e1 - e0), 0, 1)
	return t * t * (3 - 2 * t)
end
local function mix(a: RGB, b: RGB, t: number): RGB
	return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t }
end

-- Distância (com sinal) até a água, na grade grossa.
local dist = table.create(N * N, MAXD)
local function idx(i: number, j: number): number
	return j * N + i + 1
end
local function visit(cx: number, cz: number, reach: number, sdf: (number, number) -> number)
	local i0 = math.max(0, math.floor((cx - reach - X0) / CELL))
	local i1 = math.min(N - 1, math.ceil((cx + reach - X0) / CELL))
	local j0 = math.max(0, math.floor((cz - reach - Z0) / CELL))
	local j1 = math.min(N - 1, math.ceil((cz + reach - Z0) / CELL))
	for j = j0, j1 do
		local z = Z0 + j * CELL
		for i = i0, i1 do
			local k = idx(i, j)
			local d = sdf(X0 + i * CELL, z)
			if d < dist[k] then
				dist[k] = d
			end
		end
	end
end
for line in (fs.readFile("water.txt")):gmatch("[^\r\n]+") do
	local parts = line:split(" ")
	local kind = parts[1]
	local x, z = tonumber(parts[2]) :: number, tonumber(parts[3]) :: number
	if kind == "d" then
		local r = tonumber(parts[4]) :: number
		visit(x, z, r + MAXD, function(px, pz)
			return math.sqrt((px - x) ^ 2 + (pz - z) ^ 2) - r
		end)
	elseif kind == "b" then
		local hw, hl = (tonumber(parts[4]) :: number) / 2, (tonumber(parts[5]) :: number) / 2
		local a = math.rad(tonumber(parts[6]) :: number)
		local lx, lz = math.sin(a), math.cos(a) -- look
		local rx, rz = lz, -lx -- right
		visit(x, z, math.max(hw, hl) * 1.5 + MAXD, function(px, pz)
			local dx, dz = px - x, pz - z
			local qx = math.abs(dx * rx + dz * rz) - hw
			local qz = math.abs(dx * lx + dz * lz) - hl
			local ox, oz = math.max(qx, 0), math.max(qz, 0)
			return math.sqrt(ox * ox + oz * oz) + math.min(math.max(qx, qz), 0)
		end)
	end
end

-- Dentro da água, o menor dos SDFs mede a distância até a borda de cada pedaço,
-- não até a margem (o rio sai em "contas"). Perto da margem ele vale; mais para
-- dentro, a distância é propagada célula a célula (chanfro 2 passadas).
do
	local INF = math.huge
	local diag = CELL * math.sqrt(2)
	local inner = table.create(N * N, 0)
	for k = 1, N * N do
		local d = dist[k]
		inner[k] = if d >= 0 then 0 elseif d > -CELL * 1.5 then -d else INF
	end
	local function relax(i: number, j: number, di: number, dj: number, w: number)
		local ni, nj = i + di, j + dj
		if ni >= 0 and ni < N and nj >= 0 and nj < N then
			local k = idx(i, j)
			local v = inner[idx(ni, nj)] + w
			if v < inner[k] then
				inner[k] = v
			end
		end
	end
	for j = 0, N - 1 do
		for i = 0, N - 1 do
			relax(i, j, -1, 0, CELL)
			relax(i, j, 0, -1, CELL)
			relax(i, j, -1, -1, diag)
			relax(i, j, 1, -1, diag)
		end
	end
	for j = N - 1, 0, -1 do
		for i = N - 1, 0, -1 do
			relax(i, j, 1, 0, CELL)
			relax(i, j, 0, 1, CELL)
			relax(i, j, 1, 1, diag)
			relax(i, j, -1, 1, diag)
		end
	end
	for k = 1, N * N do
		if dist[k] < 0 then
			dist[k] = -inner[k]
		end
	end
end

-- Campos suaves na grade grossa: tom da grama, largura da areia e da grama escura,
-- mata fechada. Na imagem, tudo é interpolado e só a cor é decidida por pixel.
local tone = table.create(N * N, 0)
local mottle = table.create(N * N, 0)
local sandW = table.create(N * N, 0)
local darkW = table.create(N * N, 0)
local dense = table.create(N * N, 0)
local patchA = table.create(N * N, 0)
local patchB = table.create(N * N, 0)
local quarry = table.create(N * N, 0)
local stones = table.create(N * N, 0)
-- Retângulo com borda torta e macia: 0 fora, 1 dentro (warp = studs de entorto).
local function softRect(x: number, z: number, r: typeof(DENSE), warp: number, seed: number, e0: number, e1: number)
	local wx = x + (fbm(x / 90, z / 90, seed) - 0.5) * warp
	local wz = z + (fbm(x / 90, z / 90, seed + 1) - 0.5) * warp
	return smoothstep(e0, e1, math.min(wx - r.x0, r.x1 - wx, wz - r.z0, r.z1 - wz))
end
for j = 0, N - 1 do
	local z = Z0 + j * CELL
	for i = 0, N - 1 do
		local x = X0 + i * CELL
		local k = idx(i, j)
		tone[k] = fbm(x / 140, z / 140, 1)
		mottle[k] = fbm(x / 22, z / 22, 9)
		local bay = 1 - smoothstep(95, 170, math.sqrt((x - BAY.x) ^ 2 + (z - BAY.z) ^ 2))
		sandW[k] = 3 + 7 * fbm(x / 30, z / 30, 3) + 10 * bay
		darkW[k] = 18 + 28 * fbm(x / 60, z / 60, 5)
		dense[k] = softRect(x, z, DENSE, 160, 7, -40, 60)
		patchA[k] = smoothstep(0.53, 0.68, fbm(x / 55, z / 55, 11))
		patchB[k] = smoothstep(0.55, 0.7, fbm(x / 50, z / 50, 17))
		quarry[k] = softRect(x, z, QUARRY, 220, 21, -60, 60)
		stones[k] = fbm(x / 14, z / 14, 25)
	end
end

local function sample(field: { number }, gx: number, gz: number): number
	local i, j = math.floor(gx), math.floor(gz)
	local fx, fz = gx - i, gz - j
	i, j = math.clamp(i, 0, N - 2), math.clamp(j, 0, N - 2)
	local a, b = field[idx(i, j)], field[idx(i + 1, j)]
	local c, d = field[idx(i, j + 1)], field[idx(i + 1, j + 1)]
	local top = a + (b - a) * fx
	return top + ((c + (d - c) * fx) - top) * fz
end

local function colorAt(x: number, z: number): RGB
	local gx, gz = (x - X0) / CELL, (z - Z0) / CELL
	local t = sample(tone, gx, gz)
	local base = if t < 0.5
		then mix(GRASS_LIGHT, GRASS_MID, smoothstep(0.25, 0.5, t))
		else mix(GRASS_MID, GRASS_DEEP, smoothstep(0.5, 0.72, t))
	base = mix(base, PATCH_YELLOW, sample(patchA, gx, gz) * 0.75)
	base = mix(base, PATCH_DEEP, sample(patchB, gx, gz) * 0.7)
	base = mix(base, GRASS_DENSE, sample(dense, gx, gz) * 0.85)
	local m = (sample(mottle, gx, gz) - 0.5) * 0.12
	base = { base[1] * (1 + m), base[2] * (1 + m), base[3] * (1 + m) }

	-- Pedreira: grama seca na borda, depois terra com cascalho.
	local q = sample(quarry, gx, gz)
	local s = sample(stones, gx, gz)
	local ground = mix(DIRT, GRAVEL, smoothstep(0.4, 0.65, s) * 0.8)
	ground = mix(ground, DIRT_DARK, smoothstep(0.6, 0.8, s) * 0.45)
	base = mix(base, DRY_GRASS, (1 - math.abs(2 * q - 1)) * 0.7)
	base = mix(base, ground, smoothstep(0.45, 0.9, q))

	local d = sample(dist, gx, gz)
	local sw = sample(sandW, gx, gz)
	local near = 1 - smoothstep(sw, sw + sample(darkW, gx, gz), d)
	-- Perto da água: grama escura; na pedreira, terra molhada.
	local col = mix(base, mix(GRASS_DARK, DIRT_DARK, q), near * 0.9)
	local sand = mix(mix(SAND_WET, SAND, smoothstep(0, 2.5, d)), GRAVEL, q * 0.4)
	return mix(col, sand, 1 - smoothstep(sw - 1.2, sw + 1.2, d))
end

-- Água pintada na mesma imagem do chão: rasa e clara na beira, funda no meio,
-- com uma linha de espuma encostada na areia. Não vai num Decal separado com
-- transparência: Decal transparente por cima do chão apaga o nome dos jogadores
-- (visto no Studio em 10/11/2026, como a água transparente em 29/10).
local WATER_SHALLOW = hex("5cd6ee")
local WATER_MID = hex("22aee4")
local WATER_DEEP = hex("1478c4")
local FOAM = hex("eefcff")
-- Map/Ground/Ocean (1f6f9f): a baía encosta nele no leste. Mais escuro aqui
-- porque a textura de grama por cima clareia a imagem (o oceano não tem textura).
local OCEAN = hex("0f5f97")

local function waterAt(x: number, z: number): (RGB, number)
	local gx, gz = (x - X0) / CELL, (z - Z0) / CELL
	local d = sample(dist, gx, gz)
	local alpha = 1 - smoothstep(-0.5, 0.5, d)
	if alpha <= 0 then
		return WATER_SHALLOW, 0
	end
	local depth = -d
	local col = if depth < 6
		then mix(WATER_SHALLOW, WATER_MID, smoothstep(0, 6, depth))
		else mix(WATER_MID, WATER_DEEP, smoothstep(6, 28, depth))
	local m = (sample(mottle, gx, gz) - 0.5) * 0.08
	col = { col[1] * (1 + m), col[2] * (1 + m), col[3] * (1 + m) }
	-- Perto da borda leste, a baía vira a cor do oceano.
	col = mix(col, OCEAN, smoothstep(-215, -152, x) * smoothstep(4, 20, depth))
	-- Espuma: faixa fina na beira, falhada pelo ruído.
	local foam = (1 - smoothstep(0.4, 2.2, depth)) * (0.55 + 0.45 * smoothstep(0.35, 0.6, sample(stones, gx, gz)))
	return mix(col, FOAM, foam * 0.85), alpha
end

-- PNG sem filtro, comprimido com zlib (RGB ou RGBA).
local crcTable = table.create(256, 0)
for n = 0, 255 do
	local c = n
	for _ = 1, 8 do
		c = if bit32.band(c, 1) == 1 then bit32.bxor(0xEDB88320, bit32.rshift(c, 1)) else bit32.rshift(c, 1)
	end
	crcTable[n + 1] = c
end
local function crc32(s: string): number
	local c = 0xFFFFFFFF
	for i = 1, #s do
		c = bit32.bxor(crcTable[bit32.band(bit32.bxor(c, s:byte(i)), 0xFF) + 1], bit32.rshift(c, 8))
	end
	return bit32.bxor(c, 0xFFFFFFFF)
end
local function chunk(kind: string, data: string): string
	return string.pack(">I4", #data) .. kind .. data .. string.pack(">I4", crc32(kind .. data))
end
local function byte(v: number): number
	return math.clamp(math.floor(v + 0.5), 0, 255)
end

-- Decal no topo da peça: linha de cima da imagem = lado +Z, esquerda = +X
-- (conferido no Studio em 10/11/2026: ao contrário, a imagem saiu girada 180°).
local function render(withAlpha: boolean, pixel: (number, number) -> (RGB, number)): string
	local channels = if withAlpha then 4 else 3
	local raw = buffer.create(RES * (RES * channels + 1))
	local o = 0
	for row = 0, RES - 1 do
		buffer.writeu8(raw, o, 0)
		o += 1
		local z = Z0 + SIZE - (row + 0.5) * SIZE / RES
		for col = 0, RES - 1 do
			local x = X0 + SIZE - (col + 0.5) * SIZE / RES
			local c, a = pixel(x, z)
			buffer.writeu8(raw, o, byte(c[1]))
			buffer.writeu8(raw, o + 1, byte(c[2]))
			buffer.writeu8(raw, o + 2, byte(c[3]))
			if withAlpha then
				buffer.writeu8(raw, o + 3, byte(a * 255))
			end
			o += channels
		end
	end
	return "\137PNG\r\n\26\n"
		.. chunk("IHDR", string.pack(">I4I4BBBBB", RES, RES, 8, if withAlpha then 6 else 2, 0, 0, 0))
		.. chunk("IDAT", serde.compress("zlib", buffer.tostring(raw)))
		.. chunk("IEND", "")
end

local images = {
	["forest.png"] = render(false, function(x, z)
		local water, alpha = waterAt(x, z)
		return mix(colorAt(x, z), water, alpha), 1
	end),
}
for name, png in images do
	fs.writeFile(name, png)
	print(`{name}: {RES}x{RES}, {#png // 1024} KB`)
end

if process.args[1] == "serve" then
	local port = 34999
	net.serve(port, function(request)
		local png = images[string.sub(request.path, 2)]
		if png == nil then
			return { status = 404, body = "404" }
		end
		return { status = 200, headers = { ["Content-Type"] = "image/png" }, body = png }
	end)
	print(`servindo em http://localhost:{port}/forest.png`)
end
