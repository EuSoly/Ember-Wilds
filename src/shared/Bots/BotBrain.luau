--!strict
-- Cérebro dos bots (puro; spec 2026-11-20-bots-design): a partir de uma foto do
-- bot (vida, fome, frio, inventário, o que tem por perto), escolhe o objetivo.
-- O BotService (servidor) monta a foto, executa o objetivo e pergunta de novo
-- a cada pensamento. Ordem de urgência:
--   1. briga (provocado)   2. mob perigoso   3. noite/frio (fogueira)
--   4. fome                5. escada de itens (BotLadder)   6. coletar/andar
local BotLadder = require("./BotLadder")
local Defs = require("../Defs")
local StatNames = require("../StatNames")

export type Goal = "fight" | "flee" | "warm" | "eat" | "craft" | "place" | "gather" | "hunt" | "wander"

export type Snapshot = {
	health: number, -- 0 a StatNames.HealthMax
	hunger: number, -- 0 a StatNames.StatusMax (cheio = sem fome)
	cold: number, -- 0 a StatNames.StatusMax (cheio = quentinho)
	isNight: boolean,
	nearFire: boolean, -- dentro do calor de uma fogueira
	fireNearby: boolean, -- tem fogueira acesa perto o bastante para ir até ela
	counts: { [string]: number }, -- inventário (id → quantidade)
	nearStation: { [string]: boolean }, -- "workbench"/"fire" ao alcance do craft
	provoker: any?, -- quem provocou (BotRules.provoked), ainda vivo e perto
	threat: boolean, -- mob perigoso perto
	hasWeapon: boolean,
	food: string?, -- melhor comida do inventário
	stuckSeconds: number, -- tempo sem chegar perto do alvo atual
}

-- item = receita (craft/place) ou recurso cru (gather: "wood", "stone", "berry").
export type Decision = { goal: Goal, item: string? }

local LOW_HEALTH = 0.3 -- briga: abaixo disso foge
local SAFE_HEALTH = 0.5 -- mob: só enfrenta acima disso
local LOW_HUNGER = 0.4
local LOW_COLD = 0.4
local STUCK_SECONDS = 6
-- Ordem de coleta quando falta mais de um ingrediente cru.
local RAW_ORDER = { "wood", "stone" }

local BotBrain = {}

-- Primeiro ingrediente cru que falta para a receita (nil = tem tudo).
local function missingRaw(recipeId: string, counts: { [string]: number }): string?
	local missing = BotLadder.missing(recipeId, counts)
	for _, id in RAW_ORDER do
		if missing[id] then
			return id
		end
	end
	return nil
end

-- Pedra só sai com picareta (GatherRules.yield): sem ela, a de madeira primeiro.
local function gatherRaw(raw: string, counts: { [string]: number }): Decision
	local hasPickaxe = (counts.wood_pickaxe or 0) > 0 or (counts.stone_pickaxe or 0) > 0
	if raw == "stone" and not hasPickaxe then
		local wood = missingRaw("wood_pickaxe", counts)
		return if wood then { goal = "gather", item = wood } else { goal = "craft", item = "wood_pickaxe" }
	end
	return { goal = "gather", item = raw }
end

-- Colocar `recipeId` (fogueira, bancada) ou juntar o que falta para ela.
local function placeOrGather(recipeId: string, counts: { [string]: number }): Decision
	local raw = missingRaw(recipeId, counts)
	if raw then
		return gatherRaw(raw, counts)
	end
	return { goal = "place", item = recipeId }
end

local function ladder(s: Snapshot): Decision
	local step = BotLadder.next(s.counts)
	if step == nil then
		return { goal = "gather", item = "wood" }
	end
	local raw = missingRaw(step, s.counts)
	if raw then
		return gatherRaw(raw, s.counts)
	end
	local recipe = Defs.Recipes[step]
	local station = recipe and recipe.station
	if station == "workbench" and not s.nearStation.workbench then
		return placeOrGather("workbench", s.counts)
	end
	if station == "fire" and not s.nearStation.fire then
		return placeOrGather("campfire", s.counts)
	end
	return { goal = "craft", item = step }
end

local function choose(s: Snapshot): Decision
	local healthMax = StatNames.HealthMax
	local statusMax = StatNames.StatusMax
	if s.provoker ~= nil then
		return { goal = if s.health > LOW_HEALTH * healthMax then "fight" else "flee" }
	end
	if s.threat then
		return { goal = if s.hasWeapon and s.health > SAFE_HEALTH * healthMax then "fight" else "flee" }
	end
	local cold = s.cold < LOW_COLD * statusMax
	if s.isNight or cold then
		if s.nearFire or s.fireNearby then
			-- Perto do fogo: só sai para comer (com comida na mão, come ali mesmo).
			if s.hunger < LOW_HUNGER * statusMax and s.food then
				return { goal = "eat", item = s.food }
			end
			return { goal = "warm" }
		end
		return placeOrGather("campfire", s.counts)
	end
	if s.hunger < LOW_HUNGER * statusMax then
		if s.food then
			return { goal = "eat", item = s.food }
		end
		return if s.hasWeapon then { goal = "hunt" } else { goal = "gather", item = "berry" }
	end
	return ladder(s)
end

function BotBrain.decide(s: Snapshot): Decision
	local decision = choose(s)
	-- Preso indo até um recurso: anda um pouco para outro lado e tenta outro.
	if decision.goal == "gather" and s.stuckSeconds >= STUCK_SECONDS then
		return { goal = "wander" }
	end
	return decision
end

return BotBrain
