--!strict
local Strings = require("../src/shared/Strings")
local TutorialRules = require("../src/shared/Tutorial/TutorialRules")
local TutorialSteps = require("../src/shared/Tutorial/TutorialSteps")

local LIST = TutorialSteps.LIST

local function facts(counts: { [string]: number }?): TutorialRules.Facts
	return { counts = counts or {}, placed = {}, viewed = {}, wetSeconds = 0 }
end

local function step(id: string): TutorialSteps.Step
	for _, s in LIST do
		if s.id == id then
			return s
		end
	end
	error("etapa " .. id .. " não existe")
end

return {
	["six_steps_in_order"] = function()
		local ids = {}
		for _, s in LIST do
			table.insert(ids, s.id)
			assert(Strings.has(s.textKey), "texto da etapa " .. s.id .. " existe")
		end
		assert(table.concat(ids, ",") == "wood,pickaxe,berries,book,campfire,water", "ordem das etapas")
	end,

	["have_counts_inventory"] = function()
		local have, need = TutorialRules.progress(LIST[1], facts({ wood = 7 }))
		assert(have == 7 and need == 10, "7/10")
		assert(not TutorialRules.isDone(LIST[1], facts({ wood = 7 })), "7 madeiras ainda não")
		have, need = TutorialRules.progress(LIST[1], facts({ wood = 12 }))
		assert(have == 10 and need == 10, "não passa da meta")
		assert(TutorialRules.isDone(LIST[1], facts({ wood = 12 })), "12 madeiras completa")
	end,

	["advances_one_step_per_check"] = function()
		local f = facts({ wood = 10, wood_pickaxe = 1, berry = 5 })
		assert(TutorialRules.advance(1, f) == 2, "1 → 2")
		assert(TutorialRules.advance(2, f) == 3, "2 → 3")
		assert(TutorialRules.advance(3, f) == 4, "3 → 4")
		assert(TutorialRules.advance(4, f) == 4, "4 espera o livro")
	end,

	["view_and_place_and_drink"] = function()
		local f = facts()
		f.viewed.campfire = true
		assert(TutorialRules.isDone(step("book"), f), "ver a fogueira completa o livro")
		f.placed.campfire = true
		assert(TutorialRules.isDone(step("campfire"), f), "colocar a fogueira completa")
		f.wetSeconds = 1.4
		assert(not TutorialRules.isDone(step("water"), f), "1,4 s na água ainda não")
		f.wetSeconds = 1.5
		assert(TutorialRules.isDone(step("water"), f), "1,5 s na água completa")
		assert(TutorialRules.advance(#LIST, f) == #LIST + 1, "depois da última = completo")
	end,

	["campfire_trail_follows_missing_ingredient"] = function()
		local s = step("campfire")
		assert(TutorialRules.trailTarget(s, { wood = 3 }) == "tree", "falta madeira")
		assert(TutorialRules.trailTarget(s, { wood = 25, stone = 1 }) == "rock", "falta pedra")
		assert(TutorialRules.trailTarget(s, { wood = 25, stone = 5 }) == nil, "tem tudo")
		assert(TutorialRules.trailTarget(s, { campfire = 1 }) == nil, "já fez a fogueira")
	end,

	["trail_for_water_and_none_for_pickaxe"] = function()
		assert(TutorialRules.trailTarget(step("water"), {}) == "water", "água")
		assert(TutorialRules.trailTarget(step("pickaxe"), {}) == nil, "picareta não tem rastro")
		assert(TutorialRules.trailTarget(LIST[1], { wood = 2 }) == "tree", "madeira vem da árvore")
		assert(TutorialRules.trailTarget(LIST[1], { wood = 10 }) == nil, "já tem a madeira")
	end,

	["can_craft_pickaxe"] = function()
		assert(not TutorialRules.canCraft("wood_pickaxe", { wood = 9 }), "9 madeiras não")
		assert(TutorialRules.canCraft("wood_pickaxe", { wood = 10 }), "10 madeiras sim")
	end,

	["protection_expires"] = function()
		assert(TutorialRules.protected(100, 699.9), "antes dos 600 s")
		assert(not TutorialRules.protected(100, 700), "aos 600 s acaba")
	end,

	["restart_from_zero"] = function()
		assert(TutorialRules.advance(1, facts()) == 1, "sem nada, fica na 1")
	end,
}
