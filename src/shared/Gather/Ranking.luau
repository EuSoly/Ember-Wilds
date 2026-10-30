--!strict
-- Ranking do servidor (só números: testável no Lune): posição 1 = mais pontos;
-- empate fica com quem entrou antes (menor `order`).
export type Entry = { id: number, score: number, order: number }

local Ranking = {}

-- id → posição.
function Ranking.compute(entries: { Entry }): { [number]: number }
	local sorted = table.clone(entries)
	table.sort(sorted, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		return a.order < b.order
	end)
	local ranks: { [number]: number } = {}
	for position, entry in sorted do
		ranks[entry.id] = position
	end
	return ranks
end

return Ranking
