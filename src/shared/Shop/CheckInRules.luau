--!strict
-- Regras puras do check-in de 7 dias (testadas no Lune): um prêmio por dia de
-- Brasília (RankRules.dayIndex), sem precisar ser seguido; depois do 7 volta
-- ao 1. As funções MUDAM a tabela recebida (a do perfil, data.Shop.CheckIn):
-- quem chama no servidor entrega o prêmio, republica e salva.
local ShopConfig = require("./ShopConfig")
local ShopTypes = require("./Types")

export type Save = { Day: number, LastDay: number }
export type CardState = "claimed" | "today" | "future" | "locked"

local CheckInRules = {}

local DAYS = #ShopConfig.CHECKIN

-- Pode resgatar hoje? (`today` = dayIndex de agora; LastDay 0 = nunca resgatou.)
function CheckInRules.canClaim(save: Save, today: number): boolean
	return today ~= save.LastDay
end

-- Resgata o prêmio do dia: devolve ShopConfig.CHECKIN[Day], grava LastDay e
-- avança o dia (7 volta ao 1). nil (e nada muda) se já resgatou hoje.
function CheckInRules.claim(save: Save, today: number): ShopTypes.Reward?
	if not CheckInRules.canClaim(save, today) then
		return nil
	end
	local reward = ShopConfig.CHECKIN[save.Day]
	if reward == nil then
		return nil
	end
	save.LastDay = today
	save.Day = save.Day % DAYS + 1
	return reward
end

-- Estado do cartão `day` (1..7) na janela, dado o dia atual (próximo prêmio)
-- e se há resgate pronto hoje (é o que o cliente recebe do servidor).
-- Resgatados = dias antes do atual neste ciclo, mais o que acabou de ser
-- resgatado hoje (se o ciclo virou, o 7). "today" = o dia atual com prêmio
-- pronto; "locked" = o dia atual já com o resgate de hoje feito (espera a
-- meia-noite de Brasília); o resto, futuro.
function CheckInRules.stateOf(day: number, currentDay: number, ready: boolean): CardState
	if day == currentDay then
		return if ready then "today" else "locked"
	end
	if day < currentDay then
		return "claimed"
	end
	if not ready and day == (currentDay - 2) % DAYS + 1 then
		return "claimed" -- o último resgatado hoje, quando o ciclo acabou de virar
	end
	return "future"
end

-- Igual a stateOf, a partir do perfil e do dia de hoje.
function CheckInRules.cardState(save: Save, today: number, day: number): CardState
	return CheckInRules.stateOf(day, save.Day, CheckInRules.canClaim(save, today))
end

return CheckInRules
