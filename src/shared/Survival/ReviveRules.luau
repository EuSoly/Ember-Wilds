--!strict
-- Regras puras do revive (spec 2026-11-17-monetizacao, seção 4.6; testadas
-- no Lune). Quem aplica é o ReviveService.
--
-- - offer: o preço da próxima volta. `usedThisRun` = revives já usados nesta
--   "corrida" (da entrada pelo menu até a morte final), CONTANDO os grátis:
--   o grátis do VIP ocupa o degrau 1, então depois dele o próximo custa 49.
--   Ordem: revive guardado (crédito) primeiro; senão o grátis do VIP; senão o
--   degrau min(usedThisRun + 1, 4) de ShopConfig.REVIVE_ROBUX.
-- - Pending: a janela da decisão. Limite escondido de DECISION_SECONDS; o
--   tempo pausado (compra do Roblox aberta ou pendente) não conta, até
--   PURCHASE_PAUSE_MAX somados na janela toda. Só a 1ª resposta vale (o tempo
--   acabar e sair do jogo também são respostas: "decline").
-- - Proteção do revive: atributo SpawnShieldUntil (relógio do servidor).
local ShopConfig = require("../Shop/ShopConfig")

local ReviveRules = {}

ReviveRules.DECISION_SECONDS = 30
ReviveRules.PURCHASE_PAUSE_MAX = 60
ReviveRules.SHIELD_SECONDS = 3

-- step 1..4; robux = preço do degrau (quando free, só informativo).
export type Offer = { step: number, robux: number, free: boolean, credit: boolean }

export type Answer = "revive" | "decline"

export type Pending = {
	openedAt: number,
	pausedAt: number?, -- início da pausa em andamento (nil = sem pausa)
	pausedTotal: number, -- segundos já pausados nas pausas terminadas
	answer: Answer?,
}

function ReviveRules.offer(usedThisRun: number, vipFreeLeft: boolean, credits: number): Offer
	local prices = ShopConfig.REVIVE_ROBUX
	local used = if usedThisRun == usedThisRun and usedThisRun > 0 then math.floor(usedThisRun) else 0
	local step = math.min(used + 1, #prices)
	local robux = prices[step]
	if credits >= 1 then
		return { step = step, robux = robux, free = true, credit = true }
	end
	if vipFreeLeft then
		return { step = step, robux = robux, free = true, credit = false }
	end
	return { step = step, robux = robux, free = false, credit = false }
end

function ReviveRules.open(now: number): Pending
	return { openedAt = now, pausedAt = nil, pausedTotal = 0, answer = nil }
end

-- Começa uma pausa (já pausado: nada).
function ReviveRules.pause(p: Pending, now: number)
	if p.pausedAt == nil then
		p.pausedAt = now
	end
end

-- Termina a pausa em andamento (sem pausa: nada).
function ReviveRules.resume(p: Pending, now: number)
	local at = p.pausedAt
	if at ~= nil then
		p.pausedTotal += math.max(now - at, 0)
		p.pausedAt = nil
	end
end

-- Segundos pausados que contam até `now` (no máximo PURCHASE_PAUSE_MAX).
local function pausedUntil(p: Pending, now: number): number
	local total = p.pausedTotal
	local at = p.pausedAt
	if at ~= nil then
		total += math.max(now - at, 0)
	end
	return math.min(total, ReviveRules.PURCHASE_PAUSE_MAX)
end

-- true quando passaram DECISION_SECONDS fora das pausas.
function ReviveRules.expired(p: Pending, now: number): boolean
	return now - p.openedAt - pausedUntil(p, now) >= ReviveRules.DECISION_SECONDS
end

-- Registra a resposta. Devolve a resposta só na 1ª vez; depois, nil.
function ReviveRules.answer(p: Pending, accept: boolean): Answer?
	if p.answer ~= nil then
		return nil
	end
	local result: Answer = if accept then "revive" else "decline"
	p.answer = result
	return result
end

-- Saiu do jogo com a janela aberta: conta como recusa (se ainda sem resposta).
function ReviveRules.onLeave(p: Pending): Answer?
	return ReviveRules.answer(p, false)
end

-- Quem pode ver a oferta: fora do criativo, fora da vida de tutorial, com
-- perfil carregado e com algum item (slots, mochila ou armadura).
function ReviveRules.eligible(creative: boolean, tutorial: boolean, hasProfile: boolean, hasItems: boolean): boolean
	return not creative and not tutorial and hasProfile and hasItems
end

-- true enquanto a proteção do revive vale (`untilAt` = atributo SpawnShieldUntil).
function ReviveRules.shielded(untilAt: any, now: number): boolean
	return type(untilAt) == "number" and now < untilAt
end

-- Bits do LifeEnded.EmberBonus: 1 = 2×, 2 = VIP, 4 = Premium.
function ReviveRules.emberBonus(perks: { ember2x: boolean, vip: boolean, premium: boolean }): number
	return (if perks.ember2x then 1 else 0) + (if perks.vip then 2 else 0) + (if perks.premium then 4 else 0)
end

-- Chaves de texto das etiquetas de um EmberBonus, na ordem 2×, VIP, Premium
-- (o inverso de emberBonus; bits desconhecidos são ignorados).
function ReviveRules.emberTagKeys(bits: number): { string }
	local keys = {}
	if bit32.band(bits, 1) ~= 0 then
		table.insert(keys, "ember.tag.2x")
	end
	if bit32.band(bits, 2) ~= 0 then
		table.insert(keys, "ember.tag.vip")
	end
	if bit32.band(bits, 4) ~= 0 then
		table.insert(keys, "ember.tag.premium")
	end
	return keys
end

return ReviveRules
