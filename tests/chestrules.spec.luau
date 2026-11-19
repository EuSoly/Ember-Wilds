--!strict
local ChestRules = require("../src/shared/Build/ChestRules")

return {
	["pôr 3 tipos diferentes ocupa os 3 slots e o 4º devolve (0, nil)"] = function()
		assert(ChestRules.SLOTS == 3, "SLOTS = 3")
		local chest = ChestRules.new()
		assert(#chest == 3, "3 slots no baú")
		local put1, s1 = ChestRules.putAny(chest, "wood", 10)
		assert(put1 == 10 and s1 == 1, "madeira no slot 1")
		local put2, s2 = ChestRules.putAny(chest, "stone", 20)
		assert(put2 == 20 and s2 == 2, "pedra no slot 2")
		local put3, s3 = ChestRules.putAny(chest, "gold", 5)
		assert(put3 == 5 and s3 == 3, "ouro no slot 3")
		local put4, s4 = ChestRules.putAny(chest, "berry", 5)
		assert(put4 == 0 and s4 == nil, "4º tipo não entra")
	end,

	["pôr mais do mesmo tipo vai para o slot que já tem"] = function()
		local chest = ChestRules.new()
		ChestRules.putAny(chest, "wood", 10)
		ChestRules.putAny(chest, "stone", 20)
		local put, slot = ChestRules.putAny(chest, "stone", 15)
		assert(put == 15 and slot == 2, "pedra soma no slot 2")
		assert(chest[2].count == 35 and chest[3].id == nil, "slot 3 continua vazio")
	end,

	["takeAt num slot esvazia só ele e ignora slot fora de 1..3"] = function()
		local chest = ChestRules.new()
		ChestRules.putAny(chest, "wood", 10)
		ChestRules.putAny(chest, "stone", 20)
		ChestRules.putAny(chest, "gold", 5)
		local id, n = ChestRules.takeAt(chest, 2, 100)
		assert(id == "stone" and n == 20, "tirou toda a pedra do slot 2")
		assert(chest[2].id == nil and chest[2].count == 0, "slot 2 vazio")
		assert(chest[1].id == "wood" and chest[3].id == "gold", "slots 1 e 3 intactos")
		for _, bad in { 0, 4, -1, 1.5, 0 / 0 } do
			local bid, bn = ChestRules.takeAt(chest, bad, 10)
			assert(bid == nil and bn == 0, `slot inválido {bad}`)
		end
	end,

	["ChestRules.MAX = 9999 vale por slot"] = function()
		local chest = ChestRules.new()
		local put1, s1 = ChestRules.putAny(chest, "wood", 9990)
		assert(put1 == 9990 and s1 == 1, "9990 no slot 1")
		local put2, s2 = ChestRules.putAny(chest, "wood", 50)
		assert(put2 == 9 and s2 == 1, "corta em 9999 no slot 1")
		local put3, s3 = ChestRules.putAny(chest, "wood", 1)
		assert(put3 == 0 and s3 == nil, "slot 1 cheio não abre outra pilha do mesmo tipo")
		local putStone, sStone = ChestRules.putAny(chest, "stone", 9999)
		assert(putStone == 9999 and sStone == 2, "outro slot também vai até 9999")
	end,
}
