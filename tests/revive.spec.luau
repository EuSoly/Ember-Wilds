--!strict
local ReviveRules = require("../src/shared/Survival/ReviveRules")

return {
	["constantes da janela e da proteção"] = function()
		assert(ReviveRules.DECISION_SECONDS == 30, "30 s")
		assert(ReviveRules.PURCHASE_PAUSE_MAX == 60, "pausa 60 s")
		assert(ReviveRules.SHIELD_SECONDS == 3, "proteção 3 s")
	end,
	["price climbs and caps"] = function()
		assert(ReviveRules.offer(0, false, 0).robux == 25, "1º = 25")
		assert(ReviveRules.offer(1, false, 0).robux == 49, "2º = 49")
		assert(ReviveRules.offer(2, false, 0).robux == 99, "3º = 99")
		assert(ReviveRules.offer(3, false, 0).robux == 199, "4º = 199")
		assert(ReviveRules.offer(9, false, 0).robux == 199, "para no 199")
		assert(ReviveRules.offer(9, false, 0).step == 4, "degrau máximo 4")
		local paid = ReviveRules.offer(0, false, 0)
		assert(paid.free == false and paid.credit == false and paid.step == 1, "pago no degrau 1")
	end,
	["vip free takes the first step"] = function()
		local first = ReviveRules.offer(0, true, 0)
		assert(first.free == true, "grátis")
		assert(first.credit == false, "não é crédito")
		assert(first.step == 1, "degrau 1")
		-- O grátis ocupou o degrau 1: o próximo custa 49.
		local next = ReviveRules.offer(1, false, 0)
		assert(next.robux == 49 and next.free == false, "depois do grátis, 49")
	end,
	["credit is used first"] = function()
		local offer = ReviveRules.offer(2, false, 1)
		assert(offer.free == true and offer.credit == true, "crédito")
		-- Crédito vem antes do grátis do VIP (o grátis fica guardado).
		local vip = ReviveRules.offer(0, true, 2)
		assert(vip.free == true and vip.credit == true, "crédito antes do VIP")
	end,
	["window expires after 30s"] = function()
		assert(ReviveRules.expired(ReviveRules.open(0), 29.9) == false, "29,9 s aberta")
		assert(ReviveRules.expired(ReviveRules.open(0), 30) == true, "30 s expira")
	end,
	["pause stops the clock up to 60s"] = function()
		local p = ReviveRules.open(0)
		ReviveRules.pause(p, 10)
		ReviveRules.resume(p, 50)
		assert(ReviveRules.expired(p, 69) == false, "pausou 40 s: 69 ainda aberta")
		assert(ReviveRules.expired(p, 70) == true, "70 expira")

		local q = ReviveRules.open(0)
		ReviveRules.pause(q, 10)
		assert(ReviveRules.expired(q, 89.9) == false, "pausa sem fim: 89,9 aberta")
		assert(ReviveRules.expired(q, 90) == true, "pausa conta no máximo 60 s: 90 expira")
	end,
	["pause cap is for the whole window"] = function()
		local p = ReviveRules.open(0)
		ReviveRules.pause(p, 0)
		ReviveRules.resume(p, 40)
		ReviveRules.pause(p, 45)
		ReviveRules.resume(p, 100)
		-- 40 + 55 pausados, mas só 60 contam: expira em 90.
		assert(ReviveRules.expired(p, 89.9) == false, "89,9 aberta")
		assert(ReviveRules.expired(p, 90) == true, "90 expira")
	end,
	["pause twice and resume without pause are ignored"] = function()
		local p = ReviveRules.open(0)
		ReviveRules.resume(p, 5) -- sem pausa: nada
		ReviveRules.pause(p, 10)
		ReviveRules.pause(p, 20) -- já pausado: nada
		ReviveRules.resume(p, 30)
		assert(ReviveRules.expired(p, 49.9) == false, "pausou 20 s: 49,9 aberta")
		assert(ReviveRules.expired(p, 50) == true, "50 expira")
	end,
	["second answer is ignored"] = function()
		local p = ReviveRules.open(0)
		assert(ReviveRules.answer(p, true) == "revive", "1ª resposta vale")
		assert(ReviveRules.answer(p, false) == nil, "2ª ignorada")
		assert(ReviveRules.answer(p, true) == nil, "3ª ignorada")

		local q = ReviveRules.open(0)
		assert(ReviveRules.answer(q, false) == "decline", "recusa")
		assert(ReviveRules.answer(q, true) == nil, "depois da recusa nada")
	end,
	["leaving resolves as decline"] = function()
		local p = ReviveRules.open(0)
		assert(ReviveRules.onLeave(p) == "decline", "sem resposta: recusa")
		assert(ReviveRules.onLeave(p) == nil, "uma vez só")

		local q = ReviveRules.open(0)
		ReviveRules.answer(q, true)
		assert(ReviveRules.onLeave(q) == nil, "já respondido")
	end,
	["not eligible in creative, tutorial, without profile or items"] = function()
		assert(ReviveRules.eligible(false, false, true, true) == true, "elegível")
		assert(ReviveRules.eligible(true, false, true, true) == false, "criativo")
		assert(ReviveRules.eligible(false, true, true, true) == false, "tutorial")
		assert(ReviveRules.eligible(false, false, false, true) == false, "sem perfil")
		assert(ReviveRules.eligible(false, false, true, false) == false, "sem itens")
	end,
	["shield lasts until the given time"] = function()
		assert(ReviveRules.shielded(103, 102.9) == true, "dentro")
		assert(ReviveRules.shielded(103, 103) == false, "acabou")
		assert(ReviveRules.shielded(nil, 0) == false, "sem atributo")
		assert(ReviveRules.shielded("x", 0) == false, "valor estranho")
	end,
	["ember bonus bits"] = function()
		assert(ReviveRules.emberBonus({ ember2x = false, vip = false, premium = false }) == 0, "nada")
		assert(ReviveRules.emberBonus({ ember2x = true, vip = false, premium = false }) == 1, "2×")
		assert(ReviveRules.emberBonus({ ember2x = false, vip = true, premium = false }) == 2, "VIP")
		assert(ReviveRules.emberBonus({ ember2x = false, vip = false, premium = true }) == 4, "Premium")
		assert(ReviveRules.emberBonus({ ember2x = true, vip = true, premium = true }) == 7, "todos")
	end,
}
