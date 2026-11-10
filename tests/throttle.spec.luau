--!strict
local Throttle = require("../src/shared/Shop/Throttle")

return {
	["first request passes and a fast second one is dropped"] = function()
		local t = Throttle.new(0.3)
		assert(Throttle.allow(t, "p1", "spin", 10), "primeiro passa")
		assert(not Throttle.allow(t, "p1", "spin", 10.1), "segundo rápido demais")
		assert(Throttle.allow(t, "p1", "spin", 10.3), "depois do intervalo passa")
	end,

	["buying does not block spinning right after"] = function()
		local t = Throttle.new(0.3)
		assert(Throttle.allow(t, "p1", "purchase", 5), "compra")
		assert(Throttle.allow(t, "p1", "spin", 5.05), "giro logo depois da compra não é descartado")
	end,

	["players do not block each other"] = function()
		local t = Throttle.new(0.3)
		assert(Throttle.allow(t, "p1", "spin", 1), "jogador 1")
		assert(Throttle.allow(t, "p2", "spin", 1.01), "jogador 2 independente")
	end,

	["forget clears a player"] = function()
		local t = Throttle.new(0.3)
		Throttle.allow(t, "p1", "spin", 1)
		Throttle.forget(t, "p1")
		assert(Throttle.allow(t, "p1", "spin", 1.01), "esquecido pode de novo")
	end,
}
