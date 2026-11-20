--!strict
local BotBrain = require("../src/shared/Bots/BotBrain")
local BotLadder = require("../src/shared/Bots/BotLadder")

-- Bot saudável de dia, sem nada por perto; cada teste muda o que precisa.
local function snap(changes: { [string]: any }?): BotBrain.Snapshot
	local s: any = {
		health = 200,
		hunger = 100,
		cold = 100,
		isNight = false,
		nearFire = false,
		fireNearby = false,
		counts = {},
		nearStation = {},
		provoker = nil,
		threat = false,
		hasWeapon = false,
		food = nil,
		stuckSeconds = 0,
	}
	for k, v in changes or {} do
		s[k] = v
	end
	return s :: BotBrain.Snapshot
end

local function expect(d: BotBrain.Decision, goal: string, item: string?)
	assert(d.goal == goal, `objetivo: esperava {goal}, veio {d.goal}`)
	if item ~= nil then
		assert(d.item == item, `item: esperava {item}, veio {d.item}`)
	end
end

return {
	["provoked: fights back, flees when weak"] = function()
		local who = {}
		expect(BotBrain.decide(snap({ provoker = who })), "fight")
		expect(BotBrain.decide(snap({ provoker = who, health = 50 })), "flee")
	end,

	["mob nearby: flees unarmed, fights armed and healthy"] = function()
		expect(BotBrain.decide(snap({ threat = true })), "flee")
		expect(BotBrain.decide(snap({ threat = true, hasWeapon = true })), "fight")
		expect(BotBrain.decide(snap({ threat = true, hasWeapon = true, health = 80 })), "flee")
	end,

	["night: places a campfire with materials, else gathers what is missing"] = function()
		expect(BotBrain.decide(snap({ isNight = true, counts = { wood = 30, stone = 5 } })), "place", "campfire")
		expect(
			BotBrain.decide(snap({ isNight = true, counts = { wood = 30, stone = 1, wood_pickaxe = 1 } })),
			"gather",
			"stone"
		)
		expect(BotBrain.decide(snap({ isNight = true, counts = {} })), "gather", "wood")
	end,

	["stone needs a pickaxe: crafts the wood pickaxe first"] = function()
		expect(BotBrain.decide(snap({ isNight = true, counts = { wood = 30 } })), "craft", "wood_pickaxe")
		expect(BotBrain.decide(snap({ isNight = true, counts = { wood = 5 } })), "gather", "wood")
		expect(BotBrain.decide(snap({ isNight = true, counts = { wood = 30, wood_pickaxe = 1 } })), "gather", "stone")
	end,

	["night or cold: walks to a fire nearby, stays by the fire"] = function()
		expect(BotBrain.decide(snap({ isNight = true, fireNearby = true })), "warm")
		expect(BotBrain.decide(snap({ cold = 30, fireNearby = true })), "warm")
		expect(BotBrain.decide(snap({ isNight = true, nearFire = true })), "warm")
	end,

	["hungry: eats food, hunts armed, else gathers berries"] = function()
		expect(BotBrain.decide(snap({ hunger = 30, food = "berry" })), "eat", "berry")
		expect(BotBrain.decide(snap({ hunger = 30, hasWeapon = true })), "hunt")
		expect(BotBrain.decide(snap({ hunger = 30 })), "gather", "berry")
	end,

	["ladder: crafts when it has the materials, else gathers them"] = function()
		expect(BotBrain.decide(snap({ counts = { wood = 10 } })), "craft", "wood_pickaxe")
		expect(BotBrain.decide(snap({ counts = { wood = 3 } })), "gather", "wood")
	end,

	["ladder: places the workbench a recipe needs"] = function()
		local counts = { wood_pickaxe = 1, wood_sword = 1, wood = 80, stone = 25 }
		expect(BotBrain.decide(snap({ counts = counts })), "place", "workbench")
		expect(BotBrain.decide(snap({ counts = counts, nearStation = { workbench = true } })), "craft", "stone_pickaxe")
	end,

	["stuck gathering: wanders to pick another spot"] = function()
		expect(BotBrain.decide(snap({ counts = { wood = 3 }, stuckSeconds = 6 })), "wander")
	end,

	["ladder done: keeps gathering for points"] = function()
		local all = {}
		for _, id in BotLadder.STEPS do
			all[id] = 1
		end
		expect(BotBrain.decide(snap({ counts = all })), "gather")
	end,

	["ladder.next: in order, skips upgraded items, nil when done"] = function()
		assert(BotLadder.next({}) == "wood_pickaxe", "começa pela picareta")
		assert(BotLadder.next({ stone_pickaxe = 1 }) == "wood_sword", "picareta de pedra já cobre a de madeira")
		local all = {}
		for _, id in BotLadder.STEPS do
			all[id] = 1
		end
		assert(BotLadder.next(all) == nil, "escada completa")
		for _, id in BotLadder.STEPS do
			assert(id ~= "gold_pickaxe" and id ~= "campfire" and id ~= "workbench", `fora da escada: {id}`)
		end
	end,

	["ladder.missing: raw ingredients still needed"] = function()
		local missing = BotLadder.missing("stone_pickaxe", { wood = 20, stone = 15, wood_pickaxe = 1 })
		assert(missing.wood == 30, `madeira: {missing.wood}`)
		assert(missing.stone == nil, "pedra completa")
		assert(missing.wood_pickaxe == nil, "picareta de madeira completa")
	end,
}
