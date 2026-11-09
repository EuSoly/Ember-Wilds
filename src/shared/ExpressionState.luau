--!strict
-- Escolha da expressão do boneco a cada quadro: entre as expressões que estão
-- valendo agora (base, piscar, evento recente, condição), vence a de maior
-- prioridade. Também diz a cor do flash do corpo (ex. vermelho no dano).
-- Pura (sem APIs do Roblox): o relógio e o sorteio vêm de fora, para os
-- testes do Lune controlarem o tempo.
local Types = require("./Defs/Types")

type ExpressionDef = Types.ExpressionDef
type Defs = { [string]: ExpressionDef }

-- Agenda de uma expressão periódica: começa em `start` e acaba em `stop`.
type Schedule = { start: number, stop: number }

-- Estado de um boneco. Quem usa só passa adiante (não mexa nos campos).
export type State = {
	events: { [string]: number }, -- nome do evento → instante do último disparo
	schedules: { [string]: Schedule }, -- id da periódica → próxima janela
}

local ExpressionState = {}

function ExpressionState.new(): State
	return { events = {}, schedules = {} }
end

-- Marca que o evento aconteceu agora (ex. "hurt" ao levar dano).
function ExpressionState.trigger(state: State, event: string, now: number)
	state.events[event] = now
end

-- Esquece o evento (ex. "eat" quando a mordida é cancelada antes do fim).
function ExpressionState.clear(state: State, event: string)
	state.events[event] = nil
end

-- O evento disparou há menos de `window` segundos?
local function eventWithin(state: State, event: string?, now: number, window: number?): boolean
	if event == nil or window == nil then
		return false
	end
	local at = state.events[event]
	return at ~= nil and now - at >= 0 and now - at < window
end

local function randomInterval(def: ExpressionDef, random: () -> number): number
	local min = def.intervalMin :: number
	local max = def.intervalMax :: number
	return min + (max - min) * random()
end

-- Periódica: na primeira vez agenda o início (não pisca logo de cara); quando a
-- janela acaba, agenda a próxima a partir do fim dela.
local function periodicActive(state: State, def: ExpressionDef, now: number, random: () -> number): boolean
	local duration = def.duration :: number
	local schedule = state.schedules[def.id]
	if schedule == nil then
		local start = now + randomInterval(def, random)
		schedule = { start = start, stop = start + duration }
		state.schedules[def.id] = schedule
	end
	if now >= schedule.stop then
		local start = schedule.stop + randomInterval(def, random)
		-- Boneco que ficou muito tempo sem atualizar (longe da câmera): a janela
		-- nova já teria passado, então agenda a partir de agora.
		if now >= start + duration then
			start = now + randomInterval(def, random)
		end
		schedule.start = start
		schedule.stop = start + duration
	end
	return now >= schedule.start and now < schedule.stop
end

-- Ganha a de maior prioridade; empate vai para o menor id (determinístico).
local function better(a: ExpressionDef, b: ExpressionDef?): boolean
	if b == nil then
		return true
	end
	if a.priority ~= b.priority then
		return a.priority > b.priority
	end
	return a.id < b.id
end

-- O valor do atributo satisfaz a condição? Número: below/above; boolean: equals.
-- Atributo ausente ou de outro tipo nunca satisfaz.
function ExpressionState.conditionMet(condition: Types.ExpressionCondition, value: any): boolean
	if type(value) == "boolean" then
		return condition.equals ~= nil and value == condition.equals
	end
	if type(value) ~= "number" then
		return false
	end
	if condition.below ~= nil and value < condition.below then
		return true
	end
	return condition.above ~= nil and value > condition.above
end

function ExpressionState.current(
	state: State,
	defs: Defs,
	now: number,
	random: () -> number, -- [0,1); injetado para os testes
	isConditionTrue: (ExpressionDef) -> boolean
): ExpressionDef
	local best: ExpressionDef? = nil
	for _, def in defs do
		local active = false
		if def.trigger == "always" then
			active = true
		elseif def.trigger == "event" then
			active = eventWithin(state, def.event, now, def.duration)
		elseif def.trigger == "periodic" then
			active = periodicActive(state, def, now, random)
		elseif def.trigger == "condition" then
			active = isConditionTrue(def)
		end
		if active and better(def, best) then
			best = def
		end
	end
	-- A validação das Defs garante exatamente uma "always", então sempre há uma.
	assert(best ~= nil, '[ExpressionState] nenhuma expressão ativa (falta a "always")')
	return best
end

-- Cor do flash do corpo agora, ou nil. Vem da expressão de evento com flash
-- de maior prioridade cujo evento aconteceu há menos de flash.duration.
function ExpressionState.flashColor(state: State, defs: Defs, now: number): string?
	local best: ExpressionDef? = nil
	for _, def in defs do
		local flash = def.flash
		if
			def.trigger == "event"
			and flash ~= nil
			and eventWithin(state, def.event, now, flash.duration)
			and better(def, best)
		then
			best = def
		end
	end
	if best == nil or best.flash == nil then
		return nil
	end
	return best.flash.color
end

-- O instante `eventTime` está na janela [now - window, now]? Serve para ignorar
-- um HurtAt antigo que chega quando o personagem entra no alcance do streaming.
-- Um valor no futuro (relógios fora de ordem) também é ignorado.
function ExpressionState.isRecent(eventTime: number?, now: number, window: number): boolean
	return eventTime ~= nil and now - eventTime >= 0 and now - eventTime < window
end

return ExpressionState
