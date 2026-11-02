--!strict
local Defs = require("../src/shared/Defs")
local HeldItem = require("../src/shared/HeldItem")

return {
	["weapons slow the player, hands and tools do not"] = function()
		assert(HeldItem.speedFactor(nil) == 1, "mão")
		assert(HeldItem.speedFactor(Defs.Items.gold_pickaxe) == 1, "picareta")
		assert(HeldItem.speedFactor(Defs.Items.wood_sword) == 0.75, "espada")
		assert(HeldItem.speedFactor(Defs.Items.gold_spear) == 0.75, "lança")
	end,

	["only spears reach farther"] = function()
		assert(HeldItem.reach(nil) == 0, "mão")
		assert(HeldItem.reach(Defs.Items.stone_sword) == 0, "espada")
		assert(HeldItem.reach(Defs.Items.stone_spear) == 3, "lança")
	end,

	["a fresh weapon stays in the hand until equipLock ends"] = function()
		local sword = Defs.Items.gold_sword
		assert(HeldItem.isLocked(sword, 104, 100), "dentro do prazo")
		assert(not HeldItem.isLocked(sword, 104, 104), "venceu")
		assert(not HeldItem.isLocked(sword, nil, 100), "sem atributo")
		assert(not HeldItem.isLocked(sword, 0 / 0, 100), "NaN")
		assert(not HeldItem.isLocked(Defs.Items.gold_pickaxe, 104, 100), "picareta não trava")
		assert(not HeldItem.isLocked(nil, 104, 100), "mão não trava")
	end,

	["mob speeds fit the player speeds"] = function()
		-- Jogador 16 de mão ou picareta, 12 armado (espada/lança: 0,75).
		local free, armed = 16, 16 * Defs.Items.gold_sword.moveSpeed :: number
		local function speed(id: string): number
			return (Defs.Mobs[id].stats :: any).speed
		end
		assert(speed("rabbit") < free and speed("rabbit") > armed, "coelho: alcança desarmado, foge do armado")
		for _, id in { "wolf", "spider" } do
			assert(speed(id) < free and speed(id) > armed, `{id}: foge desarmado, é alcançado armado`)
		end
	end,
}
