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
-- Item largado (11/11): vira uma caixa com a skin de quem largou, na frente dele.
CrateRules.DROP_LIFETIME = 60 -- segundos (renova a cada item que entra)
CrateRules.DROP_DISTANCE = 4 -- studs à frente do jogador (2,5 ficava embaixo do boneco)
CrateRules.DROP_MERGE_RADIUS = 4 -- largar perto da própria caixa junta nela
CrateRules.MAX_DROP_SLOTS = 20 -- slots de uma caixa de item largado

-- Pontuação ganha por matar alguém com `score` pontos; 0 para valor inválido.
function CrateRules.killBonus(score: number): number
	if type(score) ~= "number" or score ~= score or score <= 0 or score == math.huge then
		return 0
	end
	return math.floor(score * CrateRules.KILL_BONUS)
end

-- Junta `count` de `id` nos slots de uma caixa de item largado: completa as
-- pilhas do mesmo item (até `maxCount` por slot) e abre slots novos no fim.
-- false (sem mexer) se a quantidade é inválida ou passaria de MAX_DROP_SLOTS.
function CrateRules.mergeDrop(
	slots: { { id: string, count: number } },
	id: string,
	count: number,
	maxCount: number
): boolean
	if type(count) ~= "number" or not (count >= 1 and count < math.huge) or count % 1 ~= 0 then
		return false
	end
	local remaining = count
	for _, slot in slots do
		if slot.id == id then
			remaining -= math.max(0, maxCount - slot.count)
		end
	end
	if remaining > 0 and #slots + math.ceil(remaining / maxCount) > CrateRules.MAX_DROP_SLOTS then
		return false
	end
	remaining = count
	for _, slot in slots do
		if remaining <= 0 then
			break
		end
		if slot.id == id and slot.count < maxCount then
			local add = math.min(remaining, maxCount - slot.count)
			slot.count += add
			remaining -= add
		end
	end
	while remaining > 0 do
		local add = math.min(remaining, maxCount)
		table.insert(slots, { id = id, count = add })
		remaining -= add
	end
	return true
end

-- A caixa usa a skin de caixa de quem matou, se houver; senão a do morto.
function CrateRules.skinFor(killerSkin: string?, ownSkin: string): string
	return killerSkin or ownSkin
end

return table.freeze(CrateRules)
