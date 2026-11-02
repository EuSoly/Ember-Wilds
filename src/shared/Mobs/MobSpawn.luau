--!strict
-- Nascimento puro dos mobs: quantos devem existir e onde nascer (sem API do Roblox).
local Types = require("../Defs/Types")
local WorldConfig = require("../WorldConfig")
local Rng = require("../World/Rng")

type MobDef = Types.MobDef

local MobSpawn = {}

-- Quanto deve existir de cada tipo com população no bioma (dia ou noite).
function MobSpawn.targets(defs: { [string]: MobDef }, biome: string, night: boolean): { [string]: number }
	local out: { [string]: number } = {}
	for id, def in defs do
		local pop = def.population and def.population[biome]
		if pop then
			out[id] = if night then pop.night else pop.day
		end
	end
	return out
end

-- Positivo = falta nascer; negativo = sobra. `counts` = vivos + vagas esfriando.
-- Só lista os tipos que diferem; tipo com contagem mas sem meta sobra tudo.
function MobSpawn.diff(targets: { [string]: number }, counts: { [string]: number }): { [string]: number }
	local out: { [string]: number } = {}
	for id, want in targets do
		local d = want - (counts[id] or 0)
		if d ~= 0 then
			out[id] = d
		end
	end
	for id, have in counts do
		if targets[id] == nil and have ~= 0 then
			out[id] = -have
		end
	end
	return out
end

-- Ponto livre ao acaso no retângulo, até `tries` tentativas; nil, nil se não achar.
function MobSpawn.pick(
	rng: Rng.Rng,
	rect: WorldConfig.Rect,
	isFree: (number, number) -> boolean,
	tries: number
): (number?, number?)
	for _ = 1, tries do
		local x = rect.minX + rng:nextNumber() * (rect.maxX - rect.minX)
		local z = rect.minZ + rng:nextNumber() * (rect.maxZ - rect.minZ)
		if isFree(x, z) then
			return x, z
		end
	end
	return nil, nil
end

return MobSpawn
