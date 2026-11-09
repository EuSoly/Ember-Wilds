--!strict
local BonecoAnim = require("../src/shared/BonecoAnim")
local C = require("../src/shared/BonecoConfig")
local EatRules = require("../src/shared/Survival/EatRules")

local function near(a: number, b: number): boolean
	return math.abs(a - b) <= 1e-6
end

return {
	["eating only before EatUntil"] = function()
		assert(EatRules.isEating(10, 9.9), "antes do fim está comendo")
		assert(not EatRules.isEating(10, 10), "no fim já não está")
		assert(not EatRules.isEating(nil, 0), "sem atributo não está")
		assert(not EatRules.isEating(0 / 0, 0), "NaN não está")
	end,

	["progress goes 0 to 1 along the bite"] = function()
		assert(near(EatRules.progress(11.2, 10, 1.2) :: number, 0), "começo = 0")
		assert(near(EatRules.progress(11.2, 10.6, 1.2) :: number, 0.5), "meio = 0,5")
		assert(EatRules.progress(11.2, 11.2, 1.2) == nil, "fim = fora da mordida")
		assert(near(EatRules.progress(20, 10, 1.2) :: number, 0), "fim muito longe conta como começo")
	end,

	["hand goes to the mouth and comes back"] = function()
		local reach0 = BonecoAnim.eatCurve(0)
		local reachMid, chewMid = BonecoAnim.eatCurve(0.5)
		local reachEnd = BonecoAnim.eatCurve(1)
		assert(near(reach0, 0) and near(reachEnd, 0), "começa e termina no repouso")
		assert(near(reachMid, 1), "no meio está na boca")
		assert(chewMid >= 0 and chewMid <= 1, "mordida entre 0 e 1")
	end,

	["one crumb moment per bite, inside the chewing part"] = function()
		local bites = BonecoAnim.eatBites()
		assert(#bites == C.EAT_BITES, `{#bites} mordidas`)
		for _, p in bites do
			assert(p > C.EAT_BRING_FRACTION and p < 1 - C.EAT_RETURN_FRACTION, `mordida em {p}`)
			local _, chew = BonecoAnim.eatCurve(p)
			assert(near(chew, 1), `fundo da mordida em {p}: {chew}`)
		end
	end,

	["eating hand reaches the mouth and does not swing"] = function()
		local state = BonecoAnim.newState()
		local pose = BonecoAnim.step(state, 1 / 60, { speed = 0, using = true, hasTool = false, eat = 0.5 })
		assert(not state.swingActive, "comendo não golpeia")
		assert(near(C.HAND_X + pose.right.x, C.EAT_HAND_X), "mão no x da boca")
	end,
}
