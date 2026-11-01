--!strict
local ChestRules = require("../src/shared/Build/ChestRules")

local spec = {}

function spec.alcance()
	assert(ChestRules.RANGE == 8 and ChestRules.MAX == 9999, "constantes do baú")
end

function spec.vazio_aceita_qualquer()
	local c: ChestRules.Contents = { id = nil, count = 0 }
	assert(ChestRules.canPut(c, "wood", 50) == 50, "vazio aceita")
	assert(ChestRules.put(c, "wood", 50) == 50, "put devolve o que entrou")
	assert(c.id == "wood" and c.count == 50, "baú deveria ter 50 wood")
end

function spec.outro_tipo_nao_entra()
	local c: ChestRules.Contents = { id = "wood", count = 5 }
	assert(ChestRules.canPut(c, "stone", 3) == 0, "outro tipo não cabe")
	assert(ChestRules.put(c, "stone", 3) == 0, "put de outro tipo devolve 0")
	assert(c.id == "wood" and c.count == 5, "baú não pode mudar")
end

function spec.teto_corta()
	local c: ChestRules.Contents = { id = "wood", count = 9990 }
	assert(ChestRules.canPut(c, "wood", 50) == 9, "só cabem 9")
	assert(ChestRules.put(c, "wood", 50) == 9, "put corta no teto")
	assert(c.count == 9999, "baú cheio")
	assert(ChestRules.canPut(c, "wood", 1) == 0, "cheio não aceita")
end

function spec.take_parcial_e_total()
	local c: ChestRules.Contents = { id = "wood", count = 10 }
	local id, n = ChestRules.take(c, 4)
	assert(id == "wood" and n == 4 and c.count == 6 and c.id == "wood", "take parcial")
	id, n = ChestRules.take(c, 100)
	assert(id == "wood" and n == 6, "take total devolve o que havia")
	assert(c.id == nil and c.count == 0, "esvaziou: id volta a nil")
	id, n = ChestRules.take(c, 1)
	assert(id == nil and n == 0, "take de baú vazio")
end

function spec.contagens_invalidas_nao_movem_nada()
	local nan = 0 / 0
	for _, bad in { 0, -3, 1.5, nan, math.huge } do
		local c: ChestRules.Contents = { id = "wood", count = 10 }
		assert(ChestRules.canPut(c, "wood", bad) == 0, `canPut {bad}`)
		assert(ChestRules.put(c, "wood", bad) == 0, `put {bad}`)
		local id, n = ChestRules.take(c, bad)
		assert(id == nil and n == 0, `take {bad}`)
		assert(c.id == "wood" and c.count == 10, `baú mudou com {bad}`)
	end
end

-- Dois pedidos de pôr seguidos (dois jogadores no mesmo baú) perto do teto:
-- o segundo só leva o que sobrou, e o total nunca passa de MAX.
spec["two puts never exceed max"] = function()
	local c: ChestRules.Contents = { id = "wood", count = ChestRules.MAX - 15 }
	local first = ChestRules.put(c, "wood", 10)
	local second = ChestRules.put(c, "wood", 10)
	assert(first == 10, `primeiro põe 10, pôs {first}`)
	assert(second == 5, `segundo só cabe 5, pôs {second}`)
	assert(c.count == ChestRules.MAX, `baú deveria estar no teto, tem {c.count}`)
	assert(ChestRules.put(c, "wood", 1) == 0 and c.count == ChestRules.MAX, "cheio não passa do teto")
end

return spec
