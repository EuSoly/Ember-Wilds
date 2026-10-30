--!strict
-- Reserva dos recursos do mundo (G2). O MapService registra cada modelo
-- montado; aqui fica, para cada um, a reserva atual e a máxima (também nos
-- atributos Amount e AmountMax do modelo, que o cliente lê para mostrar as
-- frutinhas), uma grade espacial para o golpe achar o alvo sem varrer o mapa
-- inteiro, e a regeneração (só dos recursos que não estão cheios).
-- O modelo nunca some: vazio, ele fica e o GatherService avisa que acabou.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require(ReplicatedStorage.Shared.Defs)
local GatherRules = require(ReplicatedStorage.Shared.Gather.GatherRules)
local SpatialGrid = require(ReplicatedStorage.Shared.World.SpatialGrid)
local StatNames = require(ReplicatedStorage.Shared.StatNames)

local CELL_SIZE = 16 -- studs por célula da grade
local REGEN_CHECK = 1 -- segundos entre conferências da regeneração

export type Entry = {
	model: Model,
	def: Defs.ResourceDef,
	gather: Defs.GatherDef,
	x: number,
	z: number,
	radius: number, -- raio da peça de colisão deste exemplar
	max: number,
	amount: number,
	nextRegen: number, -- os.clock() da próxima volta (só vale fora do cheio)
}

local ResourceService = {}

local grid = SpatialGrid.new(CELL_SIZE)
-- Recursos abaixo do máximo (os únicos que o laço de regeneração olha).
local regenerating: { [Entry]: boolean } = {}

local function publish(entry: Entry)
	entry.model:SetAttribute(StatNames.Amount, entry.amount)
end

-- Registra um recurso montado (só os que têm gather; enfeites ficam de fora).
-- scale = Scatter.sizeFactor do exemplar.
function ResourceService.register(model: Model, def: Defs.ResourceDef, x: number, z: number, scale: number)
	local gather = def.gather
	if gather == nil then
		return
	end
	local max = GatherRules.maxAmount(gather, scale, def.sizeJitter or 0)
	local entry: Entry = {
		model = model,
		def = def,
		gather = gather,
		x = x,
		z = z,
		radius = def.collisionRadius * scale,
		max = max,
		amount = max,
		nextRegen = 0,
	}
	model:SetAttribute(StatNames.AmountMax, max)
	publish(entry)
	grid:insert(entry, x, z)
end

-- Recursos cujas células tocam o círculo (x, z, radius).
function ResourceService.near(x: number, z: number, radius: number): { Entry }
	return grid:query(x, z, radius)
end

-- Tira `count` da reserva (nunca abaixo de 0) e põe na fila de regeneração.
function ResourceService.take(entry: Entry, count: number)
	if not (count > 0) then
		return
	end
	entry.amount = math.max(entry.amount - count, 0)
	publish(entry)
	if not regenerating[entry] then
		regenerating[entry] = true
		entry.nextRegen = os.clock() + entry.gather.regen.every
	end
end

local function regenerate()
	local now = os.clock()
	for entry in regenerating do
		local before = entry.amount
		while entry.amount < entry.max and now >= entry.nextRegen do
			entry.amount = GatherRules.regen(entry.amount, entry.max, entry.gather)
			entry.nextRegen += entry.gather.regen.every
		end
		if entry.amount ~= before then
			publish(entry)
		end
		if entry.amount >= entry.max then
			regenerating[entry] = nil
		end
	end
end

function ResourceService.Start(_self)
	task.spawn(function()
		while true do
			task.wait(REGEN_CHECK)
			regenerate()
		end
	end)
end

return ResourceService
