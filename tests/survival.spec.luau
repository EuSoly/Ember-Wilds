--!strict
local ArmorRules = require("../src/shared/Survival/ArmorRules")
local SurvivalConfig = require("../src/shared/SurvivalConfig")
local SurvivalRules = require("../src/shared/Survival/SurvivalRules")

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

local function expect(label: string, got: number, want: number)
	assert(near(got, want), `{label}: veio {got}, esperava {want}`)
end

-- Contexto base: dia, seco, sem fogo, fôlego cheio, sem armadura, floresta.
local function ctx(overrides: { [string]: any }?): SurvivalRules.Context
	local c: any = {
		isNight = false,
		inWater = false,
		nearFire = false,
		oxygen = 100,
		mods = ArmorRules.NONE,
		biomeColdFactor = 1,
	}
	for k, v in overrides or {} do
		c[k] = v
	end
	return c
end

local function bars(overrides: { [string]: any }?): SurvivalRules.Bars
	local b: any = SurvivalRules.full()
	for k, v in overrides or {} do
		b[k] = v
	end
	return b
end

return {
	["config keeps the approved numbers"] = function()
		local approved = {
			TICK = 0.5,
			HUNGER_DRAIN = 0.6,
			THIRST_DRAIN = 0.5,
			COLD_DRAIN_DAY = 0.4,
			COLD_DRAIN_NIGHT = 1.6,
			WATER_COLD_FACTOR = 2,
			WATER_THIRST_REFILL = 5,
			FIRE_WARMTH = 5,
			CAMPFIRE_RADIUS = 12,
			REGEN_MIN = 35,
			REGEN_RATE = 0.5,
			HUNGER_EMPTY_DAMAGE = 1.5,
			COLD_EMPTY_DAMAGE = 1,
			THIRST_EMPTY_DAMAGE = 1,
			OXYGEN_EMPTY_DAMAGE = 1,
			HURT_FLASH_EVERY = 2,
			EAT_INTERVAL = 0.5,
			MAX_DEFENSE = 0.9,
			MAX_FACTOR = 2,
		}
		for key, value in approved do
			assert((SurvivalConfig :: any)[key] == value, `{key} = {(SurvivalConfig :: any)[key]}, aprovado {value}`)
		end
		assert(SurvivalConfig.BIOME_COLD_FACTOR.forest == 1, "floresta = 1")
	end,

	["day drains hunger thirst and cold"] = function()
		local r = SurvivalRules.step(SurvivalRules.full(), ctx(), 10)
		expect("fome", r.bars.hunger, 94)
		expect("sede", r.bars.thirst, 95)
		expect("frio", r.bars.cold, 96)
		expect("vida", r.bars.health, 100)
		expect("dano", r.damage, 0)
		assert(r.cause == nil, "sem causa")
	end,

	["night cold drains four times faster"] = function()
		local r = SurvivalRules.step(SurvivalRules.full(), ctx({ isNight = true }), 10)
		expect("frio", r.bars.cold, 84)
	end,

	["water refills thirst and doubles cold"] = function()
		local r = SurvivalRules.step(bars({ thirst = 50 }), ctx({ inWater = true }), 2)
		expect("sede", r.bars.thirst, 60)
		expect("frio", r.bars.cold, 98.4)
	end,

	["fire warms even at night in water"] = function()
		local r = SurvivalRules.step(bars({ cold = 50 }), ctx({ isNight = true, inWater = true, nearFire = true }), 2)
		expect("frio", r.bars.cold, 60)
	end,

	["armor factors slow the drain"] = function()
		local mods = { defense = 0, coldFactor = 0.5, hungerFactor = 0.5, thirstFactor = 1 }
		local r = SurvivalRules.step(SurvivalRules.full(), ctx({ mods = mods }), 10)
		expect("frio", r.bars.cold, 98)
		expect("fome", r.bars.hunger, 97)
		expect("sede", r.bars.thirst, 95)
	end,

	["biome factor scales the cold"] = function()
		local r = SurvivalRules.step(SurvivalRules.full(), ctx({ biomeColdFactor = 2 }), 10)
		expect("frio", r.bars.cold, 92)
	end,

	["empty hunger hurts and names the cause"] = function()
		local r = SurvivalRules.step(bars({ hunger = 0 }), ctx(), 2)
		expect("dano", r.damage, 3)
		assert(r.cause == "hunger", `causa {r.cause}`)
		expect("vida não muda nas regras", r.bars.health, 100)
	end,

	["empty bars add up"] = function()
		local r = SurvivalRules.step(bars({ hunger = 0, cold = 0, thirst = 0 }), ctx({ oxygen = 0 }), 1)
		expect("dano", r.damage, 4.5)
		assert(r.cause == "hunger", `causa {r.cause}`)
	end,

	["cold wins the cause tie order after hunger"] = function()
		local r = SurvivalRules.step(bars({ cold = 0, thirst = 0 }), ctx(), 1)
		expect("dano", r.damage, 2)
		assert(r.cause == "cold", `causa {r.cause}`)
	end,

	["no oxygen hurts"] = function()
		local r = SurvivalRules.step(SurvivalRules.full(), ctx({ oxygen = 0 }), 1)
		expect("dano", r.damage, 1)
		assert(r.cause == "oxygen", `causa {r.cause}`)
	end,

	["regen needs all bars at 35"] = function()
		local ok = SurvivalRules.step(bars({ health = 50, hunger = 60, cold = 60, thirst = 60 }), ctx(), 10)
		expect("vida com tudo acima de 35", ok.bars.health, 55)
		local hungry = SurvivalRules.step(bars({ health = 50, hunger = 38, cold = 60, thirst = 60 }), ctx(), 10)
		expect("vida com fome abaixo de 35", hungry.bars.health, 50)
	end,

	["no regen while taking damage"] = function()
		local r = SurvivalRules.step(bars({ health = 50 }), ctx({ oxygen = 0 }), 1)
		expect("vida", r.bars.health, 50)
		assert(r.damage > 0, "tomou dano")
	end,

	["bars never leave 0..100"] = function()
		local r = SurvivalRules.step(bars({ hunger = 1 }), ctx(), 100)
		expect("fome", r.bars.hunger, 0)
		local regen = SurvivalRules.step(bars({ health = 99.9 }), ctx(), 100)
		expect("vida", regen.bars.health, 100)
		local water = SurvivalRules.step(bars({ thirst = 99 }), ctx({ inWater = true }), 10)
		expect("sede", water.bars.thirst, 100)
	end,

	["nil or NaN bars count as full"] = function()
		local r =
			SurvivalRules.step({ health = 0 / 0, hunger = nil :: any, cold = 0 / 0, thirst = nil :: any }, ctx(), 1)
		for name, value in r.bars :: any do
			assert(value == value, `{name} virou NaN`)
		end
		expect("fome", r.bars.hunger, 99.4)
		expect("vida", r.bars.health, 100)
	end,

	["bad dt does nothing"] = function()
		for _, dt in { -5, 0 / 0 } do
			local r = SurvivalRules.step(SurvivalRules.full(), ctx(), dt)
			expect("fome", r.bars.hunger, 100)
			expect("dano", r.damage, 0)
		end
	end,

	["eating adds and caps"] = function()
		local a = SurvivalRules.eat(bars({ hunger = 95 }), { hunger = 10 })
		assert(a ~= nil, "come")
		expect("fome", a.hunger, 100)
		assert(SurvivalRules.eat(SurvivalRules.full(), { hunger = 10 }) == nil, "cheio não come")
		local b = SurvivalRules.eat(bars({ thirst = 50 }), { hunger = 10, thirst = 5 })
		assert(b ~= nil, "repõe a sede")
		expect("sede", b.thirst, 55)
		expect("fome", b.hunger, 100)
	end,
}
