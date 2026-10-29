--!strict
-- Kits iniciais (como no Starve.io): antes de nascer, o jogador pode comprar
-- UM kit pagando com os pontos da vida que acabou (não com Golden Ember).
-- Kit novo = uma entrada aqui + o texto "kit.<id>" em Strings/ptBR.luau.
-- items: { id, count } de Defs.Items; uma mochila é vestida em vez de ir para
-- um slot (no máximo uma por kit, count 1). Valores provisórios: o Elizeu ajusta.
local Types = require("./Types")

type KitDef = Types.KitDef

local Kits: { [string]: KitDef } = {
	kit_starter = {
		id = "kit_starter",
		nameKey = "kit.kit_starter",
		order = 1,
		price = 1000,
		items = {
			{ id = "berry", count = 8 },
			{ id = "wood", count = 20 },
		},
	},
	kit_explorer = {
		id = "kit_explorer",
		nameKey = "kit.kit_explorer",
		order = 2,
		price = 2000,
		items = {
			{ id = "berry", count = 16 },
			{ id = "wood", count = 40 },
			{ id = "stone", count = 20 },
			{ id = "wood_pickaxe", count = 1 },
		},
	},
	kit_survivor = {
		id = "kit_survivor",
		nameKey = "kit.kit_survivor",
		order = 3,
		price = 4000,
		items = {
			{ id = "berry", count = 20 },
			{ id = "wood", count = 140 },
			{ id = "stone", count = 80 },
			{ id = "stone_pickaxe", count = 1 },
			{ id = "leather_bag", count = 1 },
		},
	},
	kit_veteran = {
		id = "kit_veteran",
		nameKey = "kit.kit_veteran",
		order = 4,
		price = 8000,
		items = {
			{ id = "berry", count = 30 },
			{ id = "wood", count = 200 },
			{ id = "stone", count = 150 },
			{ id = "gold", count = 20 },
			{ id = "gold_pickaxe", count = 1 },
			{ id = "leather_bag", count = 1 },
		},
	},
}

for _, kit in Kits do
	for _, item in kit.items do
		table.freeze(item)
	end
	table.freeze(kit.items)
	table.freeze(kit)
end

return table.freeze(Kits)
