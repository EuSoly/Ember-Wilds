--!strict
-- Regras do tutorial (puro, testado no Lune): se uma etapa está feita, quanto
-- falta, para onde o rastro aponta, o que pisca na interface e até quando o
-- jogador fica protegido. As etapas em si estão em TutorialSteps.
local Defs = require("../Defs")
local TutorialSteps = require("./TutorialSteps")

type Step = TutorialSteps.Step

local TutorialRules = {}

TutorialRules.PROTECTION_SECONDS = 600 -- proteção máxima depois de nascer (10 min)
TutorialRules.DRINK_SECONDS = 1.5 -- s na água para a etapa de beber
TutorialRules.REWARD_SPINS = 2 -- giros normais ao completar

-- O que o servidor (ou o cliente) sabe do jogador para avaliar a etapa.
export type Facts = {
	counts: { [string]: number }, -- itens no inventário
	placed: { [string]: boolean }, -- itens colocados no mundo nesta vida
	viewed: { [string]: boolean }, -- fichas vistas no livro nesta vida
	wetSeconds: number, -- s na água durante a etapa de beber
}

export type Need = { item: string, count: number }

local function have(counts: { [string]: number }, item: string): number
	return counts[item] or 0
end

function TutorialRules.isDone(step: Step, facts: Facts): boolean
	local goal = step.goal
	local item = goal.item or ""
	if goal.kind == "have" then
		return have(facts.counts, item) >= (goal.count or 1)
	elseif goal.kind == "view" then
		return facts.viewed[item] == true
	elseif goal.kind == "place" then
		return facts.placed[item] == true
	end
	return facts.wetSeconds >= TutorialRules.DRINK_SECONDS
end

-- Quanto tem e quanto precisa (para o "x/10" do quadrinho).
function TutorialRules.progress(step: Step, facts: Facts): (number, number)
	if step.goal.kind == "have" then
		local need = step.goal.count or 1
		return math.min(have(facts.counts, step.goal.item or ""), need), need
	end
	return if TutorialRules.isDone(step, facts) then 1 else 0, 1
end

-- Próxima etapa: passa no máximo uma por chamada. #LIST + 1 = completo.
function TutorialRules.advance(index: number, facts: Facts): number
	local step = TutorialSteps.LIST[index]
	if step and TutorialRules.isDone(step, facts) then
		return index + 1
	end
	return index
end

local function ingredients(recipeId: string?): { Need }
	local recipe = if recipeId then Defs.Recipes[recipeId] else nil
	local out: { Need } = {}
	if recipe then
		for _, ingredient in recipe.ingredients do
			table.insert(out, { item = ingredient.id, count = ingredient.count })
		end
	end
	return out
end

-- O que a etapa ainda pede no inventário (meta do "have", ou os ingredientes
-- da receita do "place" enquanto o item não foi feito).
function TutorialRules.needs(step: Step, counts: { [string]: number }): { Need }
	local goal = step.goal
	if goal.kind == "have" then
		return { { item = goal.item or "", count = goal.count or 1 } }
	elseif goal.kind == "place" then
		if have(counts, goal.item or "") >= 1 then
			return {}
		end
		return ingredients(step.recipe)
	end
	return {}
end

-- Para onde o rastro aponta: um ResourceId do mapa, "water" ou nil (sem rastro).
function TutorialRules.trailTarget(step: Step, counts: { [string]: number }): string?
	if step.goal.kind == "drink" then
		return "water"
	end
	local sources = step.sources
	if sources == nil then
		return nil
	end
	for _, need in TutorialRules.needs(step, counts) do
		if have(counts, need.item) < need.count then
			return sources[need.item]
		end
	end
	return nil
end

-- true se o inventário tem todos os ingredientes da receita.
function TutorialRules.canCraft(recipeId: string, counts: { [string]: number }): boolean
	local list = ingredients(recipeId)
	if #list == 0 then
		return false
	end
	for _, need in list do
		if have(counts, need.item) < need.count then
			return false
		end
	end
	return true
end

-- true enquanto a proteção vale (desde `startedAt`, em segundos).
function TutorialRules.protected(startedAt: number, now: number): boolean
	return now - startedAt < TutorialRules.PROTECTION_SECONDS
end

return TutorialRules
