--!strict
-- O espinho acerta o mob que encosta nele (SpikeService usa estas mesmas contas).
local BuildRules = require("../src/shared/Build/BuildRules")
local MobMove = require("../src/shared/Mobs/MobMove")

local SPIKE = { x = 0, z = 0, radius = 2 } -- raio do espinho padrão (BuildRules.radiusOf)

local function touches(x: number, z: number, mobRadius: number): boolean
	return BuildRules.touchesCircle(x, z, SPIKE.x, SPIKE.z, SPIKE.radius, BuildRules.mobSpikeMargin(mobRadius))
end

return {
	["mob empurrado pelo MobMove contra o espinho conta como encostado"] = function()
		for _, mobRadius in { 0.8, 1, 2, 3 } do
			local x, z = MobMove.step(-10, 0, 1, 0, 20, mobRadius, { SPIKE }, nil)
			local gap = math.sqrt(x * x + z * z)
			assert(gap >= SPIKE.radius + mobRadius, `sobrepôs com raio {mobRadius}`)
			assert(touches(x, z, mobRadius), `raio {mobRadius}: parado em {gap} não encosta`)
		end
	end,

	["mob claramente longe do espinho não é ferido"] = function()
		assert(not touches(SPIKE.radius + 2 + BuildRules.MOB_SPIKE_SLACK + 0.5, 0, 2), "longe demais")
		assert(not touches(0, 10, 1), "longe demais")
	end,
}
