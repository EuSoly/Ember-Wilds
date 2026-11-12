--!strict
-- Regras puras das chrono quests (src/shared/Missions/ChronoRules).
local Defs = require("../src/shared/Defs")
local ChronoRules = require("../src/shared/Missions/ChronoRules")

local DAY = 480

local function ids(list: { string }): string
	table.sort(list)
	return table.concat(list, ",")
end

return {
	["start has only enabled quests"] = function()
		local state = ChronoRules.start(Defs)
		local names = {}
		for id, quest in state do
			assert(quest.status == "active", `{id} não começou ativa`)
			table.insert(names, id)
		end
		assert(ids(names) == "clean_hands,survive", `começou com {ids(names)}`)
	end,

	["survive completes at 4 days"] = function()
		local state = ChronoRules.start(Defs)
		assert(#ChronoRules.tick(state, Defs, 4 * DAY - 1) == 0, "completou antes do prazo")
		local done = ChronoRules.tick(state, Defs, 4 * DAY)
		assert(ids(done) == "survive", `completou {ids(done)}`)
		assert(state.survive.status == "done", "survive não ficou pronta")
		assert(#ChronoRules.tick(state, Defs, 4 * DAY + 10) == 0, "avisou duas vezes")
		local later = ChronoRules.tick(state, Defs, 6 * DAY)
		assert(ids(later) == "clean_hands", `aos 6 dias: {ids(later)}`)
	end,

	["getting hurt fails survive only"] = function()
		local state = ChronoRules.start(Defs)
		local failed = ChronoRules.breakRule(state, Defs, "unhurt")
		assert(ids(failed) == "survive", `falhou {ids(failed)}`)
		assert(state.survive.status == "failed" and state.clean_hands.status == "active", "estados")
		assert(#ChronoRules.breakRule(state, Defs, "unhurt") == 0, "falhou duas vezes")
	end,

	["joining a team fails survive only"] = function()
		local state = ChronoRules.start(Defs)
		local failed = ChronoRules.breakRule(state, Defs, "alone")
		assert(ids(failed) == "survive", `falhou {ids(failed)}`)
	end,

	["hitting a neutral mob fails clean hands"] = function()
		assert(ChronoRules.isPeacefulTarget("passive"), "coelho é manso")
		assert(ChronoRules.isPeacefulTarget("neutral"), "javali/falcão contam (até se defendendo)")
		assert(not ChronoRules.isPeacefulTarget("aggressive"), "lobo/aranha podem")
		local state = ChronoRules.start(Defs)
		local failed = ChronoRules.breakRule(state, Defs, "peaceful")
		assert(ids(failed) == "clean_hands", `falhou {ids(failed)}`)
	end,

	["failed quest never completes"] = function()
		local state = ChronoRules.start(Defs)
		ChronoRules.breakRule(state, Defs, "unhurt")
		local done = ChronoRules.tick(state, Defs, 99 * DAY)
		assert(ids(done) == "clean_hands", `completou {ids(done)}`)
		assert(state.survive.status == "failed", "falhada voltou")
	end,

	["done quest is not failed later"] = function()
		local state = ChronoRules.start(Defs)
		ChronoRules.tick(state, Defs, 4 * DAY)
		assert(#ChronoRules.breakRule(state, Defs, "unhurt") == 0, "pronta falhou depois")
		assert(state.survive.status == "done", "pronta mudou")
	end,

	["seconds left counts down to zero"] = function()
		assert(ChronoRules.secondsLeft(Defs.Quests.survive, 0) == 4 * DAY, "no começo")
		assert(ChronoRules.secondsLeft(Defs.Quests.survive, DAY) == 3 * DAY, "depois de 1 dia")
		assert(ChronoRules.secondsLeft(Defs.Quests.survive, 10 * DAY) == 0, "nunca negativo")
	end,

	["chrono claim needs space"] = function()
		local state = ChronoRules.start(Defs)
		ChronoRules.tick(state, Defs, 4 * DAY)
		local def, problem = ChronoRules.claim(state, Defs, "survive", false)
		assert(def == nil and problem == "missions.inventory_full", `veio {problem}`)
		assert(state.survive.status == "done", "sem espaço mudou o estado")
		local ok = ChronoRules.claim(state, Defs, "survive", true)
		assert(ok ~= nil and ok.rewardItem == "green_gem", "resgate com espaço")
	end,

	["chrono claim twice pays once"] = function()
		local state = ChronoRules.start(Defs)
		ChronoRules.tick(state, Defs, 4 * DAY)
		assert(ChronoRules.claim(state, Defs, "survive", true) ~= nil, "primeiro resgate")
		assert(ChronoRules.claim(state, Defs, "survive", true) == nil, "pagou duas vezes")
		assert(state.survive.status == "claimed", "não marcou resgatada")
		assert(ChronoRules.claim(state, Defs, "clean_hands", true) == nil, "resgatou ativa")
		assert(ChronoRules.claim(state, Defs, "dragon", true) == nil, "resgatou desligada")
	end,

	["chrono state ends with the life"] = function()
		local state = ChronoRules.start(Defs)
		ChronoRules.tick(state, Defs, 4 * DAY)
		ChronoRules.claim(state, Defs, "survive", true)
		ChronoRules.breakRule(state, Defs, "peaceful")
		local fresh = ChronoRules.start(Defs)
		assert(fresh.survive.status == "active" and fresh.clean_hands.status == "active", "vida nova não zerou")
	end,

	["becoming a ghost fails every active quest"] = function()
		local state = ChronoRules.start(Defs)
		ChronoRules.tick(state, Defs, 4 * DAY)
		local failed = ChronoRules.failAll(state)
		assert(ids(failed) == "clean_hands", `falhou {ids(failed)}`)
		assert(state.survive.status == "done", "pronta não pode falhar")
	end,
}
