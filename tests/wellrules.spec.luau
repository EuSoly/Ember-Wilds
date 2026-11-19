--!strict
local WellRules = require("../src/shared/Build/WellRules")

-- Os números da wiki (poço dos Defs).
local WELL = { drinksPerBucket = 12, maxDrinks = 48, thirstPerDrink = 20, refillEvery = 30 }

local spec = {}

function spec.refill_junta_agua_com_o_tempo()
	local d, r = WellRules.refill(0, 30, WELL)
	assert(d == 1 and r == 0, `refill(0, 30) -> ({d}, {r})`)
	d, r = WellRules.refill(0, 75, WELL)
	assert(d == 2 and r == 15, `refill(0, 75) -> ({d}, {r})`)
	d, r = WellRules.refill(47, 120, WELL)
	assert(d == 48 and r == 0, `refill(47, 120) -> ({d}, {r})`)
	d, r = WellRules.refill(48, 999, WELL)
	assert(d == 48 and r == 0, `refill(48, 999) -> ({d}, {r})`)
end

function spec.balde_enche_12_goles()
	assert(WellRules.fill(0, WELL) == 12, "poço vazio + balde = 12")
	assert(WellRules.fill(12, WELL) == 24, "12 + 12 = 24")
end

function spec.teto_de_48()
	assert(WellRules.fill(40, WELL) == 48, "40 + 12 passaria de 48: fica em 48")
	assert(WellRules.fill(36, WELL) == 48, "36 + 12 = 48 exato")
end

function spec.poco_cheio_recusa_o_balde()
	assert(WellRules.fill(48, WELL) == nil, "cheio: nil")
end

function spec.poco_vazio_nao_da_gole()
	assert(WellRules.drink(0) == nil, "vazio: nil")
end

function spec.gole_tira_1()
	assert(WellRules.drink(12) == 11, "12 → 11")
	assert(WellRules.drink(1) == 0, "1 → 0")
end

function spec.botao_beber_so_com_agua_e_sede()
	assert(WellRules.canDrink(10, 50, 100), "tem água e sede")
	assert(not WellRules.canDrink(0, 50, 100), "poço vazio")
	assert(not WellRules.canDrink(10, 100, 100), "sede cheia")
end

function spec.botao_encher_so_com_balde_cheio_e_espaco()
	assert(WellRules.canFill("water_bucket", 10, WELL), "balde cheio e espaço")
	assert(not WellRules.canFill("bucket", 10, WELL), "balde vazio não enche")
	assert(not WellRules.canFill(nil, 10, WELL), "mão vazia")
	assert(not WellRules.canFill("water_bucket", WELL.maxDrinks, WELL), "poço cheio")
end

function spec.medidor_de_agua()
	assert(WellRules.fraction(24, WELL) == 0.5, "metade")
	assert(WellRules.fraction(0, WELL) == 0, "vazio")
	assert(WellRules.fraction(99, WELL) == 1, "nunca passa de cheio")
end

return spec
