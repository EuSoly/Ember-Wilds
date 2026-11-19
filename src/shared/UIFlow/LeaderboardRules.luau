--!strict
-- Regras puras do placar da partida (estilo Starve.io): ordena os jogadores
-- por pontos (empate: nome), corta em `limit` e, se o jogador local (`me`)
-- ficou de fora, acrescenta ele no fim com o rank real.
export type InputEntry = { name: string, score: number, userId: number }
export type Row = { rank: number, name: string, score: number, isMe: boolean }

local LeaderboardRules = {}

-- Lista completa (janela no meio da tela): até LIMIT linhas.
LeaderboardRules.LIMIT = 50
-- Placar compacto do canto (no lugar do antigo selo de pontos): só o pódio.
LeaderboardRules.PODIUM = 3

function LeaderboardRules.top(entries: { InputEntry }, limit: number, me: number): { Row }
	if #entries == 0 or limit <= 0 then
		return {}
	end
	local sorted = table.clone(entries)
	table.sort(sorted, function(a, b)
		if a.score ~= b.score then
			return a.score > b.score
		end
		if a.name ~= b.name then
			return a.name < b.name
		end
		return a.userId < b.userId
	end)
	local out: { Row } = {}
	local meIncluded = false
	for rank = 1, math.min(#sorted, limit) do
		local entry = sorted[rank]
		local isMe = entry.userId == me
		if isMe then
			meIncluded = true
		end
		table.insert(out, {
			rank = rank,
			name = entry.name,
			score = entry.score,
			isMe = isMe,
		})
	end
	if not meIncluded then
		for rank = limit + 1, #sorted do
			local entry = sorted[rank]
			if entry.userId == me then
				table.insert(out, {
					rank = rank,
					name = entry.name,
					score = entry.score,
					isMe = true,
				})
				break
			end
		end
	end
	return out
end

-- Só os PODIUM primeiros, sem acrescentar o jogador local (pedido do Elizeu,
-- 19/11: o canto mostra o top 3; a posição de cada um está na lista completa).
function LeaderboardRules.podium(entries: { InputEntry }, me: number): { Row }
	local rows = LeaderboardRules.top(entries, LeaderboardRules.PODIUM, me)
	local out: { Row } = {}
	for _, row in rows do
		if row.rank <= LeaderboardRules.PODIUM then
			table.insert(out, row)
		end
	end
	return out
end

return table.freeze(LeaderboardRules)
