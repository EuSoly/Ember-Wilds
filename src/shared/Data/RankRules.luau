--!strict
-- Regras puras do ranking semanal (testadas no Lune): qual é a semana, quando
-- ela termina, o valor da semana de cada jogador (guardado no perfil) e o
-- texto do "termina em…". Quem grava e lê o placar é o RankService.
local C = require("./RankConfig")
local DataConfig = require("./DataConfig")

export type Category = "points" | "xp" | "days" | "players" | "creatures"

-- Valores da semana de um jogador (fica no perfil, campo Ranking).
-- Victims/VictimsDay: abates por vítima no dia (só usado com limite ligado).
export type WeekState = {
	Week: number,
	points: number,
	xp: number,
	days: number,
	players: number,
	creatures: number,
	Victims: { [string]: number },
	VictimsDay: number,
}

local RankRules = {}

local function localTime(unixTime: number): number
	return unixTime + C.UTC_OFFSET
end

-- Número da semana (segunda 00:00 a domingo 23:59:59 de Brasília).
function RankRules.weekIndex(unixTime: number): number
	return math.floor((localTime(unixTime) - C.FIRST_MONDAY) / C.WEEK_SECONDS)
end

-- Último segundo (unix) da semana: domingo 23:59:59 de Brasília.
function RankRules.weekEnd(week: number): number
	return C.FIRST_MONDAY - C.UTC_OFFSET + (week + 1) * C.WEEK_SECONDS - 1
end

-- Número do dia de Brasília (vira à meia-noite local).
function RankRules.dayIndex(unixTime: number): number
	return math.floor(localTime(unixTime) / C.DAY_SECONDS)
end

function RankRules.empty(week: number): WeekState
	return { Week = week, points = 0, xp = 0, days = 0, players = 0, creatures = 0, Victims = {}, VictimsDay = 0 }
end

local function count(value: any): number
	if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then
		return 0
	end
	return math.floor(value)
end

-- O estado da semana `week`: o guardado, se for desta semana; senão (perfil
-- antigo, semana passada, lixo) um novo zerado. Campos quebrados viram 0.
function RankRules.current(state: any, week: number): WeekState
	if type(state) ~= "table" or state.Week ~= week then
		return RankRules.empty(week)
	end
	local fixed = RankRules.empty(week)
	for _, category in C.CATEGORIES do
		(fixed :: any)[category] = count(state[category])
	end
	if type(state.Victims) == "table" then
		for key, value in state.Victims do
			if type(key) == "string" then
				fixed.Victims[key] = count(value)
			end
		end
	end
	fixed.VictimsDay = count(state.VictimsDay)
	return fixed
end

-- Fim de uma vida: pontos e dias ficam com o melhor da semana; o XP soma.
-- Devolve as categorias que mudaram.
function RankRules.applyLife(state: WeekState, life: { points: number, days: number, xp: number }): { string }
	local changed = {}
	local points, days, xp = count(life.points), count(life.days), count(life.xp)
	if points > state.points then
		state.points = points
		table.insert(changed, "points")
	end
	if days > state.days then
		state.days = days
		table.insert(changed, "days")
	end
	if xp > 0 then
		state.xp += xp
		table.insert(changed, "xp")
	end
	return changed
end

-- Um abate. Com `limit` > 0, o mesmo `victimKey` conta no máximo `limit`
-- vezes por `day`. Devolve se contou.
function RankRules.applyKill(
	state: WeekState,
	category: Category,
	victimKey: string?,
	day: number,
	limit: number
): boolean
	if limit > 0 and victimKey ~= nil then
		if state.VictimsDay ~= day then
			state.Victims = {}
			state.VictimsDay = day
		end
		local already = state.Victims[victimKey] or 0
		if already >= limit then
			return false
		end
		state.Victims[victimKey] = already + 1
	end
	(state :: any)[category] += 1
	return true
end

-- Nome do DataStore ordenado da categoria (no Studio, com o prefixo de dev,
-- para testes nunca sujarem o placar do jogo).
function RankRules.storeName(category: string, inStudio: boolean): string
	local name = C.STORE_PREFIX .. category
	return if inStudio then DataConfig.DEV_STORE_PREFIX .. name else name
end

-- Escopo do DataStore: um placar separado por semana (as antigas ficam).
function RankRules.weekScope(week: number): string
	return "W" .. tostring(week)
end

-- Posição (1 = primeiro) de `userId` na lista lida do placar, ou 0 se não está.
function RankRules.position(entries: { any }, userId: number): number
	for index, entry in entries do
		if entry.UserId == userId then
			return index
		end
	end
	return 0
end

-- Texto do "termina em…": chave em Strings e os números dela.
function RankRules.countdown(seconds: number): (string, { [string]: number })
	seconds = math.max(0, math.floor(seconds))
	local days = seconds // 86400
	local hours = (seconds % 86400) // 3600
	local minutes = (seconds % 3600) // 60
	if days >= 1 then
		return "rank.ends.days", { d = days, h = hours }
	elseif hours >= 1 then
		return "rank.ends.hours", { h = hours, m = minutes }
	elseif minutes >= 1 then
		return "rank.ends.minutes", { m = minutes }
	end
	return "rank.ends.soon", {}
end

return RankRules
