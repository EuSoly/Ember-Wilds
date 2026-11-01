--!strict
-- Regras puras do baú: servidor e cliente usam as mesmas.

export type Contents = { id: string?, count: number }

local ChestRules = {}
ChestRules.MAX = 9999
-- Studs do centro do baú (XZ): meia célula + 1 célula + folga do corpo.
ChestRules.RANGE = 8

-- Só inteiros positivos e finitos movem itens (0, negativo, fração, NaN e inf não).
local function validCount(count: number): boolean
	return count > 0 and count < math.huge and count == math.floor(count)
end

-- Quanto cabe (0 se outro tipo ou cheio).
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

-- Tira até count; esvaziou → id volta a nil.
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

return table.freeze(ChestRules)
