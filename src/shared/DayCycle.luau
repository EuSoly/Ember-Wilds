--!strict
-- Ciclo de dia e noite (só números: testável no Lune).
-- O servidor publica o instante de início do ciclo (atributo CycleStart no
-- Workspace) e cada lado calcula o estado com a mesma fórmula, sem tráfego de rede.

export type CycleState = {
	day: number, -- começa em 1
	isNight: boolean,
	secondsLeft: number, -- até a próxima troca (anoitecer ou amanhecer)
	nightSoon: boolean, -- de dia e faltando WARNING_SECONDS ou menos para a noite
	-- Hora do relógio do jogo (0 a 24): o dia vai das 06:00 às 18:00 e a noite
	-- das 18:00 às 06:00 (o número do dia sobe no amanhecer, 06:00).
	hours: number,
}

local DayCycle = {}

DayCycle.DAY_SECONDS = 240
DayCycle.NIGHT_SECONDS = 240
DayCycle.WARNING_SECONDS = 30

local CYCLE_SECONDS = DayCycle.DAY_SECONDS + DayCycle.NIGHT_SECONDS

-- Estado do ciclo `elapsed` segundos depois do início.
function DayCycle.at(elapsed: number): CycleState
	local t = math.max(elapsed, 0)
	local inCycle = t % CYCLE_SECONDS
	local isNight = inCycle >= DayCycle.DAY_SECONDS
	local secondsLeft = if isNight then CYCLE_SECONDS - inCycle else DayCycle.DAY_SECONDS - inCycle
	local hours = if isNight
		then (18 + 12 * (inCycle - DayCycle.DAY_SECONDS) / DayCycle.NIGHT_SECONDS) % 24
		else 6 + 12 * inCycle / DayCycle.DAY_SECONDS
	return {
		day = math.floor(t / CYCLE_SECONDS) + 1,
		isNight = isNight,
		secondsLeft = secondsLeft,
		nightSoon = not isNight and secondsLeft <= DayCycle.WARNING_SECONDS,
		hours = hours,
	}
end

-- "mm:ss", arredondando para baixo.
function DayCycle.formatTime(seconds: number): string
	local whole = math.max(math.floor(seconds), 0)
	return string.format("%02d:%02d", whole // 60, whole % 60)
end

return DayCycle
