--!strict
local EmeraldRules = require("../src/shared/Build/EmeraldRules")

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-9
end

return {
	["750 points per minute"] = function()
		assert(EmeraldRules.POINTS_PER_MINUTE == 750, "floresta: 750/min (config do Starve)")
		assert(near(EmeraldRules.pointsFor(60), 750), "um minuto")
		assert(near(EmeraldRules.pointsFor(1), 12.5), "um segundo")
		assert(EmeraldRules.pointsFor(0) == 0, "parado")
	end,

	["destroyed by someone else kills the owner"] = function()
		assert(EmeraldRules.killsOwner(0, false), "outro destruiu: o dono morre")
		assert(not EmeraldRules.killsOwner(0, true), "o dono (ou aliado) quebrou: ninguém morre")
		assert(not EmeraldRules.killsOwner(1000, false), "saiu com vida (dono morreu ou saiu)")
	end,

	["whole points carry the fraction"] = function()
		local whole, rest = EmeraldRules.split(0.6 + 12.5)
		assert(whole == 13 and near(rest, 0.1), `{whole} e {rest}`)
	end,
}
