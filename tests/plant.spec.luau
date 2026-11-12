--!strict
-- Crescimento das plantas (PlantRules): rega, crescer, frutos, estágio,
-- colher, velhice e onde a semente pode ir.
local Defs = require("../src/shared/Defs")
local PlantRules = require("../src/shared/Farm/PlantRules")

local BERRY = (Defs.Items.berry_seed.structure :: any).plant :: Defs.PlantDef

local function near(a: number, b: number, what: string)
	assert(math.abs(a - b) < 1e-6, `{what}: {a} ~= {b}`)
end

local spec = {}

function spec.nasce_seca_e_nao_cresce_sem_agua()
	local plant = PlantRules.new(0)
	local water = PlantRules.newWater()
	assert(not PlantRules.isWet(water, 0), "nasce seca")
	PlantRules.step(plant, BERRY, 100, 100, water, false)
	assert(plant.grown == 0, "seca não cresce")
	assert(PlantRules.stage(plant) == 1, "estágio 1")
end

function spec.regada_cresce_no_tempo_da_config()
	local plant = PlantRules.new(0)
	local water = PlantRules.newWater()
	PlantRules.water(water, BERRY, 0, nil)
	assert(PlantRules.isWet(water, 199) and not PlantRules.isWet(water, 200), "rega dura 200 s")
	PlantRules.step(plant, BERRY, 20, 20, water, false)
	near(plant.grown, 0.5, "metade em 20 s")
	assert(PlantRules.stage(plant) == 2, "estágio 2 na metade")
	PlantRules.step(plant, BERRY, 40, 20, water, false)
	assert(plant.grown == 1 and PlantRules.stage(plant) == 4, "madura em 40 s")
end

function spec.canteiro_dobra_a_velocidade()
	local plant = PlantRules.new(0)
	local water = PlantRules.newWater()
	PlantRules.water(water, BERRY, 0, nil)
	PlantRules.step(plant, BERRY, 20, 20, water, true)
	assert(plant.grown == 1, "no canteiro, 40 s viram 20")
end

function spec.tunica_de_quem_regou_acelera()
	local plant = PlantRules.new(0)
	local water = PlantRules.newWater()
	PlantRules.water(water, BERRY, 0, 1.4)
	PlantRules.step(plant, BERRY, 10, 10, water, false)
	near(plant.grown, 10 * 1.4 / 40, "túnica de inverno: 1,4x")
	-- Rega sem túnica volta ao normal.
	PlantRules.water(water, BERRY, 10, nil)
	PlantRules.step(plant, BERRY, 20, 10, water, false)
	near(plant.grown, (14 + 10) / 40, "depois, 1x")
end

function spec.so_conta_o_tempo_molhado()
	local plant = PlantRules.new(0)
	local water = PlantRules.newWater()
	PlantRules.water(water, BERRY, 0, nil)
	-- Passo de 300 s com só 200 s de água: cresce tudo (40 s) e os frutos só nos 160 s molhados.
	PlantRules.step(plant, BERRY, 300, 300, water, false)
	assert(plant.grown == 1, "madura")
	assert(plant.fruit == 1, `1 fruto em 160 s molhados (120 s cada): {plant.fruit}`)
	near(plant.fruitProgress, 40 / 120, "resto do progresso")
end

function spec.frutos_param_no_maximo()
	local plant = PlantRules.new(0)
	local water = PlantRules.newWater()
	local t = 0
	for _ = 1, 20 do
		PlantRules.water(water, BERRY, t, nil)
		t += 100
		PlantRules.step(plant, BERRY, t, 100, water, false)
	end
	assert(plant.fruit == BERRY.maxFruit, `para em {BERRY.maxFruit}: {plant.fruit}`)
	assert(plant.fruitProgress == 0, "cheia não acumula")
end

function spec.colher_tira_frutos()
	local plant = PlantRules.new(0)
	plant.grown = 1
	plant.fruit = 3
	assert(PlantRules.harvest(plant, 2) == 2 and plant.fruit == 1, "forcado: 2")
	assert(PlantRules.harvest(plant, 2) == 1 and plant.fruit == 0, "só o que tem")
	assert(PlantRules.harvest(plant, 1) == 0, "sem fruto: nada")
end

function spec.colheita_por_golpe()
	assert(PlantRules.harvestOf(nil) == 1, "mão: 1")
	assert(PlantRules.harvestOf(Defs.Items.pitchfork) == 2, "forcado: 2")
	assert(PlantRules.harvestOf(Defs.Items.gold_pitchfork) == 3, "forcado de ouro: 3")
	assert(PlantRules.harvestOf(Defs.Items.stone_shovel) == 1, "outra ferramenta: 1")
end

function spec.morre_de_velhice()
	local plant = PlantRules.new(100)
	assert(not PlantRules.isDead(plant, BERRY, 100 + 3839), "ainda viva")
	assert(PlantRules.isDead(plant, BERRY, 100 + 3840), "8 dias: morre")
end

function spec.espinho_so_machuca_maduro()
	local plant = PlantRules.new(0)
	assert(not PlantRules.hurts(plant), "broto não machuca")
	plant.grown = 1
	assert(PlantRules.hurts(plant), "maduro machuca")
end

function spec.semente_vai_no_canteiro_mais_perto()
	local plots = { { x = 0, z = 0, radius = 3.2 }, { x = 6.4, z = 0, radius = 3.2 } }
	assert(PlantRules.plotAt(1, 1, plots) == 1, "dentro do primeiro")
	assert(PlantRules.plotAt(4, 0, plots) == 2, "mais perto do segundo")
	assert(PlantRules.plotAt(0, 10, plots) == nil, "fora dos dois")
end

function spec.semente_no_chao_so_na_floresta()
	assert(PlantRules.groundAllows(false, false, true), "chão da floresta")
	assert(not PlantRules.groundAllows(true, false, true), "água não")
	assert(not PlantRules.groundAllows(false, true, true), "areia não")
	assert(not PlantRules.groundAllows(false, false, false), "fora do mapa não")
end

return spec
