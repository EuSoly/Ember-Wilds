--!strict
-- Regras das barras de sobrevivência (só números: testável no Lune). O
-- SurvivalService monta o contexto de cada jogador, chama `step` a cada
-- SurvivalConfig.TICK e grava o resultado nos atributos que o HUD lê.
-- Os números ficam em SurvivalConfig; veja docs/guia/sobrevivencia.md.
local ArmorRules = require("./ArmorRules")
local StatNames = require("../StatNames")
local SurvivalConfig = require("../SurvivalConfig")
local Types = require("../Defs/Types")

-- heat: o calor "por cima" do frio (0 = nenhum; só enche com o frio cheio e
-- continuando a esquentar: em cima do fogo, deserto/lava no futuro).
export type Bars = { health: number, hunger: number, cold: number, thirst: number, heat: number }

export type Context = {
	isNight: boolean,
	inWater: boolean,
	nearFire: boolean, -- dentro do raio de calor de uma fogueira (enche o frio)
	onFire: boolean, -- em cima do fogo (passa do frio cheio e enche o calor)
	biomeHeat: number, -- calor do bioma por segundo (0 na floresta)
	oxygen: number, -- 0 a 100 (WaterService)
	mods: ArmorRules.Modifiers,
	biomeColdFactor: number, -- 1 na floresta
}

export type Cause = "hunger" | "cold" | "heat" | "thirst" | "oxygen"

-- damage: vida a tirar neste passo (quem tira é o CharacterService.hurt);
-- cause: a barra que mais tirou (nil sem dano).
export type StepResult = { bars: Bars, damage: number, cause: Cause? }

local MAX = StatNames.StatusMax
local C = SurvivalConfig

local SurvivalRules = {}

-- Chave de Strings da causa de morte de cada barra.
SurvivalRules.CAUSE_KEYS = table.freeze({
	hunger = "death.cause.hunger",
	cold = "death.cause.cold",
	heat = "death.cause.heat",
	thirst = "death.cause.thirst",
	oxygen = "death.cause.drown",
}) :: { [Cause]: string }

-- Ordem de desempate da causa (igual parcela de dano: a primeira ganha).
local CAUSE_ORDER: { Cause } = { "hunger", "cold", "heat", "thirst", "oxygen" }

local function clamp(value: number): number
	return math.clamp(value, 0, MAX)
end

-- nil ou NaN viram `default` (nunca propaga NaN para os atributos).
local function sane(value: number?, default: number?): number
	if type(value) ~= "number" or value ~= value then
		return default or MAX
	end
	return clamp(value)
end

-- Começo de vida: tudo cheio e sem calor.
function SurvivalRules.full(): Bars
	return { health = MAX, hunger = MAX, cold = MAX, thirst = MAX, heat = 0 }
end

function SurvivalRules.step(bars: Bars, ctx: Context, dt: number): StepResult
	if not (dt > 0) then
		dt = 0
	end
	local mods = ctx.mods
	local health = sane(bars.health)
	local hunger = sane(bars.hunger)
	local cold = sane(bars.cold)
	local thirst = sane(bars.thirst)
	local heat = sane(bars.heat, 0)

	-- 1. Barras.
	hunger = clamp(hunger - C.HUNGER_DRAIN * mods.hungerFactor * dt)
	if ctx.inWater then
		thirst = clamp(thirst + C.WATER_THIRST_REFILL * dt)
	else
		thirst = clamp(thirst - C.THIRST_DRAIN * mods.thirstFactor * dt)
	end
	-- Temperatura: o calor fica "por cima" do frio.
	local heating = (if ctx.onFire then C.ON_FIRE_HEAT else 0) + ctx.biomeHeat
	if heating > 0 then
		-- Esquentando: enche o frio e o que passa do topo enche o calor.
		local warmed = cold + heating * dt
		cold = clamp(warmed)
		heat = clamp(heat + math.max(warmed - MAX, 0) * mods.heatFactor)
	elseif heat > 0 then
		-- Saiu do calor: esfria primeiro o calor; o frio só cai depois.
		heat = clamp(heat - C.HEAT_COOL * dt)
	elseif ctx.nearFire then
		cold = clamp(cold + C.FIRE_WARMTH * dt)
	else
		local drain = (if ctx.isNight then C.COLD_DRAIN_NIGHT else C.COLD_DRAIN_DAY)
			* ctx.biomeColdFactor
			* mods.coldFactor
		if ctx.inWater then
			drain *= C.WATER_COLD_FACTOR
		end
		cold = clamp(cold - drain * dt)
	end

	-- 2. Dano das barras vazias (somados; a causa é a maior parcela).
	local parts: { [string]: number } = {
		hunger = if hunger <= 0 then C.HUNGER_EMPTY_DAMAGE * dt else 0,
		cold = if cold <= 0 then C.COLD_EMPTY_DAMAGE * dt else 0,
		heat = if heat >= MAX then C.HEAT_FULL_DAMAGE * dt else 0,
		thirst = if thirst <= 0 then C.THIRST_EMPTY_DAMAGE * dt else 0,
		oxygen = if ctx.oxygen <= 0 then C.OXYGEN_EMPTY_DAMAGE * dt else 0,
	}
	local damage = 0
	local cause: Cause? = nil
	local biggest = 0
	for _, name in CAUSE_ORDER do
		local part = parts[name :: any]
		damage += part
		if part > biggest then
			biggest = part
			cause = name :: any
		end
	end

	-- 3. Regeneração: sem dano agora, fome, frio e sede no mínimo e sem calor demais.
	if
		damage == 0
		and hunger >= C.REGEN_MIN
		and cold >= C.REGEN_MIN
		and thirst >= C.REGEN_MIN
		and heat < C.REGEN_MAX_HEAT
	then
		health = clamp(health + C.REGEN_RATE * dt)
	end

	return {
		bars = { health = health, hunger = hunger, cold = cold, thirst = thirst, heat = heat },
		damage = damage,
		cause = cause,
	}
end

-- Barras depois de comer `food`; nil se nada do que a comida repõe aumentaria
-- (tudo já cheio: não desperdiça a comida).
function SurvivalRules.eat(bars: Bars, food: Types.FoodEffect): Bars?
	local after: Bars = {
		health = sane(bars.health),
		hunger = sane(bars.hunger),
		cold = sane(bars.cold),
		thirst = sane(bars.thirst),
		heat = sane(bars.heat, 0),
	}
	local gained = false
	local function add(field: "health" | "hunger" | "thirst", amount: number?)
		if amount == nil then
			return
		end
		local before = after[field]
		after[field] = clamp(before + amount)
		if after[field] > before then
			gained = true
		end
	end
	add("hunger", food.hunger)
	add("thirst", food.thirst)
	add("health", food.health)
	return if gained then after else nil
end

return SurvivalRules
