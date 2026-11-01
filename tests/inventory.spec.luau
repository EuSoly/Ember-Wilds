--!strict
local Inventory = require("../src/shared/Inventory")

local function slotIs(inv: Inventory.Inventory, index: number, id: string?, count: number?)
	local slot = inv.slots[index]
	if id == nil then
		assert(slot == nil, `slot {index} deveria estar vazio, tem {slot and slot.id}`)
		return
	end
	assert(slot ~= nil, `slot {index} deveria ter {id}`)
	assert(slot.id == id, `slot {index}: esperava {id}, veio {slot.id}`)
	assert(slot.count == count, `slot {index}: esperava {count}, veio {slot.count}`)
end

local function sameSet(a: { number }, b: { number }): boolean
	if #a ~= #b then
		return false
	end
	local seen = {}
	for _, v in a do
		seen[v] = true
	end
	for _, v in b do
		if not seen[v] then
			return false
		end
	end
	return true
end

local function maxOf(max: number): (string) -> number
	return function(_id: string)
		return max
	end
end

return {
	["add to empty inventory"] = function()
		local inv = Inventory.new(10)
		local rest, changed = Inventory.add(inv, "wood", 30, 255)
		assert(rest == 0, `sobra {rest}`)
		slotIs(inv, 1, "wood", 30)
		assert(sameSet(changed, { 1 }), "alterados deveria ser {1}")
	end,

	["add fills existing stack then empty slots"] = function()
		local inv = Inventory.new(10)
		Inventory.add(inv, "wood", 8, 10)
		local rest, changed = Inventory.add(inv, "wood", 15, 10)
		assert(rest == 0, `sobra {rest}`)
		slotIs(inv, 1, "wood", 10)
		slotIs(inv, 2, "wood", 10)
		slotIs(inv, 3, "wood", 3)
		assert(sameSet(changed, { 1, 2, 3 }), "alterados deveria ser {1,2,3}")
	end,

	["add without space returns leftover"] = function()
		local inv = Inventory.new(2)
		local rest = Inventory.add(inv, "wood", 25, 10)
		assert(rest == 5, `sobra {rest}`)
		slotIs(inv, 1, "wood", 10)
		slotIs(inv, 2, "wood", 10)
	end,

	["remove is all or nothing"] = function()
		local inv = Inventory.new(10)
		Inventory.add(inv, "stone", 5, 255)
		local ok, changed = Inventory.remove(inv, "stone", 6)
		assert(ok == false, "não deveria remover mais do que tem")
		assert(#changed == 0, "nada deveria mudar")
		slotIs(inv, 1, "stone", 5)
		local ok2 = Inventory.remove(inv, "stone", 5)
		assert(ok2 == true, "deveria remover tudo")
		slotIs(inv, 1, nil)
	end,

	["remove takes from last stacks first"] = function()
		local inv = Inventory.new(10)
		Inventory.add(inv, "wood", 15, 10)
		local ok, changed = Inventory.remove(inv, "wood", 7)
		assert(ok, "deveria remover")
		slotIs(inv, 1, "wood", 8)
		slotIs(inv, 2, nil)
		assert(sameSet(changed, { 1, 2 }), "alterados deveria ser {1,2}")
	end,

	["count sums stacks"] = function()
		local inv = Inventory.new(10)
		Inventory.add(inv, "wood", 25, 10)
		Inventory.add(inv, "stone", 4, 10)
		assert(Inventory.count(inv, "wood") == 25, "madeira")
		assert(Inventory.count(inv, "gold") == 0, "ouro")
	end,

	["move to empty slot"] = function()
		local inv = Inventory.new(10)
		Inventory.add(inv, "wood", 5, 255)
		local changed = Inventory.move(inv, 1, 4, maxOf(255))
		slotIs(inv, 1, nil)
		slotIs(inv, 4, "wood", 5)
		assert(sameSet(changed, { 1, 4 }), "alterados deveria ser {1,4}")
	end,

	["move swaps different items"] = function()
		local inv = Inventory.new(10)
		Inventory.add(inv, "wood", 5, 255)
		Inventory.add(inv, "stone", 3, 255)
		Inventory.move(inv, 1, 2, maxOf(255))
		slotIs(inv, 1, "stone", 3)
		slotIs(inv, 2, "wood", 5)
	end,

	["move merges same item up to max stack"] = function()
		local inv = Inventory.new(10)
		inv.slots[1] = { id = "wood", count = 8 }
		inv.slots[2] = { id = "wood", count = 5 }
		local changed = Inventory.move(inv, 1, 2, maxOf(10))
		slotIs(inv, 2, "wood", 10)
		slotIs(inv, 1, "wood", 3)
		assert(sameSet(changed, { 1, 2 }), "alterados deveria ser {1,2}")
	end,

	["move merges completely when it fits"] = function()
		local inv = Inventory.new(10)
		inv.slots[1] = { id = "wood", count = 4 }
		inv.slots[2] = { id = "wood", count = 5 }
		Inventory.move(inv, 1, 2, maxOf(10))
		slotIs(inv, 2, "wood", 9)
		slotIs(inv, 1, nil)
	end,

	["invalid moves change nothing"] = function()
		local inv = Inventory.new(10)
		Inventory.add(inv, "wood", 5, 255)
		for _, pair in { { 0, 2 }, { 1, 11 }, { 3, 1 }, { 1, 1 }, { 1.5, 2 } } do
			local changed = Inventory.move(inv, pair[1], pair[2], maxOf(255))
			assert(#changed == 0, `mover {pair[1]}→{pair[2]} deveria ser ignorado`)
			slotIs(inv, 1, "wood", 5)
		end
	end,

	["capacity grows freely"] = function()
		local inv = Inventory.new(10)
		Inventory.add(inv, "wood", 5, 255)
		assert(#Inventory.move(inv, 1, 12, maxOf(255)) == 0, "slot 12 fora da capacidade")
		assert(Inventory.setCapacity(inv, 16) == true, "aumentar deveria funcionar")
		assert(#Inventory.move(inv, 1, 12, maxOf(255)) == 2, "slot 12 liberado")
	end,

	["capacity shrinks only when extra slots are empty"] = function()
		local inv = Inventory.new(16)
		inv.slots[14] = { id = "wood", count = 3 }
		assert(Inventory.setCapacity(inv, 10) == false, "slot 14 ocupado: não pode diminuir")
		assert(inv.capacity == 16, "capacidade não deveria mudar")
		inv.slots[14] = nil
		assert(Inventory.setCapacity(inv, 10) == true, "slots extras vazios: pode diminuir")
		assert(inv.capacity == 10, "capacidade deveria ser 10")
	end,

	["capacity formula adds bag and bonus"] = function()
		assert(Inventory.capacityFor(0, 0) == 10, "só a base")
		assert(Inventory.capacityFor(6, 0) == 16, "mochila de 6")
		assert(Inventory.capacityFor(6, 3) == 19, "mochila + bônus")
	end,

	["removeAt takes only from that slot"] = function()
		local inv = Inventory.new(10)
		Inventory.add(inv, "wood", 25, 10) -- slots 1, 2 (10 cada) e 3 (5)
		local ok, changed = Inventory.removeAt(inv, 1, 4)
		assert(ok == true, "deveria tirar 4 do slot 1")
		slotIs(inv, 1, "wood", 6)
		slotIs(inv, 2, "wood", 10)
		slotIs(inv, 3, "wood", 5)
		assert(sameSet(changed, { 1 }), "alterados deveria ser {1}")
		ok = Inventory.removeAt(inv, 3, 5)
		assert(ok == true, "deveria esvaziar o slot 3")
		slotIs(inv, 3, nil)
	end,

	["removeAt refuses bad requests without changing"] = function()
		local nan = 0 / 0
		local inv = Inventory.new(10)
		Inventory.add(inv, "wood", 5, 10)
		for _, bad in { 0, -1, 1.5, nan, math.huge, 6 } do
			local ok, changed = Inventory.removeAt(inv, 1, bad)
			assert(ok == false and #changed == 0, `quantidade {bad} não pode tirar`)
		end
		for _, index in { 0, 11, 1.5, nan, 2 } do
			local ok = Inventory.removeAt(inv, index, 1)
			assert(ok == false, `índice {index} não pode tirar`)
		end
		slotIs(inv, 1, "wood", 5)
	end,

	["spaceFor matches what add accepts"] = function()
		local inv = Inventory.new(3)
		Inventory.add(inv, "wood", 7, 10)
		Inventory.add(inv, "stone", 10, 10)
		local space = Inventory.spaceFor(inv, "wood", 10)
		assert(space == 13, `cabem 3 na pilha + 10 no slot vazio, veio {space}`)
		assert(Inventory.spaceFor(inv, "stone", 10) == 10, "pilha de pedra cheia: só o slot vazio")
		assert(inv.slots[1].count == 7 and inv.slots[3] == nil, "spaceFor não pode mudar nada")
		local rest = Inventory.add(inv, "wood", space + 4, 10)
		assert(rest == 4, `add deveria sobrar 4, sobrou {rest}`)
		assert(Inventory.spaceFor(inv, "wood", 10) == 0, "cheio")
	end,

	["capacity formula is capped"] = function()
		assert(Inventory.capacityFor(100, 100) == 40, "limite de 40 slots")
		assert(Inventory.capacityFor(-5, 0) == 10, "nunca abaixo da base")
	end,
}
