--!strict
-- Itens do jogo. Para adicionar um item: uma entrada aqui + o texto
-- "item.<id>" em Strings/ptBR.luau. Veja docs/guia/adicionar-item.md.
local SurvivalConfig = require("../SurvivalConfig")
local Types = require("./Types")

type ItemDef = Types.ItemDef

local Items: { [string]: ItemDef } = {
	-- Recursos (sem tier: moldura neutra)
	wood = { id = "wood", nameKey = "item.wood", category = "resource", maxStack = 255 },
	stone = { id = "stone", nameKey = "item.stone", category = "resource", maxStack = 255 },
	gold = { id = "gold", nameKey = "item.gold", category = "resource", maxStack = 255 },
	-- Só para teste (sai do extrator de reidite; o minério ainda não está no mapa).
	reidite = {
		id = "reidite",
		testOnly = true,
		nameKey = "item.reidite",
		category = "resource",
		tier = "reidite",
		maxStack = 255,
	},

	-- Comida
	berry = {
		id = "berry",
		nameKey = "item.berry",
		category = "food",
		maxStack = 255,
		food = { hunger = 10, crumbColor = "#7B3FA6" },
	},

	-- Carne dos mobs (crua vem do loot; assada na fogueira)
	raw_meat = {
		id = "raw_meat",
		nameKey = "item.raw_meat",
		category = "food",
		maxStack = 255,
		food = { hunger = 15, crumbColor = "#D9534F" },
	},
	cooked_meat = {
		id = "cooked_meat",
		nameKey = "item.cooked_meat",
		category = "food",
		maxStack = 255,
		food = { hunger = 35, crumbColor = "#8B4A2B" },
	},

	-- Peles, pena e linha (loot dos mobs)
	rabbit_fur = { id = "rabbit_fur", nameKey = "item.rabbit_fur", category = "resource", maxStack = 255 },
	wolf_fur = { id = "wolf_fur", nameKey = "item.wolf_fur", category = "resource", maxStack = 255 },
	boar_fur = { id = "boar_fur", nameKey = "item.boar_fur", category = "resource", maxStack = 255 },
	hawk_feather = { id = "hawk_feather", nameKey = "item.hawk_feather", category = "resource", maxStack = 255 },
	thread = { id = "thread", nameKey = "item.thread", category = "resource", maxStack = 255 },

	-- Mochilas (vestidas, não ocupam slot; dão bagSlots slots a mais).
	-- Para uma mochila maior num update, é só adicionar outra entrada aqui.
	leather_bag = {
		id = "leather_bag",
		nameKey = "item.leather_bag",
		category = "bag",
		maxStack = 1,
		bagSlots = 6,
	},

	-- Ferramentas
	wood_pickaxe = {
		id = "wood_pickaxe",
		nameKey = "item.wood_pickaxe",
		category = "tool",
		tier = "wood",
		maxStack = 1,
		pickaxe = { level = 1 },
		structureDamage = 10,
		mobDamage = 4,
	},
	stone_pickaxe = {
		id = "stone_pickaxe",
		nameKey = "item.stone_pickaxe",
		category = "tool",
		tier = "stone",
		maxStack = 1,
		pickaxe = { level = 2 },
		structureDamage = 15,
		mobDamage = 6,
	},
	gold_pickaxe = {
		id = "gold_pickaxe",
		nameKey = "item.gold_pickaxe",
		category = "tool",
		tier = "gold",
		maxStack = 1,
		pickaxe = { level = 3 },
		structureDamage = 20,
		mobDamage = 8,
	},
	diamond_pickaxe = {
		id = "diamond_pickaxe",
		-- Fora do jogo por enquanto (decisão do Elizeu, 09/11): só até ouro.
		testOnly = true,
		nameKey = "item.diamond_pickaxe",
		category = "tool",
		tier = "diamond",
		maxStack = 1,
		pickaxe = { level = 4 },
		structureDamage = 25,
		mobDamage = 10,
	},
	amethyst_pickaxe = {
		id = "amethyst_pickaxe",
		-- Fora do jogo por enquanto (decisão do Elizeu, 09/11): só até ouro.
		testOnly = true,
		nameKey = "item.amethyst_pickaxe",
		category = "tool",
		tier = "amethyst",
		maxStack = 1,
		pickaxe = { level = 5 },
		structureDamage = 30,
		mobDamage = 12,
	},
	reidite_pickaxe = {
		id = "reidite_pickaxe",
		-- Fora do jogo por enquanto (decisão do Elizeu, 09/11): só até ouro.
		testOnly = true,
		nameKey = "item.reidite_pickaxe",
		category = "tool",
		tier = "reidite",
		maxStack = 1,
		pickaxe = { level = 6 },
		structureDamage = 35,
		mobDamage = 14,
	},
	-- Armas craftáveis. Na mão deixam o jogador mais lento (moveSpeed) e ficam
	-- presas por equipLock s; a lança alcança mais longe (reach) e empurra o mob
	-- (knockback: fugindo de lança, o mob da floresta não morde). Números do Starve
	-- sem valor na wiki ("bem mais lento", "alguns segundos"): escolha provisória.
	wood_sword = {
		id = "wood_sword",
		nameKey = "item.wood_sword",
		category = "weapon",
		tier = "wood",
		maxStack = 1,
		structureDamage = 5,
		mobDamage = 12,
		moveSpeed = 0.75,
		equipLock = 4,
	},
	stone_sword = {
		id = "stone_sword",
		nameKey = "item.stone_sword",
		category = "weapon",
		tier = "stone",
		maxStack = 1,
		structureDamage = 7.5,
		mobDamage = 19,
		moveSpeed = 0.75,
		equipLock = 4,
	},
	gold_sword = {
		id = "gold_sword",
		nameKey = "item.gold_sword",
		category = "weapon",
		tier = "gold",
		maxStack = 1,
		structureDamage = 10,
		mobDamage = 22,
		moveSpeed = 0.75,
		equipLock = 4,
	},
	wood_spear = {
		id = "wood_spear",
		nameKey = "item.wood_spear",
		category = "weapon",
		tier = "wood",
		maxStack = 1,
		structureDamage = 5,
		mobDamage = 10,
		moveSpeed = 0.75,
		equipLock = 4,
		attackAnim = "thrust",
		reach = 3,
		knockback = 4,
	},
	stone_spear = {
		id = "stone_spear",
		nameKey = "item.stone_spear",
		category = "weapon",
		tier = "stone",
		maxStack = 1,
		structureDamage = 7.5,
		mobDamage = 14,
		moveSpeed = 0.75,
		equipLock = 4,
		attackAnim = "thrust",
		reach = 3,
		knockback = 4,
	},
	gold_spear = {
		id = "gold_spear",
		nameKey = "item.gold_spear",
		category = "weapon",
		tier = "gold",
		maxStack = 1,
		structureDamage = 10,
		mobDamage = 15,
		moveSpeed = 0.75,
		equipLock = 4,
		attackAnim = "thrust",
		reach = 3,
		knockback = 4,
	},
	-- Proteção provisória, ajustada quando o combate for implementado.
	wood_helmet = {
		id = "wood_helmet",
		nameKey = "item.wood_helmet",
		category = "armor",
		tier = "wood",
		maxStack = 1,
		armor = { defense = 0.1 },
	},
	stone_helmet = {
		id = "stone_helmet",
		nameKey = "item.stone_helmet",
		category = "armor",
		tier = "stone",
		maxStack = 1,
		armor = { defense = 0.2 },
	},
	gold_helmet = {
		id = "gold_helmet",
		nameKey = "item.gold_helmet",
		category = "armor",
		tier = "gold",
		maxStack = 1,
		armor = { defense = 0.3 },
	},
	earmuffs = {
		id = "earmuffs",
		nameKey = "item.earmuffs",
		category = "armor",
		maxStack = 1,
		armor = { coldFactor = 0.7 },
	},
	-- Peças de base: o bloco structure define a vida e o comportamento da peça colocada.
	workbench = {
		id = "workbench",
		nameKey = "item.workbench",
		category = "placeable",
		maxStack = 255,
		structure = { kind = "station", health = 300, radius = 3, station = "workbench" },
	},
	campfire = {
		id = "campfire",
		nameKey = "item.campfire",
		category = "placeable",
		maxStack = 255,
		structure = {
			radius = 2.7, -- tamanho do modelo (bancada)
			kind = "fire",
			health = 150,
			lifetime = 120,
			heatRadius = SurvivalConfig.CAMPFIRE_RADIUS,
			station = "fire",
		},
	},
	big_campfire = {
		id = "big_campfire",
		nameKey = "item.big_campfire",
		category = "placeable",
		maxStack = 255,
		structure = { kind = "fire", health = 300, radius = 3.1, lifetime = 360, heatRadius = 18, station = "fire" },
	},
	wood_wall = {
		id = "wood_wall",
		nameKey = "item.wood_wall",
		category = "placeable",
		tier = "wood",
		maxStack = 255,
		structure = { kind = "wall", health = 1000, radius = 3 },
	},
	stone_wall = {
		id = "stone_wall",
		nameKey = "item.stone_wall",
		category = "placeable",
		tier = "stone",
		maxStack = 255,
		structure = { kind = "wall", health = 1500, radius = 3 },
	},
	gold_wall = {
		id = "gold_wall",
		nameKey = "item.gold_wall",
		category = "placeable",
		tier = "gold",
		maxStack = 255,
		structure = { kind = "wall", health = 2000, radius = 3 },
	},
	wood_door = {
		id = "wood_door",
		nameKey = "item.wood_door",
		category = "placeable",
		tier = "wood",
		maxStack = 255,
		structure = { kind = "door", health = 1000, radius = 3 },
	},
	stone_door = {
		id = "stone_door",
		nameKey = "item.stone_door",
		category = "placeable",
		tier = "stone",
		maxStack = 255,
		structure = { kind = "door", health = 1500, radius = 3 },
	},
	gold_door = {
		id = "gold_door",
		nameKey = "item.gold_door",
		category = "placeable",
		tier = "gold",
		maxStack = 255,
		structure = { kind = "door", health = 2000, radius = 3 },
	},
	wood_spike = {
		id = "wood_spike",
		nameKey = "item.wood_spike",
		category = "placeable",
		tier = "wood",
		maxStack = 255,
		structure = { kind = "spike", health = 150, radius = 3, spikeDamage = 10 },
	},
	stone_spike = {
		id = "stone_spike",
		nameKey = "item.stone_spike",
		category = "placeable",
		tier = "stone",
		maxStack = 255,
		structure = { kind = "spike", health = 300, radius = 3, spikeDamage = 20 },
	},
	gold_spike = {
		id = "gold_spike",
		nameKey = "item.gold_spike",
		category = "placeable",
		tier = "gold",
		maxStack = 255,
		structure = { kind = "spike", health = 600, radius = 3, spikeDamage = 30 },
	},
	chest = {
		id = "chest",
		nameKey = "item.chest",
		category = "placeable",
		maxStack = 255,
		structure = { kind = "chest", health = 500, radius = 2.3 },
	},
	-- G8: estruturas novas, só para teste (testOnly). Números provisórios salvo onde diz wiki.
	wood_spike_door = {
		id = "wood_spike_door",
		testOnly = true,
		nameKey = "item.wood_spike_door",
		category = "placeable",
		tier = "wood",
		maxStack = 255,
		structure = { kind = "spike_door", health = 1000, radius = 3, spikeDamage = 10 },
	},
	stone_spike_door = {
		id = "stone_spike_door",
		testOnly = true,
		nameKey = "item.stone_spike_door",
		category = "placeable",
		tier = "stone",
		maxStack = 255,
		structure = { kind = "spike_door", health = 1500, radius = 3, spikeDamage = 20 },
	},
	gold_spike_door = {
		id = "gold_spike_door",
		testOnly = true,
		nameKey = "item.gold_spike_door",
		category = "placeable",
		tier = "gold",
		maxStack = 255,
		structure = { kind = "spike_door", health = 2000, radius = 3, spikeDamage = 30 },
	},
	stone_extractor = {
		id = "stone_extractor",
		testOnly = true,
		nameKey = "item.stone_extractor",
		category = "placeable",
		maxStack = 255,
		structure = {
			radius = 2.7, -- tamanho do modelo (bancada)
			kind = "extractor",
			health = 300, -- provisório
			-- cycleSeconds: wiki; o resto provisório
			extractor = {
				output = "stone",
				woodPerCycle = 2,
				cycleSeconds = 10,
				yield = 1,
				maxWood = 100,
				maxStock = 100,
			},
		},
	},
	gold_extractor = {
		id = "gold_extractor",
		testOnly = true,
		nameKey = "item.gold_extractor",
		category = "placeable",
		maxStack = 255,
		structure = {
			radius = 2.7, -- tamanho do modelo (bancada)
			kind = "extractor",
			health = 300, -- provisório
			-- cycleSeconds: wiki; o resto provisório
			extractor = {
				output = "gold",
				woodPerCycle = 2,
				cycleSeconds = 10,
				yield = 1,
				maxWood = 100,
				maxStock = 100,
			},
		},
	},
	-- Builds de reidite (09/11): só para teste (testOnly), para ver os modelos no
	-- jogo. Números provisórios, na escada dos outros tiers (vida +500 por tier
	-- nas paredes/portas; espinho dobra a vida e soma 10 de dano por tier).
	reidite_wall = {
		id = "reidite_wall",
		testOnly = true,
		nameKey = "item.reidite_wall",
		category = "placeable",
		tier = "reidite",
		maxStack = 255,
		structure = { kind = "wall", health = 3500, radius = 3 },
	},
	reidite_door = {
		id = "reidite_door",
		testOnly = true,
		nameKey = "item.reidite_door",
		category = "placeable",
		tier = "reidite",
		maxStack = 255,
		structure = { kind = "door", health = 3500, radius = 3 },
	},
	reidite_spike = {
		id = "reidite_spike",
		testOnly = true,
		nameKey = "item.reidite_spike",
		category = "placeable",
		tier = "reidite",
		maxStack = 255,
		structure = { kind = "spike", health = 4800, radius = 3, spikeDamage = 60 },
	},
	reidite_spike_door = {
		id = "reidite_spike_door",
		testOnly = true,
		nameKey = "item.reidite_spike_door",
		category = "placeable",
		tier = "reidite",
		maxStack = 255,
		structure = { kind = "spike_door", health = 3500, radius = 3, spikeDamage = 60 },
	},
	reidite_extractor = {
		id = "reidite_extractor",
		testOnly = true,
		nameKey = "item.reidite_extractor",
		category = "placeable",
		maxStack = 255,
		structure = {
			radius = 2.7, -- mesmo modelo-base dos outros extratores
			kind = "extractor",
			health = 300, -- provisório
			extractor = {
				output = "reidite",
				woodPerCycle = 2,
				cycleSeconds = 10,
				yield = 1,
				maxWood = 100,
				maxStock = 100,
			},
		},
	},
	furnace = {
		id = "furnace",
		testOnly = true,
		nameKey = "item.furnace",
		category = "placeable",
		maxStack = 255,
		structure = {
			radius = 3, -- tamanho do modelo (bancada)
			kind = "furnace",
			health = 500, -- provisório
			heatRadius = 24, -- provisório
			station = "fire",
			furnace = { burnEvery = 6, maxWood = 200 }, -- burnEvery: wiki; maxWood provisório
		},
	},
	bridge = {
		id = "bridge",
		testOnly = true,
		nameKey = "item.bridge",
		category = "placeable",
		maxStack = 255,
		structure = { kind = "bridge", health = 300, radius = 3.1 }, -- provisório
	},
	roof = {
		id = "roof",
		testOnly = true,
		nameKey = "item.roof",
		category = "placeable",
		maxStack = 255,
		structure = { kind = "roof", health = 300, radius = 3.2 }, -- provisório
	},
	sign = {
		id = "sign",
		testOnly = true,
		nameKey = "item.sign",
		category = "placeable",
		maxStack = 255,
		structure = { kind = "sign", health = 100 }, -- provisório
	},
	well = {
		id = "well",
		testOnly = true,
		nameKey = "item.well",
		category = "placeable",
		maxStack = 255,
		structure = {
			radius = 2.6, -- tamanho do modelo (bancada)
			kind = "well",
			health = 500, -- provisório
			well = { drinksPerBucket = 12, maxDrinks = 48, thirstPerDrink = 20 }, -- drinksPerBucket: wiki
		},
	},
	bed = {
		id = "bed",
		testOnly = true,
		nameKey = "item.bed",
		category = "placeable",
		maxStack = 255,
		structure = {
			radius = 3.5, -- tamanho do modelo (bancada)
			kind = "bed",
			health = 300, -- provisório
			bed = { regenFactor = 2, drainFactor = 0.5 },
		},
	},
	bucket = { id = "bucket", testOnly = true, nameKey = "item.bucket", category = "misc", maxStack = 1 },
	water_bucket = {
		id = "water_bucket",
		testOnly = true,
		nameKey = "item.water_bucket",
		category = "misc",
		maxStack = 1,
	},
	paper = { id = "paper", nameKey = "item.paper", category = "resource", maxStack = 255 },
	book = { id = "book", nameKey = "item.book", category = "misc", maxStack = 1, craftSpeed = 3 },
}

for _, item in Items do
	if item.food ~= nil then
		table.freeze(item.food)
	end
	if item.armor ~= nil then
		table.freeze(item.armor)
	end
	if item.pickaxe ~= nil then
		table.freeze(item.pickaxe)
	end
	if item.structure ~= nil then
		for _, field in { "extractor", "furnace", "well", "bed" } do
			local block = (item.structure :: any)[field]
			if block ~= nil then
				table.freeze(block)
			end
		end
		table.freeze(item.structure)
	end
	table.freeze(item)
end

return table.freeze(Items)
