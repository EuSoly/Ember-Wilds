--!strict
local ProfileFormat = require("../src/shared/UIFlow/ProfileFormat")

return {
	["thousands põe ponto a cada três casas"] = function()
		local cases = {
			{ 0, "0" },
			{ 999, "999" },
			{ 1000, "1.000" },
			{ 18300.7, "18.300" },
			{ 1234567, "1.234.567" },
		}
		for _, case in cases do
			local got = ProfileFormat.thousands(case[1] :: number)
			assert(got == case[2], `{case[1]}: {got}`)
		end
	end,

	["thousands com número inválido mostra zero"] = function()
		assert(ProfileFormat.thousands(0 / 0) == "0", "NaN")
		assert(ProfileFormat.thousands(-5) == "0", "negativo")
		assert(ProfileFormat.thousands(math.huge) == "0", "infinito")
	end,

	["playtime em horas e minutos"] = function()
		local cases = {
			{ 45 * 60, "45min" },
			{ 3600, "1h 0min" },
			{ 45000, "12h 30min" },
			{ 59, "0min" },
			{ -3, "0min" },
			{ 0 / 0, "0min" },
		}
		for _, case in cases do
			local got = ProfileFormat.playtime(case[1] :: number)
			assert(got == case[2], `{case[1]}: {got}`)
		end
	end,
}
