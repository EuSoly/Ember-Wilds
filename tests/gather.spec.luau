--!strict
local Defs = require("../src/shared/Defs")
local GatherRules = require("../src/shared/Gather/GatherRules")

local items = Defs.Items
local tree = Defs.Resources.tree.gather :: any
local rock = Defs.Resources.rock.gather :: any
local gold = Defs.Resources.gold_vein.gather :: any
local bush = Defs.Resources.berry_bush.gather :: any

local function eq(got: any, want: any, label: string)
	assert(got == want, `{label}: veio {got}, esperava {want}`)
end

return {
	["yield follows the pickaxe table"] = function()
		eq(GatherRules.yield(nil, tree), 1, "mão na árvore")
		eq(GatherRules.yield(items.wood, tree), 1, "madeira na mão = mão")
		eq(GatherRules.yield(nil, rock), nil, "mão na rocha")
		eq(GatherRules.yield(items.wood_pickaxe, tree), 2, "picareta de madeira na árvore")
		eq(GatherRules.yield(items.wood_pickaxe, rock), 1, "picareta de madeira na rocha")
		eq(GatherRules.yield(items.wood_pickaxe, gold), nil, "picareta de madeira no ouro")
		eq(GatherRules.yield(items.stone_pickaxe, tree), 3, "picareta de pedra na árvore")
		eq(GatherRules.yield(items.stone_pickaxe, rock), 2, "picareta de pedra na rocha")
		eq(GatherRules.yield(items.stone_pickaxe, gold), 1, "picareta de pedra no ouro")
		eq(GatherRules.yield(items.gold_pickaxe, tree), 4, "picareta de ouro na árvore")
		eq(GatherRules.yield(items.gold_pickaxe, gold), 2, "picareta de ouro no ouro")
	end,

	["berries yield one with anything"] = function()
		eq(GatherRules.yield(nil, bush), 1, "mão no arbusto")
		eq(GatherRules.yield(items.gold_pickaxe, bush), 1, "picareta no arbusto")
	end,

	["required pickaxe is the weakest that works"] = function()
		eq(GatherRules.requiredPickaxe(items, 1), "wood_pickaxe", "dureza 1")
		eq(GatherRules.requiredPickaxe(items, 2), "stone_pickaxe", "dureza 2")
		eq(GatherRules.requiredPickaxe(items, 99), nil, "dureza sem picareta")
	end,

	["max amount grows with the specimen size"] = function()
		eq(GatherRules.maxAmount(tree, 0.85, 0.15), 20, "árvore menor")
		eq(GatherRules.maxAmount(tree, 1.15, 0.15), 80, "árvore maior")
		eq(GatherRules.maxAmount(tree, 1, 0.15), 50, "árvore média")
		eq(GatherRules.maxAmount(tree, 2, 0.15), 80, "fora da faixa = teto")
		eq(GatherRules.maxAmount(rock, 1.1, 0.15), 40, "rocha fixa")
		eq(GatherRules.maxAmount(tree, 1, 0), 50, "sem variação = meio")
	end,

	["regen adds and caps"] = function()
		eq(GatherRules.regen(10, 40, rock), 12, "rocha +2")
		eq(GatherRules.regen(39, 40, rock), 40, "não passa do máximo")
		eq(GatherRules.regen(6, 7, bush), 7, "arbusto +1")
	end,

	["visible berries follow the reserve"] = function()
		eq(GatherRules.berriesVisible(7, 7, 7), 7, "cheio")
		eq(GatherRules.berriesVisible(1, 7, 7), 1, "uma")
		eq(GatherRules.berriesVisible(0, 7, 7), 0, "vazio")
		eq(GatherRules.berriesVisible(3, 5, 7), 5, "proporção arredonda para cima")
		eq(GatherRules.berriesVisible(1, 100, 7), 1, "sobra pouco ainda mostra uma")
		eq(GatherRules.berriesVisible(5, 0, 7), 0, "máximo 0 não divide por zero")
	end,

	["target is the closest touching resource"] = function()
		local near = { name = "perto", x = 3, z = 0, radius = 1 }
		local far = { name = "longe", x = 0, z = 6, radius = 1 }
		local touching = { name = "encosta", x = 4.5, z = 0, radius = 2 }
		local picked = GatherRules.pickTarget({ far, touching, near }, 0, 0, 2.5)
		assert(picked ~= nil and picked.name == "perto", `escolheu {picked and picked.name}`)
		eq(GatherRules.pickTarget({ far }, 0, 0, 2.5), nil, "longe não encosta")
		eq(GatherRules.pickTarget({}, 0, 0, 2.5), nil, "sem candidato")
	end,

	["hit rhythm and reach match the design"] = function()
		eq(GatherRules.HIT_INTERVAL, 0.5, "2 golpes por segundo")
		eq(GatherRules.HIT_REACH, 3.5, "alcance")
		eq(GatherRules.HIT_RADIUS, 2.5, "raio do golpe")
	end,
}
