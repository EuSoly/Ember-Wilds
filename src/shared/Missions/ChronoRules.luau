--!strict
-- Chrono quests (puro, testado no Lune): estado da vida atual, prazo em dias de
-- jogo, quebra de regra e resgate. Quem vigia o jogo (dano, golpes, time) e
-- guarda o estado por jogador é o QuestService. Nada disso salva: morreu, acabou.
local DataConfig = require("../Data/DataConfig")
local Types = require("../Defs/Types")

type QuestDef = Types.QuestDef

export type Status = "active" | "done" | "failed" | "claimed"
export type ChronoState = { [string]: { status: Status } }
export type WatchedRule = "alone" | "unhurt" | "peaceful"

local ChronoRules = {}

-- Estado de uma vida nova: só as quests ligadas, todas em andamento.
function ChronoRules.start(defs: Types.DefsTables): ChronoState
	local state: ChronoState = {}
	for id, def in defs.Quests do
		if def.enabled then
			state[id] = { status = "active" }
		end
	end
	return state
end

local function deadline(def: QuestDef): number
	return def.days * DataConfig.DAY_CYCLE_SECONDS
end

-- Segundos até o fim do prazo (0 quando passou).
function ChronoRules.secondsLeft(def: QuestDef, lifeSeconds: number): number
	return math.max(deadline(def) - lifeSeconds, 0)
end

-- Quests de tempo (ends = "time") ativas que chegaram ao fim do prazo viram
-- prontas. Devolve as que completaram agora.
function ChronoRules.tick(state: ChronoState, defs: Types.DefsTables, lifeSeconds: number): { string }
	local done: { string } = {}
	for id, quest in state do
		local def = defs.Quests[id]
		if quest.status == "active" and def and def.ends == "time" and lifeSeconds >= deadline(def) then
			quest.status = "done"
			table.insert(done, id)
		end
	end
	return done
end

-- Toda quest em andamento com essa regra falha. Devolve as que falharam agora.
function ChronoRules.breakRule(state: ChronoState, defs: Types.DefsTables, rule: WatchedRule): { string }
	local failed: { string } = {}
	for id, quest in state do
		local def = defs.Quests[id]
		if quest.status == "active" and def then
			for _, r in def.rules do
				if r.type == rule then
					quest.status = "failed"
					table.insert(failed, id)
					break
				end
			end
		end
	end
	return failed
end

-- Acertar este tipo de mob quebra a regra "peaceful"? Mansos e neutros sim,
-- até para se defender (decisão do Elizeu); agressivos não.
function ChronoRules.isPeacefulTarget(behavior: Types.MobBehavior): boolean
	return behavior == "passive" or behavior == "neutral"
end

-- Resgata uma quest pronta. Sem espaço no inventário: recusa e continua pronta.
function ChronoRules.claim(
	state: ChronoState,
	defs: Types.DefsTables,
	id: string,
	hasSpace: boolean
): (QuestDef?, string?)
	local quest = state[id]
	local def = defs.Quests[id]
	if quest == nil or def == nil or quest.status ~= "done" then
		return nil, nil
	end
	if not hasSpace then
		return nil, "missions.inventory_full"
	end
	quest.status = "claimed"
	return def, nil
end

return ChronoRules
