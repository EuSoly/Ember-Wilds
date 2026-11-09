--!strict
-- Lógica do inventário (só dados: testável no Lune).
--
-- O inventário é uma lista de slots (1 até a capacidade); cada slot tem um item
-- e uma quantidade, ou está vazio (nil). Toda função que muda o inventário
-- devolve a lista de slots alterados, para o servidor mandar só esses ao cliente.
-- Nenhuma função espera (yield): cada operação acontece inteira de uma vez,
-- então dois pedidos nunca se misturam e não há como duplicar itens.

local InventoryConfig = require("./InventoryConfig")

export type Slot = { id: string, count: number }
export type Inventory = { capacity: number, slots: { [number]: Slot } }

local Inventory = {}

function Inventory.new(capacity: number): Inventory
	return { capacity = capacity, slots = {} }
end

local function isValidIndex(inv: Inventory, index: number): boolean
	return index % 1 == 0 and index >= 1 and index <= inv.capacity
end

-- Adiciona `count` de `id`. Primeiro completa pilhas do mesmo item (na ordem
-- dos slots), depois usa slots vazios. Devolve (o que não coube, slots alterados).
function Inventory.add(inv: Inventory, id: string, count: number, maxStack: number): (number, { number })
	local remaining = count
	local changed: { number } = {}

	for index = 1, inv.capacity do
		if remaining <= 0 then
			break
		end
		local slot = inv.slots[index]
		if slot and slot.id == id and slot.count < maxStack then
			local added = math.min(maxStack - slot.count, remaining)
			slot.count += added
			remaining -= added
			table.insert(changed, index)
		end
	end

	for index = 1, inv.capacity do
		if remaining <= 0 then
			break
		end
		if inv.slots[index] == nil then
			local added = math.min(maxStack, remaining)
			inv.slots[index] = { id = id, count = added }
			remaining -= added
			table.insert(changed, index)
		end
	end

	return remaining, changed
end

-- Quantidade total de `id` no inventário.
function Inventory.count(inv: Inventory, id: string): number
	local total = 0
	for index = 1, inv.capacity do
		local slot = inv.slots[index]
		if slot and slot.id == id then
			total += slot.count
		end
	end
	return total
end

-- Remove `count` de `id`, tudo ou nada (se não tiver o suficiente, nada muda).
-- Tira das últimas pilhas primeiro, para não "furar" a hotbar.
function Inventory.remove(inv: Inventory, id: string, count: number): (boolean, { number })
	if Inventory.count(inv, id) < count then
		return false, {}
	end
	local remaining = count
	local changed: { number } = {}
	for index = inv.capacity, 1, -1 do
		if remaining <= 0 then
			break
		end
		local slot = inv.slots[index]
		if slot and slot.id == id then
			local taken = math.min(slot.count, remaining)
			slot.count -= taken
			remaining -= taken
			if slot.count == 0 then
				inv.slots[index] = nil
			end
			table.insert(changed, index)
		end
	end
	return true, changed
end

-- Remove `count` do slot `index` (só dele, não de outra pilha do mesmo item),
-- tudo ou nada. Índice fora da capacidade, slot vazio, quantidade inválida
-- (0, negativa, fração, NaN, inf) ou maior que a pilha: nada muda.
function Inventory.removeAt(inv: Inventory, index: number, count: number): (boolean, { number })
	if not isValidIndex(inv, index) or not (count >= 1 and count < math.huge and count % 1 == 0) then
		return false, {}
	end
	local slot = inv.slots[index]
	if slot == nil or slot.count < count then
		return false, {}
	end
	slot.count -= count
	if slot.count == 0 then
		inv.slots[index] = nil
	end
	return true, { index }
end

-- Quanto de `id` caberia agora (o que Inventory.add aceitaria), sem mudar nada:
-- o que falta nas pilhas do mesmo item + uma pilha cheia por slot vazio.
function Inventory.spaceFor(inv: Inventory, id: string, maxStack: number): number
	local space = 0
	for index = 1, inv.capacity do
		local slot = inv.slots[index]
		if slot == nil then
			space += maxStack
		elseif slot.id == id and slot.count < maxStack then
			space += maxStack - slot.count
		end
	end
	return space
end

-- Move o conteúdo do slot `from` para `to`:
-- - destino vazio: move;
-- - mesmo item: junta até o máximo da pilha (o resto fica na origem);
-- - item diferente: troca.
-- Pedido inválido (índices fora, origem vazia, from == to) não muda nada.
function Inventory.move(inv: Inventory, from: number, to: number, maxStackOf: (string) -> number): { number }
	if from == to or not isValidIndex(inv, from) or not isValidIndex(inv, to) then
		return {}
	end
	local source = inv.slots[from]
	if source == nil then
		return {}
	end
	local target = inv.slots[to]

	if target == nil then
		inv.slots[to] = source
		inv.slots[from] = nil
	elseif target.id == source.id then
		local space = maxStackOf(source.id) - target.count
		if space <= 0 then
			return {}
		end
		local moved = math.min(space, source.count)
		target.count += moved
		source.count -= moved
		if source.count == 0 then
			inv.slots[from] = nil
		end
	else
		inv.slots[to] = source
		inv.slots[from] = target
	end
	return { from, to }
end

-- Primeiro slot (1..maxIndex, ou até a capacidade) com o item `id`, ou nil.
-- maxIndex limita a busca — ex.: achar o livro só entre os slots da hotbar.
function Inventory.findSlot(inv: Inventory, id: string, maxIndex: number?): number?
	local last = math.min(maxIndex or inv.capacity, inv.capacity)
	for index = 1, last do
		local slot = inv.slots[index]
		if slot and slot.id == id then
			return index
		end
	end
	return nil
end

-- Capacidade para um jogador com uma mochila de `bagSlots` e `bonusSlots` de
-- gamepass: base + mochila + bônus, entre BASE_SLOTS e MAX_SLOTS.
function Inventory.capacityFor(bagSlots: number, bonusSlots: number): number
	local total = InventoryConfig.BASE_SLOTS + math.max(bagSlots, 0) + math.max(bonusSlots, 0)
	return math.clamp(total, InventoryConfig.BASE_SLOTS, InventoryConfig.MAX_SLOTS)
end

-- Muda a capacidade (ex.: vestiu ou trocou de mochila). Aumentar sempre pode;
-- diminuir só se os slots que vão sumir estiverem vazios, para nenhum item se
-- perder. Devolve true se a capacidade ficou igual a `capacity`.
function Inventory.setCapacity(inv: Inventory, capacity: number): boolean
	if capacity < inv.capacity then
		for index = capacity + 1, inv.capacity do
			if inv.slots[index] ~= nil then
				return false
			end
		end
	end
	inv.capacity = capacity
	return true
end

return Inventory
