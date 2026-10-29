--!strict
-- Guarda "uma vez por vida" e a conta de dias vividos (puro, testado no Lune).
-- O fim de vida pode ser pedido mais de uma vez (morreu e saiu; PlayerRemoving
-- e BindToClose juntos): só o primeiro conta.
local DataConfig = require("./DataConfig")

export type Life = { active: boolean, startedAt: number }

local LifeRules = {}

function LifeRules.start(now: number): Life
	return { active = true, startedAt = now }
end

-- Se a vida está ativa, marca como terminada e devolve os segundos vividos;
-- senão (sem vida ou já terminada) devolve nil.
function LifeRules.finish(life: Life?, now: number): number?
	if life == nil or not life.active then
		return nil
	end
	life.active = false
	return math.max(now - life.startedAt, 0)
end

-- Ciclos completos (dia + noite) vividos. Pessoal, não o "Dia N" do mundo.
function LifeRules.daysSurvived(seconds: number): number
	if type(seconds) ~= "number" or seconds ~= seconds or seconds <= 0 or seconds == math.huge then
		return 0
	end
	return math.floor(seconds / DataConfig.DAY_CYCLE_SECONDS)
end

return LifeRules
