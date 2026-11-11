--!strict
local BuildRules = require("../src/shared/Build/BuildRules")
local TeamRules = require("../src/shared/Build/TeamRules")

local function team(members: { number }, locked: boolean?): TeamRules.Team
	return { leader = members[1], members = table.clone(members), locked = locked == true }
end

return {
	["join only with room, unlocked and after the wait"] = function()
		assert(TeamRules.canJoin(team({ 1 }), 2, 100, nil), "time com vaga")
		assert(not TeamRules.canJoin(team({ 1 }, true), 2, 100, nil), "trancado")
		assert(not TeamRules.canJoin(team({ 1, 2, 3, 4, 5, 6, 7, 8 }), 9, 100, nil), "cheio (8)")
		assert(not TeamRules.canJoin(team({ 1, 2 }), 2, 100, nil), "já é do time")
		assert(not TeamRules.canJoin(team({ 1 }), 2, 100, 110), "esperando os 20 s")
		assert(TeamRules.canJoin(team({ 1 }), 2, 110, 110), "espera acabou")
	end,

	["leaving: member leaves, leader dissolves"] = function()
		local t = team({ 1, 2, 3 })
		assert(TeamRules.leave(t, 2) == false and #t.members == 2, "membro sai, time continua")
		assert(TeamRules.leave(t, 1) == true, "líder sai: time desfeito")
		assert(TeamRules.REJOIN_WAIT == 20, "espera de 20 s")
	end,

	["only the leader kicks, never himself"] = function()
		local t = team({ 1, 2 })
		assert(not TeamRules.canKick(t, 2, 1), "membro não expulsa")
		assert(not TeamRules.canKick(t, 1, 1), "líder não se expulsa")
		assert(TeamRules.canKick(t, 1, 2), "líder expulsa membro")
		assert(not TeamRules.canKick(t, 1, 3), "não expulsa quem não é do time")
	end,

	["teammates are allies and hit for 30%"] = function()
		local leaderOf = { [1] = 1, [2] = 1, [3] = 3 }
		BuildRules.setTeamResolver(function(userId: number): number?
			return leaderOf[userId]
		end)
		assert(BuildRules.areAllies(1, 2), "mesmo time")
		assert(not BuildRules.areAllies(1, 3), "times diferentes")
		assert(not BuildRules.areAllies(2, 4), "sem time")
		assert(BuildRules.areAllies(4, 4), "a própria pessoa")
		BuildRules.setTeamResolver(nil)
		assert(not BuildRules.areAllies(1, 2), "sem resolvedor: só a própria pessoa")
		assert(TeamRules.teamDamage(20) == 6, "colega tira 30%")
	end,
}
