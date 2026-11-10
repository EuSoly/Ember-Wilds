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
	order: number,
	alsoNear: { Types.CraftStation }?
): RecipeDef
	table.freeze(items)
	return table.freeze({
		id = id,
		result = id,
		count = count,
		ingredients = items,
		time = time,
		station = station,
		alsoNear = alsoNear,
		order = order,
	})
end

local i = ingredient
-- Itens de cabeça: receitas da config oficial do Starve (veja
-- docs/game-design/armaduras-starve.md). B+F = bancada e fogo; B+F+A = e água.
local FIRE = table.freeze({ "fire" :: Types.CraftStation })
local FIRE_WATER = table.freeze({ "fire" :: Types.CraftStation, "water" :: Types.CraftStation })

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
	wood_helmet = recipe("wood_helmet", 1, { i("wood", 50) }, 5, nil, 10),
	stone_helmet = recipe(
		"stone_helmet",
		1,
		{ i("stone", 75), i("wood", 75), i("wood_helmet", 1) },
		10,
		"workbench",
		11
	),
	gold_helmet = recipe(
		"gold_helmet",
		1,
		{ i("stone", 90), i("wood", 90), i("gold", 90), i("stone_helmet", 1) },
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
	earmuffs = recipe("earmuffs", 1, { i("rabbit_fur", 1), i("thread", 2) }, 5, "workbench", 28),
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

	-- Itens de cabeça do Starve (config oficial). Os de material que o jogo ainda
	-- não dá são testOnly (ver Items).
	diamond_helmet = recipe(
		"diamond_helmet",
		1,
		{ i("stone", 100), i("gold", 100), i("diamond", 100), i("gold_helmet", 1) },
		30,
		"workbench",
		60
	),
	amethyst_helmet = recipe(
		"amethyst_helmet",
		1,
		{ i("amethyst", 80), i("gold", 150), i("diamond", 120), i("diamond_helmet", 1) },
		60,
		"workbench",
		61
	),
	reidite_helmet = recipe(
		"reidite_helmet",
		1,
		{ i("reidite", 80), i("diamond", 150), i("amethyst", 120), i("amethyst_helmet", 1) },
		90,
		"workbench",
		62,
		FIRE
	),
	dragon_helmet = recipe(
		"dragon_helmet",
		1,
		{ i("blue_thread", 30), i("blue_cube", 1), i("amethyst", 150), i("dragon_heart", 3) },
		120,
		"workbench",
		63,
		FIRE_WATER
	),
	crab_helmet = recipe(
		"crab_helmet",
		1,
		{ i("gold_helmet", 1), i("crab_claws", 10), i("crab_sticks", 10), i("thread", 10) },
		60,
		"workbench",
		64
	),
	lava_helmet = recipe(
		"lava_helmet",
		1,
		{ i("dragon_helmet", 1), i("lava_cube", 1), i("reidite", 150), i("lava_heart", 2) },
		180,
		"workbench",
		65,
		FIRE_WATER
	),
	coat = recipe("coat", 1, { i("earmuffs", 1), i("wolf_fur", 5), i("thread", 4) }, 12, "workbench", 66),
	winter_hat = recipe(
		"winter_hat",
		1,
		{ i("coat", 1), i("winter_fur", 5), i("blue_thread", 4) },
		30,
		"workbench",
		67
	),
	fur_hat = recipe(
		"fur_hat",
		1,
		{ i("winter_hat", 1), i("winter_fur", 5), i("mammoth_fur", 10), i("blue_thread", 4) },
		50,
		"workbench",
		68
	),
	turban = recipe("turban", 1, { i("thread", 4), i("boar_fur", 2) }, 15, "workbench", 69),
	ninja = recipe(
		"ninja",
		1,
		{ i("turban", 1), i("thread", 6), i("boar_fur", 4), i("vulture_feather", 12), i("penguin_feather", 4) },
		150,
		"workbench",
		70
	),
	pilot = recipe("pilot", 1, {
		i("pilot_glasses", 1),
		i("hawk_feather", 8),
		i("vulture_feather", 8),
		i("penguin_feather", 8),
		i("thread", 6),
	}, 60, "workbench", 71),
	diamond_protection = recipe(
		"diamond_protection",
		1,
		{ i("flame", 5), i("diamond", 50), i("blue_thread", 5) },
		20,
		"workbench",
		72,
		FIRE
	),
	amethyst_protection = recipe(
		"amethyst_protection",
		1,
		{ i("diamond_protection", 1), i("flame", 10), i("amethyst", 50) },
		60,
		"workbench",
		73,
		FIRE
	),
	reidite_protection = recipe(
		"reidite_protection",
		1,
		{ i("amethyst_protection", 1), i("flame", 15), i("amethyst", 50), i("reidite", 50) },
		90,
		"workbench",
		74,
		FIRE
	),
	explorer = recipe("explorer", 1, { i("paper", 1), i("rabbit_fur", 1), i("thread", 2) }, 5, "workbench", 75),
	hood = recipe("hood", 1, { i("wolf_fur", 10), i("rabbit_fur", 5), i("thread", 6) }, 10, "workbench", 76),
	winter_hood = recipe("winter_hood", 1, {
		i("hood", 1),
		i("black_wolf_fur", 1),
		i("winter_fur", 15),
		i("blue_thread", 5),
		i("penguin_feather", 8),
	}, 60, "workbench", 77),
	peasant = recipe("peasant", 1, { i("rabbit_fur", 3), i("thread", 2) }, 10, "workbench", 78),
	winter_peasant = recipe("winter_peasant", 1, {
		i("peasant", 1),
		i("white_wolf_fur", 1),
		i("winter_fur", 10),
		i("blue_thread", 5),
		i("penguin_feather", 8),
	}, 60, "workbench", 79),
	diving_mask = recipe(
		"diving_mask",
		1,
		{ i("piranha_scales", 2), i("diamond", 40), i("thread", 4) },
		20,
		"workbench",
		80
	),
	diving_suit = recipe(
		"diving_suit",
		1,
		{ i("diving_mask", 1), i("gold", 80), i("kraken_skin", 1), i("amethyst", 20) },
		90,
		"workbench",
		81
	),
	-- Bruxa: sem config oficial; receita da wiki (tempo: escolha nossa).
	witch = recipe(
		"witch",
		1,
		{ i("wolf_fur", 5), i("rabbit_fur", 2), i("thread", 6), i("firefly", 2) },
		30,
		"workbench",
		82
	),
	life_crown = recipe("life_crown", 1, { i("green_gem", 1), i("gold", 200) }, 60, "workbench", 83, FIRE_WATER),
	angel_crown = recipe(
		"angel_crown",
		1,
		{ i("blue_gem", 1), i("gold", 200), i("dragon_heart", 1) },
		60,
		"workbench",
		84,
		FIRE_WATER
	),
	luck_crown = recipe("luck_crown", 1, { i("orange_gem", 1), i("gold", 200) }, 60, "workbench", 85, FIRE_WATER),
	blue_thread = recipe("blue_thread", 1, { i("diamond", 1), i("thread", 1) }, 3, "workbench", 86),
}

return table.freeze(Recipes)
