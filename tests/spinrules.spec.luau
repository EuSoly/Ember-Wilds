--!strict
local SpinRules = require("../src/shared/UIFlow/SpinRules")

local function item(id: string, rarity: number)
	return { id = id, nameKey = "x", rarity = rarity, color = "#FFFFFF" }
end

return {
	["pickIndex devolve o índice certo nas bordas"] = function()
		local w = { 50, 30, 20 }
		assert(SpinRules.pickIndex(w, 0) == 1, "r=0")
		assert(SpinRules.pickIndex(w, 0.4999) == 1, "r logo abaixo de 0.5")
		assert(SpinRules.pickIndex(w, 0.5) == 2, "r=0.5")
		assert(SpinRules.pickIndex(w, 0.7999) == 2, "r logo abaixo de 0.8")
		assert(SpinRules.pickIndex(w, 0.8) == 3, "r=0.8")
		assert(SpinRules.pickIndex(w, 0.999999) == 3, "r=0.999999")
	end,

	["pickIndex nunca passa do último índice"] = function()
		assert(SpinRules.pickIndex({ 50, 49.99999 }, 0.9999999) == 2, "caiu fora da lista")
	end,

	["pickItem só devolve a raridade pedida"] = function()
		local items = { item("a", 1), item("b", 2), item("c", 2), item("d", 6) }
		for _, r in { 0, 0.3, 0.6, 0.99 } do
			assert(SpinRules.pickItem(items, 2, r).rarity == 2, `r={r}`)
		end
		assert(
			SpinRules.pickItem(items, 2, 0).id == "b" and SpinRules.pickItem(items, 2, 0.99).id == "c",
			"escolha pelo r"
		)
	end,

	["pickItem sem a raridade desce até achar"] = function()
		local items = { item("a", 1), item("b", 3) }
		assert(SpinRules.pickItem(items, 6, 0.5).id == "b", "devia descer para a raridade 3")
		assert(SpinRules.pickItem({ item("a", 1) }, 6, 0.5).id == "a", "devia descer até a 1")
	end,

	["pickItem sem nada abaixo sobe até achar"] = function()
		-- Tipo cujos itens começam no Raro: um sorteio de Comum não pode travar.
		local items = { item("b", 3), item("c", 5) }
		assert(SpinRules.pickItem(items, 1, 0.5).id == "b", "devia subir para a raridade 3")
	end,

	["contadores somam por tipo e tipo de giro sem mutar"] = function()
		local c0 = SpinRules.newCounts()
		local c1 = SpinRules.addSpins(c0, "book", "paid", 3)
		local c2 = SpinRules.addSpins(c1, "book", "normal", 1)
		assert(c1.book.paid == 3 and c1.book.normal == 0, "soma do pago")
		assert(c2.book.normal == 1 and c2.book.paid == 3, "soma do normal")
		assert(c0.book == nil, "mudou o estado antigo")
		assert(SpinRules.canSpin(c2, "book", "paid") and not SpinRules.canSpin(c2, "bag", "paid"), "canSpin")
	end,

	["useSpin gasta um e nunca fica negativo"] = function()
		local c = SpinRules.addSpins(SpinRules.newCounts(), "bag", "normal", 1)
		local used = SpinRules.useSpin(c, "bag", "normal")
		assert(used.bag.normal == 0 and c.bag.normal == 1, "gastou e não mutou")
		local again = SpinRules.useSpin(used, "bag", "normal")
		assert(again.bag.normal == 0, "ficou negativo")
		assert(not SpinRules.canSpin(again, "bag", "normal"), "não devia poder girar")
	end,

	["canAfford"] = function()
		assert(SpinRules.canAfford(100, 100), "igual paga")
		assert(not SpinRules.canAfford(99, 100), "menor não paga")
		assert(not SpinRules.canAfford(0 / 0, 1), "NaN")
		assert(not SpinRules.canAfford(math.huge, 1), "infinito")
	end,

	["confete por raridade"] = function()
		local paid = {}
		for r = 1, 5 do
			table.insert(paid, SpinRules.confettiFor(r, true))
		end
		assert(table.concat(paid, ",") == "20,35,60,100,150", table.concat(paid, ","))
		assert(
			SpinRules.confettiFor(1, false) == 0 and SpinRules.confettiFor(2, false) == 0,
			"normal comum/incomum sem confete"
		)
		assert(SpinRules.confettiFor(3, false) == 20 and SpinRules.confettiFor(5, false) == 20, "normal épico+ com 20")
	end,
}
