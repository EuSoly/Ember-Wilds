--!strict
-- O Lune não tem o Random do Roblox: os testes usam o Rng do projeto (mesma
-- semente = mesma sequência) embrulhado numa função () -> number.
local Rng = require("../src/shared/World/Rng")
local SpawnPoint = require("../src/shared/Survival/SpawnPoint")

local ZONE = { minX = -100, maxX = 100, minZ = -50, maxZ = 50 }

local function rngOf(seed: number): () -> number
	local rng = Rng.new(seed)
	return function()
		return rng:nextNumber()
	end
end

local function never(_x: number, _z: number): boolean
	return false
end

return {
	["avoids blocked points"] = function()
		local rng = rngOf(1)
		local function blocked(x: number, _z: number): boolean
			return x < 0
		end
		local found = 0
		for _ = 1, 200 do
			local x, z = SpawnPoint.pick(rng, ZONE, blocked, 30)
			if x ~= nil then
				found += 1
				assert(x >= 0, `ponto bloqueado devolvido: x = {x}`)
				assert(z ~= nil and z >= ZONE.minZ and z <= ZONE.maxZ, "z fora da zona")
			end
		end
		assert(found > 0, "nunca achou ponto livre")
	end,

	["stays inside the zone"] = function()
		local rng = rngOf(7)
		for _ = 1, 200 do
			local x, z = SpawnPoint.pick(rng, ZONE, never, 1)
			assert(x ~= nil and z ~= nil, "zona toda livre e não achou ponto")
			assert(x >= ZONE.minX and x <= ZONE.maxX and z >= ZONE.minZ and z <= ZONE.maxZ, "ponto fora da zona")
		end
	end,

	["gives up after tries"] = function()
		local calls = 0
		local function always(_x: number, _z: number): boolean
			calls += 1
			return true
		end
		local x, z = SpawnPoint.pick(rngOf(1), ZONE, always, 30)
		assert(x == nil and z == nil, "devia desistir com nil, nil")
		assert(calls == 30, `devia tentar 30 vezes, tentou {calls}`)
	end,

	["same seed gives the same point"] = function()
		local ax, az = SpawnPoint.pick(rngOf(1), ZONE, never, 30)
		local bx, bz = SpawnPoint.pick(rngOf(1), ZONE, never, 30)
		assert(ax ~= nil and ax == bx and az == bz, "mesma semente deu pontos diferentes")
	end,
}
