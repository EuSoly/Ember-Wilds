--!strict
-- Regras puras dos bots (spec 2026-11-20-bots-design): quantos bots o servidor
-- quer, o teto de pontos de um bot e quando um jogador provocou o bot.
-- Quem usa: BotService (servidor). Testado no Lune (tests/botrules.spec).

export type Provoke = { [any]: { number } } -- instantes dos golpes de cada atacante

local BotRules = {}

BotRules.MAX_BOTS = 10 -- no máximo 10 bots por servidor
BotRules.TARGET_TOTAL = 20 -- jogadores + bots (a partir do 11º jogador sai 1 bot por jogador)
BotRules.POPULATION_EVERY = 5 -- segundos entre trocas (no máximo 1 bot entra ou sai por vez)
BotRules.PROVOKE_WINDOW = 4 -- 2 golpes do mesmo jogador nesse tempo = briga
BotRules.PROVOKE_HITS = 2
-- Teto de pontos de um bot ("jogador médio", decisão do Elizeu 20/11): matar
-- bot dá o bônus de kill de sempre (CrateRules.killBonus) sem virar farm.
BotRules.BOT_SCORE_CAP = 3000

-- Quantos bots o servidor quer com `players` jogadores e `maxPlayers` vagas.
function BotRules.target(players: number, maxPlayers: number): number
	local total = math.min(BotRules.TARGET_TOTAL, maxPlayers)
	return math.clamp(total - players, 0, BotRules.MAX_BOTS)
end

-- Quanto mudar nesta rodada: -1 (sai um), 0 ou +1 (entra um).
function BotRules.populationStep(current: number, target: number): number
	if current > target then
		return -1
	elseif current < target then
		return 1
	end
	return 0
end

-- Pontos novos de um bot, sem passar do teto (pontos inválidos não mudam nada).
function BotRules.addScore(score: number, points: number): number
	if not (points > 0) then
		return score
	end
	return math.min(score + points, BotRules.BOT_SCORE_CAP)
end

-- O golpe em área acerta tudo no círculo: quem coleta na árvore ao lado do
-- bot acerta o bot sem querer. Conta como provocação só se o bot estava mais
-- perto do centro do golpe que o recurso mais perto (nil = nenhum recurso).
function BotRules.aimedAtBot(botDistance: number, resourceDistance: number?): boolean
	return resourceDistance == nil or botDistance <= resourceDistance
end

-- Guarda um golpe de `attacker` (só os da janela ficam).
function BotRules.recordHit(state: Provoke, attacker: any, now: number)
	local kept: { number } = {}
	local hits: { number } = state[attacker] or {}
	for _, at in hits do
		if now - at <= BotRules.PROVOKE_WINDOW then
			table.insert(kept, at)
		end
	end
	table.insert(kept, now)
	state[attacker] = kept
end

-- `attacker` bateu PROVOKE_HITS vezes dentro da janela?
function BotRules.provoked(state: Provoke, attacker: any, now: number): boolean
	local count = 0
	local hits: { number } = state[attacker] or {}
	for _, at in hits do
		if now - at <= BotRules.PROVOKE_WINDOW then
			count += 1
		end
	end
	return count >= BotRules.PROVOKE_HITS
end

return BotRules
