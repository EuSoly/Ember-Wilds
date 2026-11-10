--!strict
-- As 32 peças de cabeça do pacote do Blender (assets/armor/roblox/manifest.json)
-- e os materiais que as receitas do Starve pedem.
local Defs = require("../src/shared/Defs")

local PIECES = {
	"wood_helmet",
	"stone_helmet",
	"gold_helmet",
	"diamond_helmet",
	"amethyst_helmet",
	"reidite_helmet",
	"dragon_helmet",
	"crab_helmet",
	"lava_helmet",
	"earmuffs",
	"coat",
	"winter_hat",
	"fur_hat",
	"turban",
	"ninja",
	"pilot",
	"diamond_protection",
	"amethyst_protection",
	"reidite_protection",
	"explorer",
	"hood",
	"winter_hood",
	"peasant",
	"winter_peasant",
	"diving_mask",
	"diving_suit",
	"witch",
	"santa",
	"elf",
	"life_crown",
	"angel_crown",
	"luck_crown",
}

-- Liberadas para o jogador (decisão do Elizeu, 10/11): materiais e sistemas existem.
local RELEASED = {
	wood_helmet = true,
	stone_helmet = true,
	gold_helmet = true,
	earmuffs = true,
	coat = true,
	turban = true,
	explorer = true,
	hood = true,
	peasant = true,
}

local MATERIALS = {
	"diamond",
	"amethyst",
	"winter_fur",
	"mammoth_fur",
	"penguin_feather",
	"vulture_feather",
	"kraken_skin",
	"piranha_scales",
	"flame",
	"dragon_heart",
	"lava_heart",
	"crab_claws",
	"crab_sticks",
	"blue_thread",
	"green_gem",
	"blue_gem",
	"orange_gem",
	"blue_cube",
	"lava_cube",
	"pilot_glasses",
	"black_wolf_fur",
	"white_wolf_fur",
	"firefly",
}

local function armorOf(id: string): any
	local def = Defs.Items[id]
	assert(def ~= nil, `falta o item {id}`)
	assert(def.armor ~= nil, `{id} sem bloco armor`)
	return def.armor
end

return {
	["armor pieces match the Blender pack"] = function()
		local expected = {}
		for _, id in PIECES do
			expected[id] = true
			local def = Defs.Items[id]
			assert(def ~= nil, `falta a peça {id}`)
			assert(def.category == "armor" and def.maxStack == 1, `{id}: armor com maxStack 1`)
		end
		for id, def in Defs.Items do
			if def.category == "armor" then
				assert(expected[id], `{id} é armadura mas não está no pacote`)
			end
		end
	end,

	["armor release list"] = function()
		for _, id in PIECES do
			local released = Defs.Items[id].testOnly ~= true
			assert(released == (RELEASED[id] == true), `{id}: liberado = {released}`)
		end
		for _, id in MATERIALS do
			local def = Defs.Items[id]
			assert(def ~= nil, `falta o material {id}`)
			assert(def.testOnly == true, `{id} devia ser testOnly`)
		end
	end,

	["starve numbers spot check"] = function()
		local lava = armorOf("lava_helmet")
		assert(lava.defense == 9 and lava.mobDefense == 30, "capacete de lava 9/30")
		local angel = armorOf("angel_crown")
		assert(angel.defense == 2 and angel.mobDefense == 16, "coroa do anjo 2/16")
		local fur = armorOf("fur_hat")
		assert(fur.warm.day == 3 and fur.warm.night == 17, "chapéu de pele 3/17")
		local suit = armorOf("diving_suit")
		assert(suit.oxygenLoss == 19 and suit.swimSpeed == 1.2, "roupa de mergulho")
		assert(armorOf("diamond_protection").fireHeatFactor == 0, "proteção anula o fogo")
		assert(armorOf("hood").hidesName == true, "capuz esconde o nome")
		assert(armorOf("winter_hood").hidesName == true, "capuz de inverno esconde o nome")
		assert(armorOf("explorer").explorer == true, "explorador")
		assert(armorOf("life_crown").regenHeal == 40, "coroa da vida")
		assert(armorOf("coat").warm.day == 2 and armorOf("coat").warm.night == 13, "casaco 2/13")
	end,

	["armor recipes"] = function()
		for _, id in PIECES do
			local recipe = Defs.Recipes[id]
			if id == "santa" or id == "elf" then
				assert(recipe == nil, `{id} sai do presente de Natal, sem receita`)
			else
				assert(recipe ~= nil and recipe.result == id, `{id} sem receita`)
			end
		end
		local reidite = Defs.Recipes.reidite_helmet
		assert(reidite.station == "workbench", "reidite na bancada")
		assert(reidite.alsoNear and #reidite.alsoNear == 1 and reidite.alsoNear[1] == "fire", "e no fogo")
		local crown = Defs.Recipes.life_crown
		assert(crown.alsoNear and #crown.alsoNear == 2, "coroa: fogo e água")
		assert(crown.alsoNear[1] == "fire" and crown.alsoNear[2] == "water", "ordem fogo, água")
		local explorer = Defs.Recipes.explorer
		local counts = {}
		for _, part in explorer.ingredients do
			counts[part.id] = part.count
		end
		assert(counts.paper == 1 and counts.rabbit_fur == 1 and counts.thread == 2, "explorador do Starve")
		assert(explorer.station == "workbench" and explorer.time == 5, "bancada, 5 s")
		local blue = Defs.Recipes.blue_thread
		assert(blue and blue.time == 3 and #blue.ingredients == 2, "linha azul: diamante + linha, 3 s")
	end,

	["released recipes only use released items"] = function()
		for _, recipe in Defs.Recipes do
			local result = Defs.Items[recipe.result]
			if result and result.testOnly ~= true then
				for _, part in recipe.ingredients do
					local item = Defs.Items[part.id]
					assert(item and item.testOnly ~= true, `{recipe.id} liberado usa {part.id} (só teste)`)
				end
			end
		end
	end,

	["crab food"] = function()
		local sticks = Defs.Items.crab_sticks
		local claws = Defs.Items.crab_claws
		assert(sticks.category == "food" and sticks.food and sticks.food.hunger == 20, "palito de caranguejo")
		assert(claws.category == "food" and claws.food and claws.food.hunger == 10, "garra de caranguejo")
	end,
}
