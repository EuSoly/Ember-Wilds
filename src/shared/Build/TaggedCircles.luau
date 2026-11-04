--!strict
-- Círculos (vistos de cima) dos modelos com uma tag do CollectionService e o
-- raio num atributo do modelo: as pontes e os telhados (StatNames.BridgeTag /
-- RoofTag + PieceRadius). Serve nos dois lados sem depender do StructureService
-- (a água do WaterSim roda no cliente também).
--
-- Barato: a lista é mantida pelos sinais de tag (entrou/saiu), não pelo
-- GetTagged a cada consulta, e só é refeita quando muda. A peça não se mexe
-- depois de colocada, então o centro é lido do pivô uma vez por refazer.
-- Modelo que saiu do mundo (Destroy) antes de o sinal de saída chegar já não
-- conta: a consulta confere o Parent e refaz a lista na hora.
-- (Só roda no Roblox: usa o CollectionService.)
local CollectionService = game:GetService("CollectionService")

local BuildRules = require("./BuildRules")

type Circle = BuildRules.Circle

export type Watcher = {
	tag: string,
	radiusAttribute: string,
	-- Modelos com a tag no mundo.
	members: { [Model]: boolean },
	-- Lista pronta: circles[i] é o círculo de owners[i].
	circles: { Circle },
	owners: { Model },
	dirty: boolean,
}

local TaggedCircles = {}

-- Círculo do modelo, ou nil. O segundo valor diz se vale tentar de novo: sem
-- a peça principal (pode chegar depois no cliente) sim; sem um raio válido
-- não (o modelo fica de fora e a lista não refaz a cada consulta).
local function circleOf(watcher: Watcher, model: Model): (Circle?, boolean)
	local radius = model:GetAttribute(watcher.radiusAttribute)
	if typeof(radius) ~= "number" or not (radius > 0) then
		return nil, false
	end
	if model.PrimaryPart == nil then
		return nil, true
	end
	local position = model:GetPivot().Position
	return { x = position.X, z = position.Z, r = radius }, false
end

local function rebuild(watcher: Watcher)
	local circles: { Circle } = {}
	local owners: { Model } = {}
	local pending = false
	for model in watcher.members do
		if model.Parent == nil then
			continue
		end
		local circle, retry = circleOf(watcher, model)
		if circle then
			table.insert(circles, circle)
			table.insert(owners, model)
		elseif retry then
			pending = true
		end
	end
	watcher.circles = circles
	watcher.owners = owners
	-- Alguma peça ainda incompleta: tenta de novo na próxima consulta.
	watcher.dirty = pending
end

-- Acompanha os modelos com `tag`; o raio vem do atributo `radiusAttribute`.
function TaggedCircles.watch(tag: string, radiusAttribute: string): Watcher
	local watcher: Watcher = {
		tag = tag,
		radiusAttribute = radiusAttribute,
		members = {},
		circles = {},
		owners = {},
		dirty = true,
	}
	local function add(instance: Instance)
		if instance:IsA("Model") then
			watcher.members[instance] = true
			watcher.dirty = true
		end
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(add)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
		if instance:IsA("Model") then
			watcher.members[instance] = nil
			watcher.dirty = true
		end
	end)
	for _, instance in CollectionService:GetTagged(tag) do
		add(instance)
	end
	return watcher
end

-- Os círculos atuais e, no mesmo índice, o modelo de cada um.
function TaggedCircles.list(watcher: Watcher): ({ Circle }, { Model })
	if not watcher.dirty then
		for _, model in watcher.owners do
			if model.Parent == nil then
				watcher.dirty = true
				break
			end
		end
	end
	if watcher.dirty then
		rebuild(watcher)
	end
	return watcher.circles, watcher.owners
end

-- O ponto (x, z) está dentro (ou na borda) de algum círculo, expandido por
-- `margin` (padrão 0)?
function TaggedCircles.contains(watcher: Watcher, x: number, z: number, margin: number?): boolean
	local circles = TaggedCircles.list(watcher)
	return BuildRules.insideAny(x, z, circles, margin)
end

return TaggedCircles
