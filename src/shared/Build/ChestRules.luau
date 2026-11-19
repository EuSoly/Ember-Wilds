--!strict
-- Regras puras do baú: servidor e cliente usam as mesmas.
-- Desde 19/11 o baú guarda até 3 tipos de item (ChestRules.SLOTS = 3), cada um
-- uma pilha até ChestRules.MAX.

export type Contents = { id: string?, count: number }
export type Chest = { Contents }

local ChestRules = {}
ChestRules.SLOTS = 3
ChestRules.MAX = 9999
-- Studs do centro do baú (XZ): meia célula + 1 célula + folga do corpo.
ChestRules.RANGE = 8

-- Só inteiros positivos e finitos movem itens (0, negativo, fração, NaN e inf não).
local function validCount(count: number): boolean
	return count > 0 and count < math.huge and count == math.floor(count)
end

local function validSlot(slot: number): boolean
	return slot >= 1 and slot <= ChestRules.SLOTS and slot == math.floor(slot)
end

function ChestRules.new(): Chest
	local chest: Chest = {}
	for i = 1, ChestRules.SLOTS do
		chest[i] = { id = nil, count = 0 }
	end
	return chest
end

-- Quanto cabe num único slot (0 se outro tipo ou cheio).
function ChestRules.canPut(c: Contents, id: string, count: number): number
	if not validCount(count) then
		return 0
	end
	if c.id ~= nil and c.id ~= id then
		return 0
	end
	return math.min(count, ChestRules.MAX - c.count)
end

function ChestRules.put(c: Contents, id: string, count: number): number
	local fits = ChestRules.canPut(c, id, count)
	if fits <= 0 then
		return 0
	end
	c.id = id
	c.count += fits
	return fits
end

-- Tira até count de um slot; esvaziou → id volta a nil.
function ChestRules.take(c: Contents, count: number): (string?, number)
	local id = c.id
	if id == nil or not validCount(count) then
		return nil, 0
	end
	local taken = math.min(count, c.count)
	c.count -= taken
	if c.count <= 0 then
		c.id = nil
		c.count = 0
	end
	return id, taken
end

-- Acha o slot para `id` (o que já tem `id`, senão o primeiro vazio) e diz
-- quanto cabe lá: devolve (quanto cabe, índice do slot) ou (0, nil).
function ChestRules.canPutAny(chest: Chest, id: string, count: number): (number, number?)
	if not validCount(count) then
		return 0, nil
	end
	for i = 1, ChestRules.SLOTS do
		local c = chest[i]
		if c and c.id == id then
			local fits = ChestRules.canPut(c, id, count)
			if fits > 0 then
				return fits, i
			end
			return 0, nil
		end
	end
	for i = 1, ChestRules.SLOTS do
		local c = chest[i]
		if c and c.id == nil then
			local fits = ChestRules.canPut(c, id, count)
			if fits > 0 then
				return fits, i
			end
			return 0, nil
		end
	end
	return 0, nil
end

-- Põe no slot que já tem `id`; senão no primeiro vazio; devolve (quanto entrou,
-- índice do slot) ou (0, nil).
function ChestRules.putAny(chest: Chest, id: string, count: number): (number, number?)
	local fits, slot = ChestRules.canPutAny(chest, id, count)
	if fits <= 0 or slot == nil then
		return 0, nil
	end
	local put = ChestRules.put(chest[slot], id, fits)
	if put <= 0 then
		return 0, nil
	end
	return put, slot
end

-- Tira até `count` do slot `slot` (1..SLOTS).
function ChestRules.takeAt(chest: Chest, slot: number, count: number): (string?, number)
	if not validSlot(slot) then
		return nil, 0
	end
	local c = chest[slot]
	if c == nil then
		return nil, 0
	end
	return ChestRules.take(c, count)
end

return table.freeze(ChestRules)
