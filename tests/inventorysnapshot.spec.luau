--!strict
local Inventory = require("../src/shared/Inventory")
local InventorySnapshot = require("../src/shared/InventorySnapshot")

return {
	["copy is deep"] = function()
		local inv = Inventory.new(10)
		inv.slots[1] = { id = "wood", count = 5 }
		inv.slots[4] = { id = "stone", count = 2 }
		local snap = InventorySnapshot.copy(inv, "bag_leather", "wolf_hat", 4)
		inv.slots[1].count = 99
		inv.slots[4] = nil
		inv.slots[2] = { id = "berry", count = 1 }
		inv.capacity = 15
		assert(snap.capacity == 10, `capacidade da cópia mudou: {snap.capacity}`)
		assert(snap.slots[1].id == "wood" and snap.slots[1].count == 5, "slot 1 da cópia mudou")
		assert(snap.slots[4] ~= nil and snap.slots[4].id == "stone", "slot 4 da cópia sumiu")
		assert(snap.slots[2] == nil, "slot 2 apareceu na cópia")
		assert(snap.bag == "bag_leather" and snap.armor == "wolf_hat" and snap.selected == 4, "extras errados")
	end,

	["apply does not alias the snapshot"] = function()
		local inv = Inventory.new(10)
		inv.slots[3] = { id = "wood", count = 7 }
		local snap = InventorySnapshot.copy(inv, nil, nil, 1)
		local target = Inventory.new(10)
		InventorySnapshot.apply(target, snap)
		target.slots[3].count = 1
		assert(snap.slots[3].count == 7, "mexer no inventário recriado mudou a cópia")
	end,

	["apply puts every slot back at the same index"] = function()
		local inv = Inventory.new(10)
		inv.slots[2] = { id = "wood", count = 3 }
		inv.slots[9] = { id = "stone", count = 4 }
		local snap = InventorySnapshot.copy(inv, nil, nil, 9)
		local target = Inventory.new(10)
		target.slots[1] = { id = "berry", count = 1 } -- o que havia antes some
		InventorySnapshot.apply(target, snap)
		assert(target.slots[1] == nil, "slot 1 devia ficar vazio")
		assert(target.slots[2].id == "wood" and target.slots[2].count == 3, "slot 2 errado")
		assert(target.slots[9].id == "stone" and target.slots[9].count == 4, "slot 9 errado")
	end,

	["restore keeps slots beyond base capacity"] = function()
		local inv = Inventory.new(23)
		inv.slots[22] = { id = "wood", count = 10 }
		local snap = InventorySnapshot.copy(inv, "bag_leather", nil, 1)
		assert(snap.capacity == 23, "a cópia devia guardar a capacidade 23")
		local target = Inventory.new(10)
		assert(Inventory.setCapacity(target, 23), "setCapacity(23) falhou")
		InventorySnapshot.apply(target, snap)
		assert(target.capacity >= 23, `capacidade caiu para {target.capacity}`)
		assert(target.slots[22] ~= nil and target.slots[22].id == "wood", "slot 22 sumiu")
	end,

	["apply raises capacity instead of dropping items"] = function()
		local inv = Inventory.new(23)
		inv.slots[23] = { id = "stone", count = 1 }
		local snap = InventorySnapshot.copy(inv, nil, nil, 1)
		local target = Inventory.new(10)
		InventorySnapshot.apply(target, snap)
		assert(target.capacity == 23, `capacidade devia subir para 23, ficou {target.capacity}`)
		assert(target.slots[23] ~= nil, "slot 23 sumiu")
	end,
}
