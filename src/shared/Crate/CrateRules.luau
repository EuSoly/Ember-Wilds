--!strict
-- Regras puras da caixa de itens que todo morto (jogador ou mob) deixa.
-- Sem Roblox aqui: o servidor usa estes números e funções.
local CrateRules = {}

CrateRules.PLAYER_LIFETIME = 180 -- segundos até a caixa de jogador sumir
CrateRules.MOB_LIFETIME = 60 -- segundos até a caixa de mob sumir
CrateRules.HEALTH = 600 -- vida da caixa (dá para quebrar)
CrateRules.OPEN_RANGE = 8 -- distância máxima para abrir/pegar
CrateRules.RADIUS = 1.5 -- raio do corpo da caixa
CrateRules.KILL_BONUS = 0.25 -- fração da pontuação do morto que o matador ganha

-- Pontuação ganha por matar alguém com `score` pontos; 0 para valor inválido.
function CrateRules.killBonus(score: number): number
	if type(score) ~= "number" or score ~= score or score <= 0 or score == math.huge then
		return 0
	end
	return math.floor(score * CrateRules.KILL_BONUS)
end

-- A caixa usa a skin de caixa de quem matou, se houver; senão a do morto.
function CrateRules.skinFor(killerSkin: string?, ownSkin: string): string
	return killerSkin or ownSkin
end

return table.freeze(CrateRules)
