--!strict
local ResetRules = require("../src/shared/Survival/ResetRules")

return {
	["reset waits ten seconds standing still"] = function()
		assert(ResetRules.SECONDS == 10, "10 s")
		-- Só conta o chão (X e Z): pular no lugar não cancela.
		assert(ResetRules.moved(10, 10, 10, 10) == false, "parado")
		assert(ResetRules.moved(10, 10, 10.5, 10.5) == false, "balanço pequeno não conta")
		assert(ResetRules.moved(10, 10, 13, 10), "andou")
		assert(not ResetRules.done(9.9) and ResetRules.done(10), "termina nos 10 s")
	end,
}
