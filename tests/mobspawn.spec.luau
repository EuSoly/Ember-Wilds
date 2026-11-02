--!strict
local Defs = require("../src/shared/Defs")
local Rng = require("../src/shared/World/Rng")
local MobSpawn = require("../src/shared/Mobs/MobSpawn")

return {
	["targets use the forest day and night population"] = function()
		local day = MobSpawn.targets(Defs.Mobs, "forest", false)
		assert(day.rabbit == 40 and day.wolf == 10 and day.spider == 8 and day.boar == 8 and day.hawk == 6, "dia")
		local night = MobSpawn.targets(Defs.Mobs, "forest", true)
		assert(night.rabbit == 15 and night.wolf == 20 and night.spider == 16, "noite")
	end,

	["targets are empty for a biome without population"] = function()
		assert(next(MobSpawn.targets(Defs.Mobs, "nowhere", false)) == nil, "devia ser vazio")
	end,

	["diff reports missing, surplus and equal"] = function()
		local d = MobSpawn.diff({ rabbit = 10, wolf = 5, boar = 3 }, { rabbit = 4, wolf = 8, boar = 3 })
		assert(d.rabbit == 6, "falta")
		assert(d.wolf == -3, "sobra")
		assert(d.boar == nil, "igual não aparece")
	end,

	["diff counts a missing type as zero and surplus without target"] = function()
		local d = MobSpawn.diff({ rabbit = 2 }, { hawk = 4 })
		assert(d.rabbit == 2 and d.hawk == -4, "diff errado")
	end,

	["pick finds a free point inside the rect"] = function()
		local rect = { minX = 10, minZ = 20, maxX = 30, maxZ = 40 }
		local x, z = MobSpawn.pick(Rng.new(1), rect, function()
			return true
		end, 5)
		assert(x and z and x >= 10 and x <= 30 and z >= 20 and z <= 40, `{x}, {z}`)
	end,

	["pick gives up after exactly tries calls"] = function()
		local calls = 0
		local x, z = MobSpawn.pick(Rng.new(1), { minX = 0, minZ = 0, maxX = 1, maxZ = 1 }, function()
			calls += 1
			return false
		end, 7)
		assert(x == nil and z == nil, "devia desistir")
		assert(calls == 7, `chamadas: {calls}`)
	end,
}
