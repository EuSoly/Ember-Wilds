--!strict
-- Cópia do inventário (só dados: testável no Lune), para o revive: quem morre
-- e paga para voltar volta com EXATAMENTE o mesmo inventário — os mesmos slots
-- nos mesmos índices, a mochila e a armadura vestidas e o slot selecionado.
--
-- `copy` tira a foto (cópia funda: mexer no inventário depois não muda a foto);
-- `apply` põe a foto num inventário e nunca perde item: se a foto tem mais
-- slots que o inventário, a capacidade sobe para caber tudo.

local Inventory = require("./Inventory")

export type Snapshot = {
	capacity: number,
	slots: { [number]: { id: string, count: number } },
	bag: string?,
	armor: string?,
	selected: number,
}

local InventorySnapshot = {}

local function copySlots(slots: { [number]: Inventory.Slot }): { [number]: Inventory.Slot }
	local out: { [number]: Inventory.Slot } = {}
	for index, slot in slots do
		out[index] = { id = slot.id, count = slot.count }
	end
	return out
end

function InventorySnapshot.copy(inv: Inventory.Inventory, bag: string?, armor: string?, selected: number): Snapshot
	return {
		capacity = inv.capacity,
		slots = copySlots(inv.slots),
		bag = bag,
		armor = armor,
		selected = selected,
	}
end

-- Troca o conteúdo de `inv` pelo da foto: cada slot no mesmo índice (o que
-- havia antes some). A capacidade fica no mínimo a da foto (e o maior índice
-- ocupado, se a foto vier torta), para nenhum item ficar fora.
function InventorySnapshot.apply(inv: Inventory.Inventory, snap: Snapshot)
	local capacity = math.max(inv.capacity, snap.capacity)
	for index in snap.slots do
		capacity = math.max(capacity, index)
	end
	inv.capacity = capacity
	inv.slots = copySlots(snap.slots)
end

return InventorySnapshot
