--!strict
local ScreenFx = require("../src/shared/UIFlow/ScreenFx")
local StatNames = require("../src/shared/StatNames")

local MAX = StatNames.StatusMax

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

local function stats(overrides: { [string]: number }): ScreenFx.Stats
	local base: ScreenFx.Stats = { hunger = MAX, cold = MAX, heat = 0, thirst = MAX, oxygen = MAX }
	for key, value in overrides do
		(base :: any)[key] = value
	end
	return base
end

return {
	["full bar has no effect"] = function()
		assert(ScreenFx.low(MAX, MAX) == 0, "cheia: sem efeito")
	end,

	["effect starts only below the warning line"] = function()
		assert(ScreenFx.low(StatNames.WarningFraction * MAX, MAX) == 0, "na linha do alerta ainda não")
		local half = ScreenFx.low(StatNames.WarningFraction * MAX / 2, MAX)
		assert(near(half, ScreenFx.LOW_PEAK / 2), `metade do caminho: {half}`)
	end,

	["empty bar is full effect"] = function()
		assert(ScreenFx.low(0, MAX) == 1, "zerada (machucando): efeito cheio")
	end,

	["heat replaces the cold effect"] = function()
		local levels = ScreenFx.levels(stats({ cold = 0, heat = 10 }))
		assert(levels.cold == 0, "com calor não mostra o frio")
	end,

	["full heat is full effect"] = function()
		assert(ScreenFx.levels(stats({ heat = MAX })).heat == 1, "calor cheio: efeito cheio")
		assert(ScreenFx.levels(stats({ heat = 0 })).heat == 0, "sem calor: nada")
	end,

	["each low bar has its own effect"] = function()
		local levels = ScreenFx.levels(stats({ hunger = 0, thirst = 0, oxygen = 0 }))
		assert(levels.hunger == 1 and levels.thirst == 1 and levels.oxygen == 1, "fome, sede e fôlego zerados")
		assert(levels.cold == 0, "frio cheio continua sem efeito")
	end,

	["damage flash fades out"] = function()
		assert(ScreenFx.flash(0) == 1, "na hora do golpe: cheio")
		assert(near(ScreenFx.flash(ScreenFx.FLASH_TIME / 2), 0.5), "no meio: metade")
		assert(ScreenFx.flash(ScreenFx.FLASH_TIME) == 0, "no fim: some")
		assert(ScreenFx.flash(99) == 0, "muito depois: nada")
	end,

	["only a drop in health is a hit"] = function()
		assert(ScreenFx.hit(nil, 100) == false, "primeira leitura não é golpe")
		assert(ScreenFx.hit(100, 90) == true, "caiu: golpe")
		assert(ScreenFx.hit(90, 100) == false, "subiu (comeu, curou): não é golpe")
		assert(ScreenFx.hit(90, 90) == false, "igual: nada")
	end,
}
