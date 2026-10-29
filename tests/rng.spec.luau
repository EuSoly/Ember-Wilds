--!strict
local Rng = require("../src/shared/World/Rng")

return {
	["same seed gives the same sequence"] = function()
		local a, b = Rng.new(20261029), Rng.new(20261029)
		for i = 1, 100 do
			assert(a:nextNumber() == b:nextNumber(), `sequências diferentes no passo {i}`)
		end
	end,

	["near seeds give different sequences"] = function()
		local a, b = Rng.new(20261029), Rng.new(20261030)
		local same = 0
		for _ = 1, 20 do
			if math.abs(a:nextNumber() - b:nextNumber()) < 0.01 then
				same += 1
			end
		end
		assert(same < 5, `sementes vizinhas parecidas demais ({same} de 20)`)
	end,

	["numbers stay in range"] = function()
		local rng = Rng.new(0)
		local seen: { [number]: boolean } = {}
		for _ = 1, 2000 do
			local n = rng:nextNumber()
			assert(n >= 0 and n < 1, `nextNumber fora de [0, 1): {n}`)
			local i = rng:nextInteger(1, 3)
			assert(i == 1 or i == 2 or i == 3, `nextInteger fora de [1, 3]: {i}`)
			seen[i] = true
		end
		assert(seen[1] and seen[2] and seen[3], "nextInteger deveria sortear 1, 2 e 3")
	end,

	["negative and huge seeds work"] = function()
		for _, seed in { -5, 2 ^ 40, 2147483646, 2147483647 } do
			local n = Rng.new(seed):nextNumber()
			assert(n >= 0 and n < 1, `semente {seed} deu {n}`)
		end
	end,
}
