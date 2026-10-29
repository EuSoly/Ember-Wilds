--!strict
-- Modelos dos recursos do mundo, montados pelo MapService em Workspace.Resources.
-- 1. Se existe um modelo do Studio em ServerStorage.Assets.Resources com o nome
--    "<id>_<variação>" (ou "<id>_1"), ele é clonado, redimensionado para
--    Defs.Resources.size × a variação do exemplar, e ganha uma peça de colisão
--    invisível no pé (tronco/base). Todas as peças do modelo viram enfeite.
-- 2. Senão, entra o modelo provisório feito por código (abaixo).
--
-- Padrão de todo recurso:
-- - pivô no chão (Y = 0), sem giro: quem monta só faz
--   model:PivotTo(CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0));
-- - UMA peça sólida (a PrimaryPart) com raio = collisionRadius × variação;
--   enfeites (decorative, ex. pedras do chão) não têm colisão;
-- - copas das árvores com a tag Occluder (ficam transparentes sobre o boneco);
-- - atributo ResourceId; tag Resource (menos nos enfeites);
-- - ModelStreamingMode = Atomic (chega inteiro ao cliente).
-- Medidas na escala do boneco (corpo de 3,6 studs de largura e ~2 de altura).
-- (Só roda no Roblox, e o build só no servidor: lê o ServerStorage.)
local ServerStorage = game:GetService("ServerStorage")

local Defs = require("../Defs")
local Palette = require("../Palette")
local StatNames = require("../StatNames")
local Theme = require("../Theme")
local Types = require("../Defs/Types")

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

-- Pedra do chão (provisória): uma bolinha cinza, sem colisão.
local function buildPebble(model: Model, r: number, _variant: number): Part
	local pebble = newPart("Pebble", Enum.PartType.Ball, Vector3.one * r * 2, CFrame.new(0, r * 0.4, 0), STONE)
	add(model, pebble)
	return pebble
end

type Builder = (model: Model, collisionRadius: number, variant: number) -> Part

local BUILDERS: { [string]: Builder } = {
	tree = buildTree,
	rock = buildRock,
	gold_vein = buildGoldVein,
	berry_bush = buildBerryBush,
	pebble = buildPebble,
}

-- Altura da peça de colisão (invisível) dos modelos do Studio.
local COLLIDER_HEIGHT = 6

-- Modelo feito no Studio: ServerStorage.Assets.Resources/<id>_<variação>
-- (ou <id>_1 se a variação não existir). nil = usa o provisório de código.
local function findTemplate(resourceId: string, variant: number): Model?
	local assets = ServerStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Resources")
	if folder == nil then
		return nil
	end
	local template = folder:FindFirstChild(`{resourceId}_{variant}`) or folder:FindFirstChild(`{resourceId}_1`)
	if template == nil then
		return nil
	end
	if not template:IsA("Model") then
		warn(`[ResourceModels] {template:GetFullName()} precisa ser um Model; usando o provisório`)
		return nil
	end
	return template
end

-- Meia altura de uma peça no eixo Y do mundo (considera o giro dela).
local function halfHeight(part: BasePart): number
	local cf, size = part.CFrame, part.Size
	return 0.5
		* (math.abs(cf.RightVector.Y) * size.X + math.abs(cf.UpVector.Y) * size.Y + math.abs(cf.LookVector.Y) * size.Z)
end

-- Clona e prepara um modelo do Studio: redimensiona para def.size × scale,
-- deixa tudo como enfeite (ancorado, sem colisão nem raycast), marca as
-- árvores inteiras como Occluder e cria a peça de colisão (invisível) no pé do tronco/base.
-- O pivô fica no chão, embaixo da peça de colisão.
local function fromTemplate(template: Model, def: Types.ResourceDef, scale: number): Model
	local model = template:Clone()
	-- Modelo de recurso não roda código: remove scripts que vierem junto.
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("LuaSourceContainer") then
			descendant:Destroy()
		end
	end

	local _, boxSize = model:GetBoundingBox()
	local measured = if def.sizeAxis == "height" then boxSize.Y else math.max(boxSize.X, boxSize.Z)
	local factor = if def.size and measured > 0 then def.size * scale / measured else scale
	if factor ~= 1 then
		model:ScaleTo(model:GetScale() * factor)
	end

	-- Altura e "pé" do modelo: a peça mais baixa (o tronco, nas árvores).
	local minY, maxY = math.huge, -math.huge
	local lowest: BasePart? = nil
	local lowestBottom = math.huge
	local parts: { BasePart } = {}
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BasePart") then
			table.insert(parts, descendant)
			local half = halfHeight(descendant)
			local bottom = descendant.Position.Y - half
			minY = math.min(minY, bottom)
			maxY = math.max(maxY, descendant.Position.Y + half)
			if bottom < lowestBottom then
				lowestBottom = bottom
				lowest = descendant
			end
		end
	end
	local boxCFrame = model:GetBoundingBox()
	local foot = if def.id == "tree" and lowest then lowest.Position else boxCFrame.Position
	local height = maxY - minY

	for _, part in parts do
		part.Anchored = true
		part.CanCollide = false
		part.CanQuery = false
		part.CanTouch = false
		-- Árvore inteira (copa e tronco com galhos): o tronco também esconde o
		-- boneco quando ele passa atrás dela.
		if def.id == "tree" then
			part:AddTag(StatNames.OccluderTag)
		end
	end

	-- Pivô no chão; com `sink`, parte da altura fica enterrada (pedras do chão).
	local ground = CFrame.new(foot.X, minY + height * (def.sink or 0), foot.Z)
	local primary: Part
	if def.decorative then
		-- Enfeite: sem colisão; uma âncora invisível só para o pivô.
		primary = newPart("Anchor", Enum.PartType.Block, Vector3.one * 0.2, ground, STONE)
		primary.Transparency = 1
	else
		-- A colisão cresce junto com o exemplar (o espalhador conta com isso).
		local r = def.collisionRadius * scale
		primary = solid(
			newPart(
				"Collision",
				Enum.PartType.Cylinder,
				Vector3.new(COLLIDER_HEIGHT, r * 2, r * 2),
				ground * CFrame.new(0, COLLIDER_HEIGHT / 2, 0) * UPRIGHT,
				STONE
			)
		)
		primary.Transparency = 1
	end
	primary.Parent = model
	model.PrimaryPart = primary
	primary.PivotOffset = primary.CFrame:Inverse() * ground
	return model
end

-- Monta o modelo do recurso, ou nil para id desconhecido. Usa o modelo do
-- Studio (ServerStorage.Assets.Resources) se existir; senão o provisório de
-- código. `scale` = variação de tamanho deste exemplar (1 = normal). A
-- variação é limitada a 1..variants. Só no servidor (lê o ServerStorage).
function ResourceModels.build(resourceId: string, variant: number, scale: number?): Model?
	local def = Defs.Resources[resourceId]
	if def == nil then
		return nil
	end
	local v = math.clamp(math.floor(variant), 1, def.variants)
	local s = scale or 1

	local model: Model
	local template = findTemplate(resourceId, v)
	if template then
		model = fromTemplate(template, def, s)
	else
		local builder = BUILDERS[resourceId]
		if builder == nil then
			return nil
		end
		model = Instance.new("Model")
		local primary = builder(model, def.collisionRadius, v)
		model.PrimaryPart = primary
		-- Pivô no centro da base, no chão, sem giro. Com PrimaryPart, o pivô do
		-- modelo é o da PrimaryPart (WorldPivot não vale): sem este ajuste o pivô
		-- herdaria o giro do tronco (cilindro deitado + UPRIGHT) e o PivotTo
		-- derrubaria a árvore.
		primary.PivotOffset = primary.CFrame:Inverse()
		if def.decorative then
			for _, descendant in model:GetDescendants() do
				if descendant:IsA("BasePart") then
					descendant.CanCollide = false
					descendant.CanQuery = false
				end
			end
		end
		if s ~= 1 then
			model:ScaleTo(s)
		end
	end

	model.Name = resourceId
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	model:SetAttribute(StatNames.ResourceId, resourceId)
	if not def.decorative then
		model:AddTag(StatNames.ResourceTag)
	end
	return model
end

return ResourceModels
