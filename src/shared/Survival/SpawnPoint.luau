--!strict
-- Ponto de nascimento ao acaso (puro: testável no Lune). Sorteia pontos na
-- zona até um não estar bloqueado, no máximo `tries` vezes.
--
-- `rng` devolve um número em [0, 1): no servidor, o NextNumber de um Random;
-- nos testes, o World/Rng (o Lune não tem o Random do Roblox). Mesmo gerador
-- com a mesma semente = mesmo ponto.

export type Zone = { minX: number, maxX: number, minZ: number, maxZ: number }

local SpawnPoint = {}

-- (x, z) livre dentro da zona, ou nil, nil se as `tries` tentativas caírem em
-- pontos bloqueados.
function SpawnPoint.pick(
	rng: () -> number,
	zone: Zone,
	blocked: (x: number, z: number) -> boolean,
	tries: number
): (number?, number?)
	for _ = 1, tries do
		local x = zone.minX + rng() * (zone.maxX - zone.minX)
		local z = zone.minZ + rng() * (zone.maxZ - zone.minZ)
		if not blocked(x, z) then
			return x, z
		end
	end
	return nil, nil
end

return SpawnPoint
