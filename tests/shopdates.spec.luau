--!strict
local ShopDates = require("../src/shared/Shop/ShopDates")

return {
	["parse reads Brasilia time (UTC-3)"] = function()
		assert(ShopDates.parse("2026-11-09 00:00") == 1794193200, "00:00 em Brasília = 03:00 UTC")
	end,

	["parse crosses month ends"] = function()
		local before = ShopDates.parse("2026-02-28 23:59")
		local after = ShopDates.parse("2026-03-01 00:00")
		assert(before ~= nil and after ~= nil and after - before == 60, "fevereiro de 2026 tem 28 dias")
	end,

	["parse accepts a leap day"] = function()
		local leap = ShopDates.parse("2028-02-29 12:00")
		local next = ShopDates.parse("2028-03-01 12:00")
		assert(leap ~= nil and next ~= nil and next - leap == 86400, "29/02/2028 existe")
	end,

	["parse rejects badly written dates"] = function()
		for _, text in
			{
				"2026-13-01 00:00",
				"2026-02-30 10:00",
				"2026-11-09",
				"09/11/2026 10:00",
				"2026-11-09 24:00",
				"2026-11-09 10:60",
			}
		do
			assert(ShopDates.parse(text) == nil, `deveria recusar "{text}"`)
		end
	end,

	["isOpen without dates is always open"] = function()
		assert(ShopDates.isOpen(nil, nil, 0), "sem datas = aberto")
	end,

	["isOpen includes the start and excludes the end"] = function()
		assert(ShopDates.isOpen(100, 200, 100), "abre no começo")
		assert(not ShopDates.isOpen(100, 200, 200), "fecha no fim")
		assert(not ShopDates.isOpen(100, nil, 99), "antes do começo está fechado")
		assert(ShopDates.isOpen(nil, 200, 199), "sem começo vale até o fim")
	end,

	["dayMonth shows Brasilia day"] = function()
		local noon = ShopDates.parse("2026-12-17 12:00") :: number
		assert(ShopDates.dayMonth(noon) == "17/12", ShopDates.dayMonth(noon))
		-- 01:00 UTC ainda é o dia anterior em Brasília.
		local late = ShopDates.parse("2027-03-01 00:30") :: number
		assert(ShopDates.dayMonth(late) == "01/03", ShopDates.dayMonth(late))
		assert(ShopDates.dayMonth(late - 3600) == "28/02", ShopDates.dayMonth(late - 3600))
		local leap = ShopDates.parse("2028-02-29 23:59") :: number
		assert(ShopDates.dayMonth(leap) == "29/02", "ano bissexto")
	end,

	["clock formats mm:ss and h:mm:ss"] = function()
		assert(ShopDates.clock(0) == "00:00", "zero")
		assert(ShopDates.clock(59.2) == "01:00", "arredonda para cima")
		assert(ShopDates.clock(754) == "12:34", "mm:ss")
		assert(ShopDates.clock(3600) == "1:00:00", "1 h")
		assert(ShopDates.clock(-5) == "00:00", "negativo")
	end,
}
