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
		assert(SpinRules.confettiFor(3, false) == 20, "normal épico com 20")
		assert(SpinRules.confettiFor(4, false) == 40 and SpinRules.confettiFor(5, false) == 70, "normal cresce")
		assert(SpinRules.confettiFor(9, false) == 70 and SpinRules.confettiFor(0, false) == 0, "fora da faixa")
	end,

	["revelação cresce com a raridade e Comum normal é discreto"] = function()
		local common = SpinRules.revealFor(1, false)
		assert(common.shake == 0 and common.flash == 0, "Comum normal sem tremida nem clarão")
		assert(not common.rays and not common.ring, "Comum normal sem raios nem anel")
		assert(common.hold > 0 and common.hold < 0.5, "espera curta no Comum")
		for _, paid in { false, true } do
			for r = 2, 5 do
				local low, high = SpinRules.revealFor(r - 1, paid), SpinRules.revealFor(r, paid)
				assert(high.hold >= low.hold, `espera caiu em {r}`)
				assert(high.shake >= low.shake, `tremida caiu em {r}`)
				assert(high.flash >= low.flash, `clarão caiu em {r}`)
			end
		end
		local mythic = SpinRules.revealFor(5, true)
		assert(mythic.hold <= 1, "ninguém espera mais de 1 s")
		assert(mythic.flash <= 0.8, "o clarão nunca cobre a tela toda")
		assert(mythic.rays and mythic.ring, "Mítico com tudo")
	end,

	["giro pago sempre tem raios, anel, tremida e clarão"] = function()
		local paid = SpinRules.revealFor(1, true)
		assert(paid.rays and paid.ring and paid.shake > 0 and paid.flash > 0, "pago Comum")
		assert(SpinRules.revealFor(2, false).rays and not SpinRules.revealFor(2, false).ring, "Raro normal: só raios")
		assert(SpinRules.revealFor(3, false).ring, "Épico normal: anel")
	end,

	["tique sobe de tom e de volume conforme o giro freia"] = function()
		assert(SpinRules.tickPitch(0, 1) == 1, "começo no tom normal")
		assert(SpinRules.tickPitch(1, 0) > 1, "sobe mesmo sem suspense")
		assert(SpinRules.tickPitch(1, 1) > SpinRules.tickPitch(1, 0), "sobe mais com suspense")
		assert(SpinRules.tickPitch(1, 1) <= 1.5, "sem ficar esganiçado")
		assert(SpinRules.tickPitch(2, 5) == SpinRules.tickPitch(1, 1), "fora da faixa")
		assert(SpinRules.tickVolume(0) < SpinRules.tickVolume(0.5), "volume cresce")
		assert(SpinRules.tickVolume(1) == 1 and SpinRules.tickVolume(3) == 1, "fim no volume cheio")
		assert(SpinRules.tickVolume(0) >= 0.4, "começo ainda audível")
	end,

	["tensão fica em zero no começo do giro e chega a 1 no fim"] = function()
		assert(SpinRules.tensionRamp(0) == 0, "começo")
		assert(SpinRules.tensionRamp(SpinRules.TENSION_START) == 0, "início da rampa")
		assert(SpinRules.tensionRamp(1) == 1, "fim")
		assert(SpinRules.tensionRamp(1.5) == 1, "passou do fim")
		assert(SpinRules.tensionRamp(-1) == 0, "antes do começo")
	end,

	["tensão só cresce e acelera perto do fim"] = function()
		local last = 0
		for i = 0, 20 do
			local t = SpinRules.tensionRamp(i / 20)
			assert(t >= last, `caiu em {i / 20}`)
			last = t
		end
		-- Curva (não reta): na metade da rampa ainda está abaixo da metade.
		local mid = SpinRules.TENSION_START + (1 - SpinRules.TENSION_START) / 2
		assert(SpinRules.tensionRamp(mid) < 0.5, "devia acelerar no fim")
	end,

	["featuredItem sorteia entre as míticas"] = function()
		local items = { item("a", 1), item("b", 5), item("c", 3), item("d", 5) }
		assert(SpinRules.featuredItem(items, 0).id == "b", "r=0 pega a primeira mítica")
		assert(SpinRules.featuredItem(items, 0.99).id == "d", "r alto pega a última mítica")
	end,

	["featuredItem sem mítica usa a mais rara que existir"] = function()
		local items = { item("a", 1), item("b", 3), item("c", 3) }
		assert(SpinRules.featuredItem(items, 0).id == "b", "raridade 3 é a maior")
		assert(SpinRules.featuredItem({ item("livro", 1) }, 0.5).id == "livro", "uma só")
	end,

	["featuredItem sem itens devolve nil"] = function()
		assert(SpinRules.featuredItem({}, 0.5) == nil, "lista vazia")
	end,

	["markerTile conta os quadradinhos que passaram pelo marcador"] = function()
		-- Janela de 400 (marcador em 200), passo de 100.
		assert(SpinRules.markerTile(0, 100, 400) == 2, "parado")
		assert(SpinRules.markerTile(-99, 100, 400) == 2, "quase passando")
		assert(SpinRules.markerTile(-101, 100, 400) == 3, "passou um")
		assert(SpinRules.markerTile(-1000, 100, 400) == 12, "longe")
	end,
	["spin button only while idle, with spins and no prize open"] = function()
		assert(SpinRules.canPress(1, false, false), "parado, com giro: pode")
		assert(not SpinRules.canPress(0, false, false), "sem giro: não")
		assert(not SpinRules.canPress(3, true, false), "girando: não")
		-- O bug de 10/11/2026: girar com o prêmio aberto, e o Pegar cortava o
		-- segundo giro no meio (a tela travava girando).
		assert(not SpinRules.canPress(3, false, true), "prêmio na tela: não")
	end,
}
