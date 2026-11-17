--!strict
local XpBoost = require("../src/shared/Data/XpBoost")

local function near(a: number, b: number, msg: string)
	assert(math.abs(a - b) < 1e-9, `{msg}: {a} ~= {b}`)
end

return {
	["boost cobrindo metade da vida dá 1,5"] = function()
		near(XpBoost.factor(0, 100, 50, 200), 1.5, "metade")
	end,

	["boost cobrindo a vida inteira dá 2"] = function()
		near(XpBoost.factor(0, 100, -10, 200), 2, "inteiro")
	end,

	["sem interseção dá 1"] = function()
		near(XpBoost.factor(0, 100, 200, 300), 1, "depois")
		near(XpBoost.factor(200, 300, 0, 100), 1, "antes")
	end,

	["vida de duração zero dá 1"] = function()
		near(XpBoost.factor(50, 50, 0, 100), 1, "zero")
		near(XpBoost.factor(80, 50, 0, 100), 1, "invertida")
	end,

	["boost vazio ou invertido dá 1"] = function()
		near(XpBoost.factor(0, 100, 50, 50), 1, "vazio")
		near(XpBoost.factor(0, 100, 80, 20), 1, "invertido")
		near(XpBoost.factor(0, 100, 0, 0), 1, "sem boost")
	end,

	["valores inválidos dão 1"] = function()
		near(XpBoost.factor(0 / 0, 100, 0, 100), 1, "nan")
		near(XpBoost.factor(0, 100, 0, math.huge), 1, "inf")
	end,
}
