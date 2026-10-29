--!strict
local CurrencyRules = require("../src/shared/Data/CurrencyRules")

local function emptyData(): CurrencyRules.CurrencyData
	return { Balance = 0, HourWindowStart = 0, HourEarned = 0 }
end

return {
	["points convert with the per-life cap"] = function()
		assert(CurrencyRules.pointsToCurrency(12345) == 12, `12345 → {CurrencyRules.pointsToCurrency(12345)}`)
		assert(CurrencyRules.pointsToCurrency(800000) == 500, `800000 → {CurrencyRules.pointsToCurrency(800000)}`)
		assert(CurrencyRules.pointsToCurrency(999) == 0, "999 pontos não dão moeda")
	end,

	["strange points never give currency"] = function()
		assert(CurrencyRules.pointsToCurrency(-5) == 0, "negativo")
		assert(CurrencyRules.pointsToCurrency(0 / 0) == 0, "NaN")
		assert(CurrencyRules.pointsToCurrency(math.huge) == 0, "infinito")
		assert(CurrencyRules.pointsToCurrency(-math.huge) == 0, "menos infinito")
	end,

	["earn respects the hourly cap and window"] = function()
		local d = emptyData()
		assert(CurrencyRules.earn(d, 500, 1000) == 300, "primeiro ganho limitado a 300")
		assert(d.Balance == 300, `saldo {d.Balance}`)
		assert(d.HourWindowStart == 1000, `janela começou em {d.HourWindowStart}`)
		assert(CurrencyRules.earn(d, 10, 1500) == 0, "teto da hora já atingido")
		assert(d.Balance == 300, "saldo não muda sem ganho")
		assert(CurrencyRules.earn(d, 10, 1000 + 3600) == 10, "janela nova depois de 1 h")
		assert(d.Balance == 310, `saldo {d.Balance}`)
		assert(d.HourEarned == 10, `ganho da hora {d.HourEarned}`)
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

	["grant ignores the hourly cap"] = function()
		local d = emptyData()
		assert(CurrencyRules.grant(d, 1000) == true, "grant válido")
		assert(d.Balance == 1000, `saldo {d.Balance}`)
		assert(d.HourEarned == 0, "grant não conta no teto por hora")
		assert(CurrencyRules.grant(d, -1) == false, "grant negativo falha")
		assert(CurrencyRules.grant(d, 0 / 0) == false, "grant NaN falha")
		assert(d.Balance == 1000, "saldo igual depois de grants inválidos")
	end,
}
