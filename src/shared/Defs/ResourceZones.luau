--!strict
-- Tipos de zona de recurso. No Studio, uma Part em Workspace.Map/Zones com o
-- atributo ZoneType = "<id>" é preenchida pelo espalhador com estas densidades
-- (quantos de cada recurso a cada 10.000 studs², ou seja, num quadrado 100×100).
-- Zona nova = uma entrada aqui + o texto "zone.<id>" em Strings/ptBR.luau.
-- Valores provisórios: o Elizeu ajusta.
local Types = require("./Types")

type ResourceZoneDef = Types.ResourceZoneDef

local function zone(id: string, densities: { [string]: number }): ResourceZoneDef
	return table.freeze({
		id = id,
		nameKey = "zone." .. id,
		densities = table.freeze(densities),
	})
end

local ResourceZones: { [string]: ResourceZoneDef } = {
	forest_dense = zone("forest_dense", { tree = 14, rock = 2, berry_bush = 2, pebble = 3 }),
	forest_open = zone("forest_open", { tree = 6, rock = 3, berry_bush = 3, gold_vein = 0.3, pebble = 5 }),
	quarry = zone("quarry", { rock = 8, gold_vein = 3, tree = 1, pebble = 10 }),
	berry_field = zone("berry_field", { berry_bush = 8, tree = 1, pebble = 3 }),
}

return table.freeze(ResourceZones)
