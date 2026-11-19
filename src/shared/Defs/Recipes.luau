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
	-- Tiers altos: receitas do Starve (testOnly até os minérios existirem no mapa).
	diamond_pickaxe = recipe(
		"diamond_pickaxe",
		1,
		{ ingredient("diamond", 20), ingredient("gold", 50), ingredient("stone", 80), ingredient("gold_pickaxe", 1) },
		20,
		"workbench",
		30
	),
	amethyst_pickaxe = recipe("amethyst_pickaxe", 1, {
		ingredient("diamond", 40),
		ingredient("gold", 60),
		ingredient("amethyst", 30),
		ingredient("diamond_pickaxe", 1),
	}, 60, "workbench", 31),
	reidite_pickaxe = recipe("reidite_pickaxe", 1, {
		ingredient("amethyst", 30),
		ingredient("diamond", 40),
		ingredient("reidite", 30),
		ingredient("amethyst_pickaxe", 1),
	}, 90, "workbench", 32),
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
	bandage = recipe("bandage", 1, { ingredient("thread", 2) }, 5, "workbench", 41),
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
		{ i("wood_door", 1), i("wood", 80), i("stone", 60) },
		20,
		"workbench",
		51
	),
	stone_spike_door = recipe("stone_spike_door", 1, { i("stone_door", 1), i("stone", 140) }, 20, "workbench", 52),
	gold_spike_door = recipe(
		"gold_spike_door",
		1,
		{ i("gold_door", 1), i("gold", 80), i("stone", 60) },
		20,
		"workbench",
		53
	),
	stone_extractor = recipe("stone_extractor", 1, { i("wood", 50), i("stone", 100) }, 90, "workbench", 54),
	gold_extractor = recipe("gold_extractor", 1, { i("stone", 60), i("gold", 120) }, 90, "workbench", 55),
	furnace = recipe("furnace", 1, { i("wood", 150), i("stone", 50), i("gold", 15) }, 20, "workbench", 44),
	bridge = recipe("bridge", 1, { i("wood", 15) }, 5, "workbench", 45),
	roof = recipe("roof", 1, { i("wood", 30) }, 5, "workbench", 46),
	sign = recipe("sign", 1, { i("wood", 20) }, 5, "workbench", 47),
	-- Config do Starve: 100 pedras + 30 terras, bancada e fogo perto, 10 s.
	well = recipe("well", 1, { ingredient("stone", 100), ingredient("ground", 30) }, 10, "workbench", 48, FIRE),
	bed = recipe("bed", 1, {
		ingredient("wood", 100),
		ingredient("stone", 50),
		ingredient("wolf_fur", 5),
		ingredient("rabbit_fur", 5),
		ingredient("thread", 6),
	}, 10, "workbench", 49), -- wiki
	-- Config do Starve (bucket_empty): 20 madeira + 1 linha, bancada, 5 s.
	bucket = recipe("bucket", 1, { ingredient("wood", 20), ingredient("thread", 1) }, 5, "workbench", 50),

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
	-- Ferramentas e armas (config oficial do Starve; 11/11).
	diamond_sword = recipe(
		"diamond_sword",
		1,
		{ i("diamond", 40), i("gold", 60), i("stone", 80), i("gold_sword", 1) },
		30,
		"workbench",
		90
	),
	amethyst_sword = recipe(
		"amethyst_sword",
		1,
		{ i("diamond", 60), i("gold", 100), i("amethyst", 40), i("diamond_sword", 1) },
		60,
		"workbench",
		91
	),
	reidite_sword = recipe(
		"reidite_sword",
		1,
		{ i("diamond", 100), i("amethyst", 80), i("reidite", 40), i("amethyst_sword", 1) },
		90,
		"workbench",
		92
	),
	dragon_sword = recipe(
		"dragon_sword",
		1,
		{ i("blue_thread", 20), i("dragon_orb", 1), i("amethyst", 150), i("dragon_heart", 3) },
		120,
		"workbench",
		93,
		FIRE_WATER
	),
	lava_sword = recipe(
		"lava_sword",
		1,
		{ i("dragon_sword", 1), i("lava_orb", 1), i("reidite", 150), i("lava_heart", 2) },
		180,
		"workbench",
		94,
		FIRE_WATER
	),
	diamond_spear = recipe(
		"diamond_spear",
		1,
		{ i("wood", 200), i("diamond", 40), i("gold", 60), i("gold_spear", 1) },
		30,
		"workbench",
		95
	),
	amethyst_spear = recipe(
		"amethyst_spear",
		1,
		{ i("amethyst", 40), i("diamond", 80), i("gold", 90), i("diamond_spear", 1) },
		60,
		"workbench",
		96
	),
	reidite_spear = recipe(
		"reidite_spear",
		1,
		{ i("reidite", 40), i("amethyst", 80), i("diamond", 90), i("amethyst_spear", 1) },
		90,
		"workbench",
		97
	),
	dragon_spear = recipe(
		"dragon_spear",
		1,
		{ i("blue_thread", 20), i("dragon_orb", 1), i("amethyst", 100), i("dragon_heart", 3) },
		120,
		"workbench",
		98,
		FIRE_WATER
	),
	lava_spear = recipe(
		"lava_spear",
		1,
		{ i("dragon_spear", 1), i("lava_orb", 1), i("reidite", 100), i("lava_heart", 2) },
		200,
		"workbench",
		99,
		FIRE_WATER
	),
	crab_spear = recipe(
		"crab_spear",
		1,
		{ i("wood_spear", 1), i("crab_claws", 5), i("thread", 6) },
		30,
		"workbench",
		100
	),
	stone_hammer = recipe("stone_hammer", 1, { i("wood", 90), i("stone", 50) }, 10, "workbench", 101),
	gold_hammer = recipe(
		"gold_hammer",
		1,
		{ i("wood", 160), i("stone", 120), i("gold", 80), i("stone_hammer", 1) },
		15,
		"workbench",
		102
	),
	diamond_hammer = recipe(
		"diamond_hammer",
		1,
		{ i("diamond", 80), i("stone", 200), i("gold", 150), i("gold_hammer", 1) },
		20,
		"workbench",
		103
	),
	amethyst_hammer = recipe(
		"amethyst_hammer",
		1,
		{ i("diamond", 160), i("amethyst", 60), i("gold", 250), i("diamond_hammer", 1) },
		60,
		"workbench",
		104
	),
	reidite_hammer = recipe(
		"reidite_hammer",
		1,
		{ i("amethyst", 160), i("reidite", 60), i("diamond", 250), i("amethyst_hammer", 1) },
		90,
		"workbench",
		105
	),
	-- Super Martelo: a garrafa d'água do Starve vira o balde d'água.
	super_hammer = recipe("super_hammer", 1, {
		i("reidite_hammer", 1),
		i("water_bucket", 1),
		i("kraken_skin", 1),
		i("piranha_scales", 10),
		i("amethyst", 20),
	}, 120, "workbench", 106, FIRE),
	wood_shield = recipe("wood_shield", 1, { i("wood", 100) }, 25, "workbench", 107),
	stone_shield = recipe(
		"stone_shield",
		1,
		{ i("wood_shield", 1), i("stone", 100), i("wood", 50) },
		40,
		"workbench",
		108
	),
	gold_shield = recipe(
		"gold_shield",
		1,
		{ i("stone_shield", 1), i("gold", 50), i("stone", 50), i("wood", 50) },
		50,
		"workbench",
		109
	),
	diamond_shield = recipe(
		"diamond_shield",
		1,
		{ i("gold_shield", 1), i("diamond", 50), i("gold", 50), i("stone", 50) },
		70,
		"workbench",
		110
	),
	amethyst_shield = recipe(
		"amethyst_shield",
		1,
		{ i("diamond_shield", 1), i("amethyst", 50), i("diamond", 50), i("gold", 50) },
		90,
		"workbench",
		111
	),
	reidite_shield = recipe(
		"reidite_shield",
		1,
		{ i("amethyst_shield", 1), i("reidite", 50), i("amethyst", 50), i("diamond", 50) },
		120,
		"workbench",
		112
	),
	-- Chave inglesa: receita da wiki (70 pedra); o tempo é escolha nossa.
	wrench = recipe("wrench", 1, { i("stone", 70) }, 10, "workbench", 113),
	stone_shovel = recipe("stone_shovel", 1, { i("wood", 30), i("stone", 15) }, 5, "workbench", 114),
	gold_shovel = recipe(
		"gold_shovel",
		1,
		{ i("stone_shovel", 1), i("gold", 20), i("stone", 30), i("wood", 40) },
		10,
		"workbench",
		115
	),
	diamond_shovel = recipe(
		"diamond_shovel",
		1,
		{ i("gold_shovel", 1), i("diamond", 20), i("gold", 50), i("stone", 80) },
		20,
		"workbench",
		116
	),
	amethyst_shovel = recipe(
		"amethyst_shovel",
		1,
		{ i("diamond_shovel", 1), i("gold", 60), i("amethyst", 30), i("diamond", 40) },
		40,
		"workbench",
		117
	),
	pitchfork = recipe("pitchfork", 1, { i("wood", 100), i("stone", 50) }, 10, "workbench", 118),
	gold_pitchfork = recipe("gold_pitchfork", 1, { i("pitchfork", 1), i("pitchfork_part", 1) }, 60, "workbench", 119),
	watering_can = recipe("watering_can", 1, { i("wood", 50) }, 5, "workbench", 120),
	-- Fazenda (config do Starve): canteiro na bancada; sementes perto do fogo.
	plot = recipe("plot", 1, { i("wood", 20), i("ground", 15) }, 5, "workbench", 140),
	berry_seed = recipe("berry_seed", 1, { i("berry", 3) }, 5, "fire", 141),
	wheat_seed = recipe("wheat_seed", 1, { i("wheat", 3) }, 5, "fire", 142),
	pumpkin_seed = recipe("pumpkin_seed", 1, { i("pumpkin", 8) }, 5, "fire", 143),
	carrot_seed = recipe("carrot_seed", 1, { i("carrot", 8) }, 5, "fire", 144),
	tomato_seed = recipe("tomato_seed", 1, { i("tomato", 8) }, 5, "fire", 145),
	garlic_seed = recipe("garlic_seed", 1, { i("garlic", 8) }, 5, "fire", 146),
	thornbush_seed = recipe("thornbush_seed", 1, { i("thornbush", 8) }, 5, "fire", 147),
	watermelon_seed = recipe("watermelon_seed", 1, { i("watermelon", 16) }, 5, "fire", 148),
	aloe_vera_seed = recipe("aloe_vera_seed", 1, { i("aloe_vera", 16) }, 5, "fire", 149),
	machete = recipe("machete", 1, { i("stone", 70), i("wood", 50) }, 10, "workbench", 121),
	reidite_wall = recipe("reidite_wall", 1, { i("amethyst_wall", 1), i("reidite", 5) }, 5, "workbench", 130),
	reidite_door = recipe("reidite_door", 1, { i("amethyst_door", 1), i("reidite", 15) }, 8, "workbench", 131),
	reidite_spike = recipe(
		"reidite_spike",
		1,
		{ i("reidite_wall", 1), i("reidite", 40), i("gold", 30) },
		20,
		"workbench",
		132
	),
	reidite_spike_door = recipe(
		"reidite_spike_door",
		1,
		{ i("reidite_door", 1), i("reidite", 80), i("gold", 60) },
		20,
		"workbench",
		133
	),
	reidite_extractor = recipe("reidite_extractor", 1, { i("amethyst", 90), i("reidite", 180) }, 90, "workbench", 134),
	-- Construções novas (config oficial do Starve; 11/11).
	diamond_wall = recipe("diamond_wall", 1, { i("gold_wall", 1), i("diamond", 11) }, 5, "workbench", 122),
	diamond_door = recipe("diamond_door", 1, { i("gold_door", 1), i("diamond", 21) }, 8, "workbench", 123),
	diamond_spike = recipe(
		"diamond_spike",
		1,
		{ i("diamond_wall", 1), i("diamond", 40), i("stone", 30) },
		20,
		"workbench",
		124
	),
	diamond_spike_door = recipe(
		"diamond_spike_door",
		1,
		{ i("diamond_door", 1), i("diamond", 80), i("stone", 60) },
		20,
		"workbench",
		125
	),
	amethyst_wall = recipe("amethyst_wall", 1, { i("diamond_wall", 1), i("amethyst", 8) }, 5, "workbench", 126),
	amethyst_door = recipe("amethyst_door", 1, { i("diamond_door", 1), i("amethyst", 18) }, 8, "workbench", 127),
	amethyst_spike = recipe(
		"amethyst_spike",
		1,
		{ i("amethyst_wall", 1), i("amethyst", 40), i("stone", 30) },
		20,
		"workbench",
		128
	),
	amethyst_spike_door = recipe(
		"amethyst_spike_door",
		1,
		{ i("amethyst_door", 1), i("amethyst", 80), i("stone", 60) },
		20,
		"workbench",
		129
	),
	diamond_extractor = recipe("diamond_extractor", 1, { i("gold", 70), i("diamond", 140) }, 90, "workbench", 135),
	amethyst_extractor = recipe(
		"amethyst_extractor",
		1,
		{ i("diamond", 80), i("amethyst", 160) },
		90,
		"workbench",
		136
	),
	totem = recipe("totem", 1, { i("wood", 50) }, 10, "workbench", 137),
	resurrection_stone = recipe("resurrection_stone", 1, { i("diamond", 40), i("stone", 45) }, 20, "workbench", 138),
	emerald_machine = recipe("emerald_machine", 1, {
		i("resurrection_stone", 1),
		i("emerald", 40),
		i("sandworm_juice", 1),
	}, 200, "workbench", 139, FIRE_WATER),
}

return table.freeze(Recipes)
