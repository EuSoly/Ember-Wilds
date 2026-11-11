--!strict
-- As ferramentas e armas dos modelos de Assets.Tools (11/11), com os números e
-- as receitas da config oficial do Starve.
local Defs = require("../src/shared/Defs")

local TOOLS = {
	"diamond_sword",
	"amethyst_sword",
	"reidite_sword",
	"dragon_sword",
	"lava_sword",
	"pirate_sword",
	"diamond_spear",
	"amethyst_spear",
	"reidite_spear",
	"dragon_spear",
	"lava_spear",
	"crab_spear",
	"stone_hammer",
	"gold_hammer",
	"diamond_hammer",
	"amethyst_hammer",
	"reidite_hammer",
	"super_hammer",
	"wood_shield",
	"stone_shield",
	"gold_shield",
	"diamond_shield",
	"amethyst_shield",
	"reidite_shield",
	"stone_shovel",
	"gold_shovel",
	"diamond_shovel",
	"amethyst_shovel",
	"pitchfork",
	"gold_pitchfork",
	"watering_can",
	"machete",
	"wrench",
}

local RELEASED = {
	stone_hammer = true,
	gold_hammer = true,
	wood_shield = true,
	stone_shield = true,
	gold_shield = true,
	wrench = true,
}

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
	["every tool model is an item"] = function()
		for _, id in TOOLS do
			local def = Defs.Items[id]
			assert(def ~= nil, `falta o item {id}`)
			assert(def.category == "weapon" or def.category == "tool", `{id}: arma ou ferramenta`)
			assert(def.maxStack == 1, `{id}: maxStack 1`)
		end
	end,

	["tool release list"] = function()
		for _, id in TOOLS do
			local released = Defs.Items[id].testOnly ~= true
			assert(released == (RELEASED[id] == true), `{id}: liberado = {released}`)
		end
		for _, id in { "dragon_orb", "lava_orb", "pitchfork_part" } do
			local def = Defs.Items[id]
			assert(def ~= nil and def.testOnly == true, `{id} devia existir só para teste`)
		end
	end,

	["starve numbers spot check"] = function()
		local lava = Defs.Items.lava_sword
		assert(lava.mobDamage == 33, "espada de lava 33")
		assert(lava.gearBonus and lava.gearBonus.set == "lava" and lava.gearBonus.damage == 3, "+3 com lava")
		local spear = Defs.Items.dragon_spear
		assert(spear.gearBonus and spear.gearBonus.set == "dragon" and spear.gearBonus.damage == 2, "+2 com dragão")
		local reidite = Defs.Items.reidite_hammer
		assert(
			reidite.structureDamage == 70 and reidite.hammer and reidite.hammer.minDamage == 70,
			"martelo de reidite"
		)
		local stone = Defs.Items.stone_hammer
		assert(stone.mobDamage == 2 and stone.structureDamage == 20, "martelo de pedra")
		assert(stone.hammer and stone.hammer.minDamage == 5 and stone.moveSpeed == nil, "mínimo 5, não deixa lento")
		local shield = Defs.Items.gold_shield
		assert(shield.shield and shield.shield.defense == 3 and shield.shield.mobDefense == 8, "escudo de ouro 3/8")
		assert(shield.mobDamage == 3 and shield.moveSpeed == nil, "bate 3 e não deixa lento")
		assert(Defs.Items.wrench.repair == 70, "chave conserta 70")
		assert(Defs.Items.diamond_spear.attackAnim == "thrust", "lança estoca")
	end,

	["starve recipes"] = function()
		local hammer = counts("stone_hammer")
		assert(hammer.wood == 90 and hammer.stone == 50, "martelo: 90 madeira, 50 pedra")
		local shield = counts("gold_shield")
		assert(
			shield.stone_shield == 1 and shield.gold == 50 and shield.stone == 50 and shield.wood == 50,
			"escudo de ouro"
		)
		local super = counts("super_hammer")
		assert(super.water_bucket == 1 and super.kraken_skin == 1 and super.reidite_hammer == 1, "super martelo")
		local pick = counts("diamond_pickaxe")
		assert(
			pick.diamond == 20 and pick.gold == 50 and pick.stone == 80 and pick.gold_pickaxe == 1,
			"picareta do Starve"
		)
		local lava = Defs.Recipes.lava_sword
		assert(lava.alsoNear and #lava.alsoNear == 2, "lava: bancada, fogo e água")
		assert(Defs.Recipes.pirate_sword == nil, "espada pirata sai do baú do tesouro")
		assert(Defs.Recipes.wrench and Defs.Recipes.wrench.station == "workbench", "chave na bancada")
	end,
}
