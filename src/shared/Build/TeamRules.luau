--!strict
-- Times pelo totem (puro, testado no Lune; veja docs/guia/times.md). Starve:
-- até 8 contando o líder, quem sai espera 20 s para entrar em outro, colega
-- tira 30% do golpe. Desfazer quando o líder sai (ou morre, ou perde o totem) é
-- escolha nossa: a wiki não diz.
local TeamRules = {}

TeamRules.MAX = 8
TeamRules.REJOIN_WAIT = 20 -- segundos
TeamRules.TOTEM_RADIUS = 10 -- studs além do raio do totem para entrar/expulsar/trancar
TeamRules.TEAM_DAMAGE = 0.3

-- members inclui o líder (UserIds).
export type Team = { leader: number, members: { number }, locked: boolean }

-- `userId` pode entrar agora? `waitUntil` = fim da espera depois de sair (nil = nenhuma).
function TeamRules.canJoin(team: Team, userId: number, now: number, waitUntil: number?): boolean
	if team.locked or #team.members >= TeamRules.MAX or table.find(team.members, userId) ~= nil then
		return false
	end
	return waitUntil == nil or now >= waitUntil
end

-- Tira `userId` do time. true = o time acabou (o líder saiu).
function TeamRules.leave(team: Team, userId: number): boolean
	if userId == team.leader then
		return true
	end
	local index = table.find(team.members, userId)
	if index then
		table.remove(team.members, index)
	end
	return false
end

-- `by` pode expulsar `target`? Só o líder, e só outro membro do time.
function TeamRules.canKick(team: Team, by: number, target: number): boolean
	return by == team.leader and target ~= team.leader and table.find(team.members, target) ~= nil
end

-- Golpe de colega de time (Starve: 30%).
function TeamRules.teamDamage(amount: number): number
	return amount * TeamRules.TEAM_DAMAGE
end

return TeamRules
