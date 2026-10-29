--!strict
-- Modelos provisórios dos recursos do mundo (low-poly, só peças), montados
-- pelo MapService em Workspace.Resources. Quando os modelos de verdade
-- chegarem, só este arquivo muda (como o ToolModel).
--
-- Padrão de todo recurso:
-- - pivô no centro da base, no chão (Y = 0): quem monta só faz
--   model:PivotTo(CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0));
-- - no máximo 6 peças, todas ancoradas, CanTouch = false;
-- - UMA peça sólida (a PrimaryPart: tronco ou base) com raio = collisionRadius
--   de Defs.Resources; o resto não colide nem é atingido por raycast;
-- - CastShadow só no topo (copa/pedra de cima), para a sombra ficar leve;
-- - copas das árvores com a tag Occluder (ficam transparentes sobre o boneco);
-- - atributo ResourceId e tag Resource no modelo (a fase de coleta usa);
-- - ModelStreamingMode = Atomic (chega inteiro ao cliente).
-- As variações (1..variants) mudam tamanho e forma de leve, sem sorteio: o
-- mesmo id e variação dão sempre o mesmo modelo.
-- Medidas na escala do boneco (corpo de 3,6 studs de largura e ~2 de altura).
-- (Só roda no Roblox: cria instâncias.)
local Defs = require("../Defs")
local Palette = require("../Palette")
local StatNames = require("../StatNames")
local Theme = require("../Theme")

local ResourceModels = {}

local LEAF_LIGHT = Theme.color(Palette.biome.forest[1])
local LEAF_DARK = Theme.color(Palette.biome.forest[2])
local WOOD = Theme.color(Palette.biome.forest[3])
local STONE = Theme.color(Palette.tier.stone)
local GOLD = Theme.color(Palette.tier.gold)
-- Frutinha: o vermelho da paleta (mesmo da vida).
local BERRY = Theme.color(Palette.status.health)

-- Cilindro do Roblox tem o eixo em X: este giro o deixa em pé (eixo em Y).
local UPRIGHT = CFrame.Angles(0, 0, math.pi / 2)

local function newPart(name: string, shape: Enum.PartType, size: Vector3, cframe: CFrame, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = shape
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	-- Enfeite por padrão; a peça sólida é ligada em `solid`.
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	return part
end

local function solid(part: Part): Part
	part.CanCollide = true
	part.CanQuery = true
	return part
end

local function shadowed(part: Part): Part
	part.CastShadow = true
	return part
end

local function canopy(part: Part): Part
	part.CastShadow = true
	part:AddTag(StatNames.OccluderTag)
	return part
end

local function add(model: Model, part: Part)
	part.Parent = model
end

-- Árvore: tronco marrom (sólido) + copa de 2–3 peças verdes por cima do boneco.
-- Copa de ~9–12 studs vista de cima.
local function buildTree(model: Model, r: number, variant: number): Part
	local trunkHeight = 5 + variant * 0.5
	local trunkSize = Vector3.new(trunkHeight, r * 2, r * 2)
	local trunk =
		solid(newPart("Trunk", Enum.PartType.Cylinder, trunkSize, CFrame.new(0, trunkHeight / 2, 0) * UPRIGHT, WOOD))
	add(model, trunk)

	local top = trunkHeight + 2
	if variant == 1 then
		-- Redonda: uma bola grande e uma menor de lado.
		add(model, canopy(newPart("Canopy", Enum.PartType.Ball, Vector3.one * 9, CFrame.new(0, top, 0), LEAF_DARK)))
		add(
			model,
			canopy(
				newPart("Canopy", Enum.PartType.Ball, Vector3.one * 5.5, CFrame.new(2.6, top + 1.6, -1.4), LEAF_LIGHT)
			)
		)
	elseif variant == 2 then
		-- Larga: três bolas em triângulo (~11 de largura).
		for i, offset in { Vector3.new(-2.2, 0, 1.2), Vector3.new(2.2, 0.4, 1.2), Vector3.new(0, 1, -2) } do
			local color = if i == 3 then LEAF_LIGHT else LEAF_DARK
			add(
				model,
				canopy(newPart("Canopy", Enum.PartType.Ball, Vector3.one * 7, CFrame.new(0, top, 0) + offset, color))
			)
		end
	else
		-- Pinheiro achatado: dois discos (cilindros em pé) empilhados.
		local low = CFrame.new(0, top - 0.6, 0) * UPRIGHT
		local high = CFrame.new(0, top + 1.4, 0) * UPRIGHT
		add(model, canopy(newPart("Canopy", Enum.PartType.Cylinder, Vector3.new(2.4, 11, 11), low, LEAF_DARK)))
		add(model, canopy(newPart("Canopy", Enum.PartType.Cylinder, Vector3.new(2.4, 7, 7), high, LEAF_LIGHT)))
	end
	return trunk
end

-- Base de pedra sólida: bola de raio r afundada no chão, para o contorno na
-- altura do boneco ficar perto de r.
local function stoneBase(model: Model, r: number): Part
	local base = solid(newPart("Base", Enum.PartType.Ball, Vector3.one * r * 2, CFrame.new(0, r * 0.25, 0), STONE))
	add(model, base)
	return base
end

-- Rocha: 2–3 pedras cinza, a maior é a sólida. ~5–7 studs vista de cima.
local function buildRock(model: Model, r: number, variant: number): Part
	local base = stoneBase(model, r)
	local rocks = {
		{ offset = Vector3.new(r * 0.9, 0.4, r * 0.5), size = 2.4 },
		{ offset = Vector3.new(-r * 0.6, 0.2, r * 0.8), size = 1.8 },
	}
	local count = if variant == 1 then 1 else 2
	local shape = if variant == 3 then Enum.PartType.Block else Enum.PartType.Ball
	for i = 1, count do
		local rock = rocks[i]
		local cframe = CFrame.new(rock.offset) * CFrame.Angles(0, i * 0.8, 0.3)
		add(model, shadowed(newPart("Rock", shape, Vector3.one * rock.size, cframe, STONE)))
	end
	-- Pedra de cima, para o topo ficar legível pela câmera.
	add(
		model,
		shadowed(newPart("Top", Enum.PartType.Ball, Vector3.one * r * 1.1, CFrame.new(-0.3, r * 0.9, -0.2), STONE))
	)
	return base
end

-- Jazida de ouro: rocha cinza (sólida) + 2–3 cristais dourados girados.
-- ~5–6 studs vista de cima.
local function buildGoldVein(model: Model, r: number, variant: number): Part
	local base = stoneBase(model, r)
	local crystals = {
		{
			offset = Vector3.new(0.4, r * 0.9, 0),
			size = Vector3.new(0.9, 2.2, 0.9),
			turn = CFrame.Angles(0.3, 0.4, 0.2),
		},
		{
			offset = Vector3.new(-1.1, r * 0.75, 0.8),
			size = Vector3.new(0.8, 1.7, 0.8),
			turn = CFrame.Angles(-0.4, 1.1, -0.5),
		},
		{
			offset = Vector3.new(1, r * 0.7, -1),
			size = Vector3.new(0.7, 1.5, 0.7),
			turn = CFrame.Angles(0.5, 2.0, 0.4),
		},
	}
	local count = if variant == 1 then 3 else 2
	for i = 1, count do
		local c = crystals[i]
		local crystal = shadowed(newPart("Crystal", Enum.PartType.Block, c.size, CFrame.new(c.offset) * c.turn, GOLD))
		crystal.Material = Enum.Material.Neon
		add(model, crystal)
	end
	return base
end

-- Arbusto de frutinha: bola verde (sólida) + 3–4 frutinhas vermelhas por cima.
-- ~4–5 studs vista de cima.
local function buildBerryBush(model: Model, r: number, variant: number): Part
	local bush =
		shadowed(solid(newPart("Bush", Enum.PartType.Ball, Vector3.one * r * 2, CFrame.new(0, r * 0.6, 0), LEAF_DARK)))
	add(model, bush)
	-- Tufo claro em cima (enfeite), para o topo não ficar liso.
	add(model, newPart("Top", Enum.PartType.Ball, Vector3.one * r * 1.2, CFrame.new(0.2, r * 1.2, -0.2), LEAF_LIGHT))
	local count = if variant == 1 then 4 else 3
	local spread = r * 0.85
	for i = 1, count do
		local angle = (i / count) * 2 * math.pi + variant * 0.5
		local height = r * 1.1 - (i % 2) * 0.4
		local cframe = CFrame.new(math.cos(angle) * spread, height, math.sin(angle) * spread)
		add(model, newPart("Berry", Enum.PartType.Ball, Vector3.one, cframe, BERRY))
	end
	return bush
end

type Builder = (model: Model, collisionRadius: number, variant: number) -> Part

local BUILDERS: { [string]: Builder } = {
	tree = buildTree,
	rock = buildRock,
	gold_vein = buildGoldVein,
	berry_bush = buildBerryBush,
}

-- Monta o modelo, ou nil para id desconhecido (ou ainda sem modelo). A
-- variação é limitada a 1..variants.
function ResourceModels.build(resourceId: string, variant: number): Model?
	local def = Defs.Resources[resourceId]
	local builder = BUILDERS[resourceId]
	if def == nil or builder == nil then
		return nil
	end
	local v = math.clamp(math.floor(variant), 1, def.variants)

	local model = Instance.new("Model")
	model.Name = resourceId
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute(StatNames.ResourceId, resourceId)
	model:AddTag(StatNames.ResourceTag)

	local primary = builder(model, def.collisionRadius, v)
	model.PrimaryPart = primary
	-- Pivô no centro da base, no chão, sem giro. Com PrimaryPart, o pivô do
	-- modelo é o da PrimaryPart (WorldPivot não vale): sem este ajuste o pivô
	-- herdaria o giro do tronco (cilindro deitado + UPRIGHT) e o PivotTo
	-- derrubaria a árvore.
	primary.PivotOffset = primary.CFrame:Inverse()
	return model
end

return ResourceModels
