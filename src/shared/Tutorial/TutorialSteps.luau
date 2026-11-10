--!strict
-- As etapas do tutorial da primeira partida, como dados (ver
-- docs/superpowers/specs/2026-11-10-tutorial-design.md). Para mudar a ordem ou
-- os números, mexa só aqui; quem decide se uma etapa está feita é TutorialRules.
-- - goal: "have" (ter N do item no inventário), "view" (ver a ficha do item no
--   livro), "place" (colocar o item no mundo) ou "drink" (ficar na água);
-- - sources: de onde sai cada item que falta (ResourceId do mapa), para o rastro;
-- - recipe: a receita que pisca na coluna de receitas quando dá para fazer.
local TutorialSteps = {}

export type Goal = {
	kind: "have" | "view" | "place" | "drink",
	item: string?,
	count: number?,
}

export type Step = {
	id: string,
	textKey: string,
	goal: Goal,
	sources: { [string]: string }?,
	recipe: string?,
}

local function step(id: string, goal: Goal, extra: { sources: { [string]: string }?, recipe: string? }?): Step
	return table.freeze({
		id = id,
		textKey = "tutorial.step." .. id,
		goal = table.freeze(goal),
		sources = if extra and extra.sources then table.freeze(extra.sources) else nil,
		recipe = if extra then extra.recipe else nil,
	})
end

-- Os singletons de `kind` são alargados para string em literal de tabela; o
-- `:: any` segura o tipo (mesmo truque do resto do projeto).
TutorialSteps.LIST = table.freeze({
	step("wood", { kind = "have", item = "wood", count = 10 } :: any, { sources = { wood = "tree" } }),
	step("pickaxe", { kind = "have", item = "wood_pickaxe", count = 1 } :: any, { recipe = "wood_pickaxe" }),
	step("berries", { kind = "have", item = "berry", count = 5 } :: any, { sources = { berry = "berry_bush" } }),
	step("book", { kind = "view", item = "campfire" } :: any),
	step(
		"campfire",
		{ kind = "place", item = "campfire" } :: any,
		{ sources = { wood = "tree", stone = "rock" }, recipe = "campfire" }
	),
	step("water", { kind = "drink" } :: any),
}) :: { Step }

return TutorialSteps
