--!strict
-- Registro do último jogador que acertou cada vítima. Fica num módulo próprio
-- porque CharacterService requer DeathService (sem ciclo de require).
local LastAttacker = {}

local records: { [Player]: { attacker: Player, at: number } } = {}

function LastAttacker.record(victim: Player, attacker: Player, at: number)
	records[victim] = { attacker = attacker, at = at }
end

function LastAttacker.get(victim: Player): (Player?, number?)
	local record = records[victim]
	if record == nil then
		return nil, nil
	end
	return record.attacker, record.at
end

function LastAttacker.clear(victim: Player)
	records[victim] = nil
end

return LastAttacker
