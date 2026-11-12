--!strict
-- Construções com os números da config oficial do Starve (11/11).
local Defs = require("../src/shared/Defs")

local TIERS = { "wood", "stone", "gold", "diamond", "amethyst", "reidite" }
local WALL_LIFE = { 1000, 1500, 2000, 2500, 3500, 4000 }
local SPIKE_LIFE = { 150, 300, 600, 1200, 2400, 3000 }
local SPIKE_TOUCH = { 10, 20, 30, 40, 50, 60 }
local SPIKE_HIT = { 2, 3, 3, 4, 4, 5 }
local SPIKE_DOOR_LIFE = { 100, 200, 400, 800, 1600, 2000 }
local SPIKE_DOOR_TOUCH = { 5, 10, 15, 25, 30, 35 }
local SPIKE_DOOR_HIT = { 1, 2, 2, 3, 3, 4 }

local RELEASED = {
	"well", -- 12/11 (receita do Starve: 100 pedras + 30 terras)
	"wood_spike_door",
	"stone_spike_door",
	"gold_spike_door",
	"stone_extractor",
	"gold_extractor",
	"furnace",
	"bridge",
	"roof",
	"sign",
	"bed",
	"totem",
}
local TEST_ONLY = {
	"diamond_wall",
	"diamond_door",
	"diamond_spike",
	"diamond_spike_door",
	"diamond_extractor",
	"amethyst_wall",
	"amethyst_door",
	"amethyst_spike",
	"amethyst_spike_door",
	"amethyst_extractor",
	"reidite_extractor",
	"resurrection_stone",
	"emerald_machine",
	"emerald",
	"sandworm_juice",
}

local function structure(id: string): any
	local def = Defs.Items[id]
	assert(def ~= nil and def.structure ~= nil, `falta a construção {id}`)
	return def.structure
end

local function counts(id: string): { [string]: number }
	local recipe = Defs.Recipes[id]
	assert(recipe ~= nil, `sem receita: {id}`)
	local out = {}
	for _, part in recipe.ingredients do
		out[part.id] = part.count
	end
	return out
end

return {
	["walls doors and spikes follow the starve ladder"] = function()
		for i, tier in TIERS do
			assert(structure(tier .. "_wall").health == WALL_LIFE[i], `{tier}_wall`)
			assert(structure(tier .. "_door").health == WALL_LIFE[i], `{tier}_door`)
			local spike = structure(tier .. "_spike")
			assert(spike.health == SPIKE_LIFE[i] and spike.spikeDamage == SPIKE_TOUCH[i], `{tier}_spike`)
			assert(spike.spikeHitDamage == SPIKE_HIT[i], `{tier}_spike hit`)
			local door = structure(tier .. "_spike_door")
			assert(door.health == SPIKE_DOOR_LIFE[i] and door.spikeDamage == SPIKE_DOOR_TOUCH[i], `{tier}_spike_door`)
			assert(door.spikeHitDamage == SPIKE_DOOR_HIT[i], `{tier}_spike_door hit`)
		end
	end,

	["extractors follow the starve numbers"] = function()
		for _, tier in { "stone", "gold", "diamond", "amethyst", "reidite" } do
			local s = structure(tier .. "_extractor")
			assert(s.health == 2000, `{tier}: vida 2000`)
			local e = s.extractor
			assert(e.output == tier, `{tier}: produz {tier}`)
			assert(e.woodPerCycle == 2 and e.cycleSeconds == 10 and e.yield == 1, `{tier}: ciclo`)
			assert(e.maxWood == 255 and e.maxStock == 255, `{tier}: capacidade`)
		end
	end,

	["release list"] = function()
		for _, id in RELEASED do
			assert(Defs.Items[id] ~= nil and Defs.Items[id].testOnly ~= true, `{id} devia estar liberado`)
		end
		for _, id in TEST_ONLY do
			assert(Defs.Items[id] ~= nil and Defs.Items[id].testOnly == true, `{id} devia ser só de teste`)
		end
	end,

	["new structures and their life"] = function()
		assert(structure("totem").kind == "totem", "totem")
		for _, id in { "totem", "resurrection_stone", "emerald_machine" } do
			assert(structure(id).maxPerPlayer == 1, `{id}: uma por jogador`)
		end
		assert(structure("resurrection_stone").kind == "resurrection", "pedra")
		assert(structure("resurrection_stone").health == 200, "pedra: 200")
		assert(structure("emerald_machine").kind == "emerald_machine", "máquina")
		assert(structure("emerald_machine").health == 1000, "máquina: 1000")
		assert(structure("furnace").health == 1000, "fornalha: 1000")
		assert(structure("bed").health == 400, "cama: 400")
	end,

	["starve recipes"] = function()
		local stone = counts("stone_extractor")
		assert(stone.wood == 50 and stone.stone == 100, "extrator de pedra")
		local gold = counts("gold_extractor")
		assert(gold.stone == 60 and gold.gold == 120, "extrator de ouro")
		assert(counts("totem").wood == 50, "totem: 50 madeira")
		local res = counts("resurrection_stone")
		assert(res.diamond == 40 and res.stone == 45, "pedra da ressurreição")
		local machine = counts("emerald_machine")
		assert(machine.resurrection_stone == 1 and machine.emerald == 40 and machine.sandworm_juice == 1, "máquina")
		local alsoNear = Defs.Recipes.emerald_machine.alsoNear
		assert(alsoNear and #alsoNear == 2, "máquina: bancada, fogo e água")
		local furnace = counts("furnace")
		assert(furnace.wood == 150 and furnace.stone == 50 and furnace.gold == 15, "fornalha")
		assert(counts("bridge").wood == 15 and counts("roof").wood == 30 and counts("sign").wood == 20, "madeiras")
		local wall = counts("diamond_wall")
		assert(wall.gold_wall == 1 and wall.diamond == 11, "parede de diamante")
		local spike = counts("amethyst_spike")
		assert(spike.amethyst_wall == 1 and spike.amethyst == 40 and spike.stone == 30, "espinho de ametista")
	end,
}
