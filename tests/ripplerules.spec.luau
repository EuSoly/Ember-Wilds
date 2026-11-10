--!strict
local RippleRules = require("../src/shared/World/RippleRules")

return {
	["entering the water emits right away"] = function()
		local emit, state = RippleRules.step(nil, 10, 20, 5)
		assert(emit, "primeiro passo na água solta um anel")
		assert(state.x == 10 and state.z == 20 and state.t == 5, "guarda onde e quando")
	end,

	["walking emits every few studs, not every frame"] = function()
		local _, state = RippleRules.step(nil, 0, 0, 0)
		local emit = RippleRules.step(state, RippleRules.STEP - 0.5, 0, 1)
		assert(not emit, "andou menos que o passo")
		local emit2, state2 = RippleRules.step(state, RippleRules.STEP, 0, 1)
		assert(emit2 and state2.x == RippleRules.STEP, "andou o passo: solta e guarda")
	end,

	["a fast walker still waits the minimum gap"] = function()
		local _, state = RippleRules.step(nil, 0, 0, 0)
		local emit = RippleRules.step(state, 50, 0, RippleRules.MIN_GAP / 2)
		assert(not emit, "longe, mas cedo demais")
	end,

	["standing still in the water emits slowly"] = function()
		local _, state = RippleRules.step(nil, 0, 0, 0)
		local emit = RippleRules.step(state, 0, 0, RippleRules.IDLE_EVERY - 0.1)
		assert(not emit, "parado: ainda não")
		local emit2, state2 = RippleRules.step(state, 0.2, 0, RippleRules.IDLE_EVERY)
		assert(emit2 and state2.t == RippleRules.IDLE_EVERY, "parado: anel lento")
	end,

	["no emit keeps the previous state"] = function()
		local _, state = RippleRules.step(nil, 0, 0, 0)
		local emit, same = RippleRules.step(state, 1, 0, 0.5)
		assert(not emit and same == state, "sem anel, o estado não muda")
	end,

	["ring grows and fades over its life"] = function()
		local size0, alpha0 = RippleRules.ring(0)
		local sizeMid, alphaMid = RippleRules.ring(0.5)
		local size1, alpha1 = RippleRules.ring(1)
		assert(size0 < sizeMid and sizeMid < size1, "cresce")
		assert(alpha0 < alphaMid and alphaMid < alpha1, "some aos poucos (transparência sobe)")
		assert(alpha1 == 1, "no fim fica invisível")
		local clampedSize, clampedAlpha = RippleRules.ring(2)
		assert(clampedSize == size1 and clampedAlpha == 1, "fora do intervalo fica no fim")
	end,
}
