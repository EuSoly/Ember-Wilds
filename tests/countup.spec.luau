--!strict
local CountUp = require("../src/shared/UIFlow/CountUp")

local function check(t: number, expectedPoints: number, expectedCurrency: number)
	local points, currency = CountUp.at(t, 2, 5000, 5)
	assert(
		points == expectedPoints and currency == expectedCurrency,
		`t={t}: ({points}, {currency}), esperado ({expectedPoints}, {expectedCurrency})`
	)
end

return {
	["start, middle and end"] = function()
		check(0, 5000, 0)
		check(1, 2500, 2)
		check(2, 0, 5)
	end,

	["clamped outside the duration"] = function()
		check(3, 0, 5)
		check(-1, 5000, 0)
	end,

	["rounding keeps points up and currency down"] = function()
		local points, currency = CountUp.at(0.5, 2, 5001, 5)
		assert(points == 3751 and currency == 1, `({points}, {currency})`)
		local points2, currency2 = CountUp.at(1.9, 2, 999, 5)
		assert(points2 == 50 and currency2 == 4, `({points2}, {currency2})`)
	end,

	["zero duration jumps to the end"] = function()
		local points, currency = CountUp.at(0, 0, 5000, 5)
		assert(points == 0 and currency == 5, `({points}, {currency})`)
	end,
}
