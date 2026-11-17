--!strict
local CombatTag = require("../src/shared/Combat/CombatTag")

-- Tabelas fazem o papel de Player: só a identidade importa.
local function fake(): any
	return {}
end

return {
	["janela é de 10 s"] = function()
		assert(CombatTag.WINDOW == 10, "janela")
	end,
	["killer direto vence o último atacante"] = function()
		local victim, killer, last = fake(), fake(), fake()
		assert(CombatTag.resolve(killer, last, 100, victim, 101) == killer, "killer direto")
	end,
	["sem killer, quem bateu a 9 s conta"] = function()
		local victim, last = fake(), fake()
		assert(CombatTag.resolve(nil, last, 100, victim, 109) == last, "9 s conta")
		assert(CombatTag.resolve(nil, last, 100, victim, 110) == last, "10 s exato conta")
	end,
	["sem killer, quem bateu a 11 s não conta"] = function()
		local victim, last = fake(), fake()
		assert(CombatTag.resolve(nil, last, 100, victim, 111) == nil, "11 s não conta")
	end,
	["o próprio morto nunca conta"] = function()
		local victim = fake()
		assert(CombatTag.resolve(nil, victim, 100, victim, 101) == nil, "last == victim")
		assert(CombatTag.resolve(victim, nil, nil, victim, 101) == nil, "killer == victim")
	end,
	["sem registro devolve nil"] = function()
		assert(CombatTag.resolve(nil, nil, nil, fake(), 100) == nil, "vazio")
		assert(CombatTag.resolve(nil, fake(), nil, fake(), 100) == nil, "sem hora")
	end,
}
