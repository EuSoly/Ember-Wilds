--!strict
-- Receitas do jogo (números do spec da G3). `order` é a posição no livro de receitas.
local Types = require("./Types")

type RecipeDef = Types.RecipeDef
local function ingredient(id: string, count: number): Types.RecipeIngredient
	return table.freeze({ id = id, count = count })
end

local function recipe(
	id: string,
	count: number,
	items: { Types.RecipeIngredient },
	time: number,
	station: Types.CraftStation?,
	order: number
): RecipeDef
	table.freeze(items)
	return table.freeze({
		id = id,
		result = id,
		count = count,
		ingredients = items,
		time = time,
		station = station,
		order = order,
	})
end

local Recipes: { [string]: RecipeDef } = {
	wood_pickaxe = recipe("wood_pickaxe", 1, { ingredient("wood", 10) }, 5, nil, 1),
	stone_pickaxe = recipe(
		"stone_pickaxe",
		1,
		{ ingredient("wood", 50), ingredient("stone", 15), ingredient("wood_pickaxe", 1) },
		15,
		"workbench",
		2
	),
	gold_pickaxe = recipe(
		"gold_pickaxe",
		1,
		{ ingredient("wood", 40), ingredient("stone", 30), ingredient("gold", 20), ingredient("stone_pickaxe", 1) },
		20,
		"workbench",
		3
	),
	-- Tiers altos: provisórias até os minérios (diamante etc.) existirem no mapa.
	diamond_pickaxe = recipe(
		"diamond_pickaxe",
		1,
		{ ingredient("wood", 60), ingredient("stone", 40), ingredient("gold", 30), ingredient("gold_pickaxe", 1) },
		30,
		"workbench",
		30
	),
	amethyst_pickaxe = recipe(
		"amethyst_pickaxe",
		1,
		{ ingredient("wood", 80), ingredient("stone", 60), ingredient("gold", 45), ingredient("diamond_pickaxe", 1) },
		40,
		"workbench",
		31
	),
	reidite_pickaxe = recipe(
		"reidite_pickaxe",
		1,
		{ ingredient("wood", 100), ingredient("stone", 80), ingredient("gold", 60), ingredient("amethyst_pickaxe", 1) },
		50,
		"workbench",
		32
	),
	wood_sword = recipe("wood_sword", 1, { ingredient("wood", 30) }, 5, nil, 4),
	stone_sword = recipe(
		"stone_sword",
		1,
		{ ingredient("wood", 50), ingredient("stone", 25), ingredient("wood_sword", 1) },
		15,
		"workbench",
		5
	),
	gold_sword = recipe(
		"gold_sword",
		1,
		{ ingredient("wood", 60), ingredient("stone", 50), ingredient("gold", 40), ingredient("stone_sword", 1) },
		20,
		"workbench",
		6
	),
	wood_spear = recipe("wood_spear", 1, { ingredient("wood", 40) }, 5, nil, 7),
	stone_spear = recipe(
		"stone_spear",
		1,
		{ ingredient("wood", 60), ingredient("stone", 10), ingredient("wood_spear", 1) },
		15,
		"workbench",
		8
	),
	gold_spear = recipe(
		"gold_spear",
		1,
		{ ingredient("wood", 80), ingredient("stone", 30), ingredient("gold", 30), ingredient("stone_spear", 1) },
		20,
		"workbench",
		9
	),
	wood_helmet = recipe("wood_helmet", 1, { ingredient("wood", 50) }, 5, nil, 10),
	stone_helmet = recipe(
		"stone_helmet",
		1,
		{ ingredient("wood", 75), ingredient("stone", 75), ingredient("wood_helmet", 1) },
		20,
		"workbench",
		11
	),
	gold_helmet = recipe(
		"gold_helmet",
		1,
		{ ingredient("wood", 90), ingredient("stone", 90), ingredient("gold", 90), ingredient("stone_helmet", 1) },
		20,
		"workbench",
		12
	),
	workbench = recipe("workbench", 1, { ingredient("wood", 30), ingredient("stone", 10) }, 10, nil, 13),
	campfire = recipe("campfire", 1, { ingredient("wood", 25), ingredient("stone", 5) }, 10, nil, 14),
	big_campfire = recipe(
		"big_campfire",
		1,
		{ ingredient("wood", 35), ingredient("stone", 10), ingredient("campfire", 1) },
		15,
		nil,
		15
	),
	wood_wall = recipe("wood_wall", 1, { ingredient("wood", 20) }, 5, "workbench", 16),
	stone_wall = recipe("stone_wall", 1, { ingredient("stone", 17) }, 5, "workbench", 17),
	gold_wall = recipe("gold_wall", 1, { ingredient("gold", 14) }, 5, "workbench", 18),
	wood_door = recipe("wood_door", 1, { ingredient("wood", 30) }, 8, "workbench", 19),
	stone_door = recipe("stone_door", 1, { ingredient("stone", 27), ingredient("wood_door", 1) }, 8, "workbench", 20),
	gold_door = recipe("gold_door", 1, { ingredient("gold", 24), ingredient("stone_door", 1) }, 8, "workbench", 21),
	wood_spike = recipe(
		"wood_spike",
		1,
		{ ingredient("wood", 40), ingredient("stone", 30), ingredient("wood_wall", 1) },
		20,
		"workbench",
		22
	),
	stone_spike = recipe(
		"stone_spike",
		1,
		{ ingredient("stone", 70), ingredient("stone_wall", 1) },
		20,
		"workbench",
		23
	),
	gold_spike = recipe(
		"gold_spike",
		1,
		{ ingredient("gold", 40), ingredient("stone", 30), ingredient("gold_wall", 1) },
		20,
		"workbench",
		24
	),
	chest = recipe("chest", 1, { ingredient("wood", 25), ingredient("gold", 2) }, 20, "workbench", 25),
	paper = recipe("paper", 1, { ingredient("wood", 20) }, 5, "fire", 26),
	cooked_meat = recipe("cooked_meat", 1, { ingredient("raw_meat", 1) }, 3, "fire", 40),
	-- Provisórias até os mobs (Starve: pele de lobo/coelho e linha). Trocar = só estes dados.
	book = recipe("book", 1, { ingredient("paper", 4), ingredient("gold", 10) }, 30, "workbench", 27),
	earmuffs = recipe("earmuffs", 1, { ingredient("wood", 30), ingredient("gold", 5) }, 10, "workbench", 28),
	leather_bag = recipe(
		"leather_bag",
		1,
		{ ingredient("wood", 60), ingredient("stone", 20), ingredient("gold", 5) },
		15,
		"workbench",
		29
	),
	-- G8: estruturas novas (só para teste).
	wood_spike_door = recipe(
		"wood_spike_door",
		1,
		{ ingredient("wood_door", 1), ingredient("wood_spike", 1) },
		10,
		"workbench",
		51
	), -- provisório
	stone_spike_door = recipe(
		"stone_spike_door",
		1,
		{ ingredient("stone_door", 1), ingredient("stone_spike", 1) },
		10,
		"workbench",
		52
	), -- provisório
	gold_spike_door = recipe(
		"gold_spike_door",
		1,
		{ ingredient("gold_door", 1), ingredient("gold_spike", 1) },
		10,
		"workbench",
		53
	), -- provisório
	stone_extractor = recipe(
		"stone_extractor",
		1,
		{ ingredient("wood", 200), ingredient("stone", 50) },
		10,
		"workbench",
		54
	), -- provisório
	gold_extractor = recipe(
		"gold_extractor",
		1,
		{ ingredient("wood", 200), ingredient("gold", 30) },
		10,
		"workbench",
		55
	), -- provisório
	furnace = recipe("furnace", 1, { ingredient("stone", 100), ingredient("gold", 30) }, 10, "workbench", 44), -- provisório
	bridge = recipe("bridge", 1, { ingredient("wood", 30) }, 5, "workbench", 45), -- provisório
	roof = recipe("roof", 1, { ingredient("wood", 25) }, 5, "workbench", 46), -- provisório
	sign = recipe("sign", 1, { ingredient("wood", 20) }, 5, "workbench", 47), -- wiki
	well = recipe("well", 1, { ingredient("stone", 60) }, 8, "workbench", 48), -- provisório
	bed = recipe("bed", 1, {
		ingredient("wood", 100),
		ingredient("stone", 50),
		ingredient("wolf_fur", 5),
		ingredient("rabbit_fur", 5),
		ingredient("thread", 6),
	}, 10, "workbench", 49), -- wiki
	bucket = recipe("bucket", 1, { ingredient("wood", 15) }, 5, "workbench", 50), -- provisório
}

return table.freeze(Recipes)
