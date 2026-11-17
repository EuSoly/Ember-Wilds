--!strict
-- Quem matou: o killer direto, ou (queda, afogamento, fome, mob...) o último
-- jogador que acertou a vítima nos últimos WINDOW segundos. Regra pura.
local CombatTag = {}

CombatTag.WINDOW = 10

function CombatTag.resolve(killer: any?, last: any?, lastAt: number?, victim: any, now: number): any?
	if killer ~= nil and killer ~= victim then
		return killer
	end
	if last ~= nil and last ~= victim and lastAt ~= nil and now - lastAt <= CombatTag.WINDOW then
		return last
	end
	return nil
end

return CombatTag
