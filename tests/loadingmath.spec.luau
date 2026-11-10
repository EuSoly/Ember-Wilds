--!strict
local LoadingMath = require("../src/first/LoadingMath")

local FRAME = 1 / 60

local function run(progress: number, frames: number, ready: boolean): number
	for _ = 1, frames do
		progress = LoadingMath.step(progress, FRAME, ready)
	end
	return progress
end

return {
	["waiting approaches but never passes the target"] = function()
		local p = run(0, 600, false)
		assert(p <= LoadingMath.WAITING_TARGET, `passou do alvo: {p}`)
		assert(p > 0.85, `parou cedo demais: {p}`)
	end,

	["reaches the middle in about two seconds"] = function()
		local p = run(0, 120, false)
		assert(p >= 0.4 and p <= 0.6, `em 2 s veio {p}`)
	end,

	["ready runs to the end through the night"] = function()
		local p = 0.2
		local sawNight = false
		for _ = 1, 600 do
			p = LoadingMath.step(p, FRAME, true)
			assert(p <= 1, `passou de 1: {p}`)
			if LoadingMath.isNight(p) and p < 1 then
				sawNight = true
			end
		end
		assert(p == 1, `não chegou ao fim: {p}`)
		assert(sawNight, "pulou a lua")
	end,

	["status text by phase"] = function()
		assert(LoadingMath.status(0.1) == "Carregando o mundo…", LoadingMath.status(0.1))
		assert(LoadingMath.status(0.5) == "Acendendo as fogueiras…", LoadingMath.status(0.5))
		assert(LoadingMath.status(1) == "Pronto!", LoadingMath.status(1))
	end,

	["night starts at the middle"] = function()
		assert(not LoadingMath.isNight(0.499), "0.499 ainda é dia")
		assert(LoadingMath.isNight(0.5), "0.5 já é noite")
	end,

	["a slow frame does not skip the sun"] = function()
		-- Primeiro quadro de 3 s num celular lento: a barra não pode pular a metade.
		assert(not LoadingMath.isNight(LoadingMath.step(0, 3, false)), "pulou o sol")
	end,

	["big dt is clamped"] = function()
		assert(LoadingMath.step(0, 10, false) <= LoadingMath.WAITING_TARGET, "dt grande passou do alvo")
		assert(LoadingMath.step(0.95, 10, true) == 1, "pronto com dt grande deveria ir a 1")
	end,
	["a target below the default holds the bar there"] = function()
		local p = 0
		for _ = 1, 600 do
			p = LoadingMath.step(p, FRAME, false, 0.3)
		end
		assert(p <= 0.3 and p > 0.28, `segue o alvo das artes: {p}`)
	end,

	["asset target grows with the assets loaded"] = function()
		assert(LoadingMath.assetTarget(0, 0) == LoadingMath.WAITING_TARGET, "sem lista: o alvo de sempre")
		local start = LoadingMath.assetTarget(0, 100)
		local half = LoadingMath.assetTarget(50, 100)
		local all = LoadingMath.assetTarget(100, 100)
		assert(start < half and half < all, "cresce")
		assert(all == LoadingMath.WAITING_TARGET, "tudo carregado: o alvo de sempre")
	end,

	["asset status shows the count with a thousands dot"] = function()
		assert(LoadingMath.assetStatus(312, 1730) == "Carregando artes 312/1.730", LoadingMath.assetStatus(312, 1730))
		assert(LoadingMath.assetStatus(0, 12) == "Carregando artes 0/12", "sem milhar")
	end,
}
