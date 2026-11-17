--!strict
local CurrencyRules = require("../src/shared/Data/CurrencyRules")

local function emptyData(): CurrencyRules.CurrencyData
	return { Balance = 0, HourWindowStart = 0, HourEarned = 0 }
end

return {
	["points convert without per-life cap"] = function()
		assert(CurrencyRules.pointsToCurrency(9_000_000, 1) == 9000, "sem teto por vida")
		assert(CurrencyRules.pointsToCurrency(12345, 1) == 12, "12345 → 12")
		assert(CurrencyRules.pointsToCurrency(999, 1) == 0, "999 pontos não dão moeda")
	end,

	["multiplier is applied before flooring"] = function()
		assert(CurrencyRules.pointsToCurrency(1500, 2.7) == 4, "1,5 × 2,7 = 4,05")
		assert(CurrencyRules.pointsToCurrency(999, 2.7) == 2, "0,999 × 2,7 = 2,69")
	end,

	["bad multiplier counts as 1"] = function()
		assert(CurrencyRules.pointsToCurrency(5000, 0 / 0) == 5, "NaN")
		assert(CurrencyRules.pointsToCurrency(5000, -3) == 5, "negativo")
	end,

	["bad points give zero"] = function()
		assert(CurrencyRules.pointsToCurrency(0 / 0, 2) == 0, "NaN")
		assert(CurrencyRules.pointsToCurrency(-10, 2) == 0, "negativo")
	end,

	["strange points never give currency"] = function()
		assert(CurrencyRules.pointsToCurrency(-5, 1) == 0, "negativo")
		assert(CurrencyRules.pointsToCurrency(0 / 0, 1) == 0, "NaN")
		assert(CurrencyRules.pointsToCurrency(math.huge, 1) == 0, "infinito")
		assert(CurrencyRules.pointsToCurrency(-math.huge, 1) == 0, "menos infinito")
	end,

	["earn has no hourly cap"] = function()
		local d = emptyData()
		assert(CurrencyRules.earn(d, 10_000, 1000) == 10_000, "primeiro ganho inteiro")
		assert(CurrencyRules.earn(d, 10_000, 1000) == 10_000, "segundo no mesmo instante")
		assert(d.Balance == 20_000, `saldo {d.Balance}`)
	end,

	["earn ignores invalid amounts"] = function()
		local d = emptyData()
		assert(CurrencyRules.earn(d, -3, 100) == 0, "negativo")
		assert(CurrencyRules.earn(d, 2.5, 100) == 0, "não inteiro")
		assert(CurrencyRules.earn(d, 0 / 0, 100) == 0, "NaN")
		assert(CurrencyRules.earn(d, math.huge, 100) == 0, "infinito")
		assert(d.Balance == 0, `saldo {d.Balance}`)
	end,

	["spend needs enough balance"] = function()
		local d = emptyData()
		d.Balance = 50
		assert(CurrencyRules.spend(d, 80) == false, "gastar mais que o saldo falha")
		assert(d.Balance == 50, "saldo igual depois da falha")
		assert(CurrencyRules.spend(d, 20) == true, "gasto válido")
		assert(d.Balance == 30, `saldo {d.Balance}`)
		assert(CurrencyRules.spend(d, -1) == false, "gasto negativo falha")
		assert(CurrencyRules.spend(d, 1.5) == false, "gasto não inteiro falha")
		assert(d.Balance == 30, "saldo igual depois de gastos inválidos")
	end,

	["grant adds to the balance"] = function()
		local d = emptyData()
		assert(CurrencyRules.grant(d, 1000) == true, "grant válido")
		assert(d.Balance == 1000, `saldo {d.Balance}`)
		assert(CurrencyRules.grant(d, -1) == false, "grant negativo falha")
		assert(CurrencyRules.grant(d, 0 / 0) == false, "grant NaN falha")
		assert(d.Balance == 1000, "saldo igual depois de grants inválidos")
	end,
}
