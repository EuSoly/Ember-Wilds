--!strict
local WellRules = require("../src/shared/Build/WellRules")

-- Os números da wiki (poço dos Defs).
local WELL = { drinksPerBucket = 12, maxDrinks = 48, thirstPerDrink = 20 }

local spec = {}

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

return spec
