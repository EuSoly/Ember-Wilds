--!strict
-- Fazenda (12/11): canteiro, sementes das 9 culturas, frutos, regador e
-- forcados, com os números da config oficial do Starve.
local Defs = require("../src/shared/Defs")

-- cultura: { cresce, fruto a cada, rega dura, vive, máx., fruto colhido, receita, pontos da semente }
local CROPS = {
	berry = { 40, 120, 200, 3840, 5, "berry", 3, 11 },
	wheat = { 16, 120, 200, 3840, 3, "wheat", 3, 11 },
	pumpkin = { 50, 160, 250, 3840, 1, "pumpkin", 8, 18 },
	carrot = { 30, 240, 200, 3840, 3, "carrot", 8, 18 },
	tomato = { 30, 240, 200, 3840, 3, "tomato", 8, 18 },
	watermelon = { 180, 240, 200, 2880, 1, "watermelon", 16, 26 },
	garlic = { 120, 240, 200, 3840, 3, "garlic", 8, 18 },
	aloe_vera = { 200, 240, 200, 3840, 1, "aloe_vera", 16, 26 },
	thornbush = { 15, 240, 240, 3840, 1, "thornbush", 8, 18 },
}

local PUBLIC = { berry_seed = true, plot = true, watering_can = true, watering_can_full = true, pitchfork = true }

local function counts(recipeId: string): { [string]: number }
	local recipe = Defs.Recipes[recipeId]
	assert(recipe ~= nil, `sem receita: {recipeId}`)
	local out = {}
	for _, part in recipe.ingredients do
		out[part.id] = part.count
	end
	return out
end

return {
	["every crop has a seed with the starve numbers"] = function()
		for crop, n in CROPS do
			local seed = Defs.Items[crop .. "_seed"]
			assert(seed ~= nil, `falta a semente de {crop}`)
			assert(seed.category == "placeable", `{crop}: semente é colocável`)
			local structure = seed.structure
			assert(structure and structure.kind == "plant", `{crop}: kind plant`)
			local plant = structure.plant
			assert(plant ~= nil, `{crop}: bloco plant`)
			assert(plant.crop == crop, `{crop}: crop`)
			assert(plant.growSeconds == n[1], `{crop}: cresce {n[1]}`)
			assert(plant.fruitSeconds == n[2], `{crop}: fruto a cada {n[2]}`)
			assert(plant.waterSeconds == n[3], `{crop}: rega {n[3]}`)
			assert(plant.lifeSeconds == n[4], `{crop}: vive {n[4]}`)
			assert(plant.maxFruit == n[5], `{crop}: máx. {n[5]}`)
			assert(plant.fruit == n[6] and Defs.Items[n[6]] ~= nil, `{crop}: colhe {n[6]}`)
			assert(plant.fruitPoints == math.floor(n[8] / 3 + 0.5), `{crop}: pontos do fruto`)
			local recipe = Defs.Recipes[crop .. "_seed"]
			assert(recipe and recipe.station == "fire" and recipe.time == 5, `{crop}: semente perto do fogo, 5 s`)
			assert(counts(crop .. "_seed")[n[6]] == n[7], `{crop}: {n[7]} frutos na receita`)
		end
	end,

	["only the berry seed is public"] = function()
		for crop in CROPS do
			local id = crop .. "_seed"
			assert((Defs.Items[id].testOnly ~= true) == (PUBLIC[id] == true), `{id}: público?`)
			local fruit = Defs.Items[CROPS[crop][6]]
			if crop ~= "berry" then
				assert(fruit.testOnly == true, `{fruit.id}: fruto de teste`)
			end
		end
		for id in PUBLIC do
			assert(Defs.Items[id] and Defs.Items[id].testOnly ~= true, `{id} devia ser público`)
		end
		assert(Defs.Items.gold_pitchfork.testOnly == true, "forcado de ouro segue de teste")
	end,

	["new fruits"] = function()
		local food = {
			pumpkin = { 30, nil },
			carrot = { 20, nil },
			tomato = { 16, nil },
			watermelon = { 15, 8 },
			garlic = { 14, nil },
		}
		for id, n in food do
			local item = Defs.Items[id]
			assert(item.category == "food" and item.food, `{id}: comida`)
			assert(item.food.hunger == n[1] and item.food.thirst == n[2], `{id}: fome/sede`)
		end
		local aloe = Defs.Items.aloe_vera
		assert(aloe.category == "food" and aloe.food and aloe.food.health == 15, "babosa cura 15")
		assert(Defs.Items.wheat.category == "resource" and Defs.Items.thornbush.category == "resource", "recursos")
	end,

	["plot and tools"] = function()
		local plot = Defs.Items.plot
		assert(plot.category == "placeable" and plot.structure, "canteiro colocável")
		assert(plot.structure.kind == "plot" and plot.structure.health == 3500, "canteiro: vida 3500")
		assert(plot.structure.snap == true, "canteiro encaixa em grade")
		local plotCost = counts("plot")
		assert(plotCost.wood == 20 and plotCost.ground == 15, "canteiro: 20 madeiras + 15 terras")
		assert(Defs.Recipes.plot.station == "workbench", "canteiro na bancada")
		assert(counts("watering_can").wood == 50, "regador: 50 madeiras")
		local can, full = Defs.Items.watering_can, Defs.Items.watering_can_full
		assert(can.waters ~= true and full.waters == true, "só o cheio rega")
		assert(Defs.Items.pitchfork.harvest == 2 and Defs.Items.gold_pitchfork.harvest == 3, "forcados")
		local thorn = Defs.Items.thornbush_seed.structure
		assert(thorn and thorn.spikeDamage == 20, "arbusto de espinho machuca 20")
	end,

	["tunics speed up crops"] = function()
		assert(Defs.Items.peasant.armor and Defs.Items.peasant.armor.cropGrowth == 1.2, "túnica 1,2")
		assert(
			Defs.Items.winter_peasant.armor and Defs.Items.winter_peasant.armor.cropGrowth == 1.4,
			"túnica de inverno 1,4"
		)
	end,
}
