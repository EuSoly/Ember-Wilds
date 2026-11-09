--!strict
-- O que o livro de receitas mostra (puro, testado no Lune com os Defs reais).
-- A tela (Screens/RecipeBookScreen + UI/BookSheet) só desenha. Tudo vem dos
-- Defs: item novo, receita, mob ou recurso entra no livro sozinho.
-- Veja docs/superpowers/specs/2026-11-09-livro-receitas-design.md.
local Defs = require("../Defs")
local CraftRules = require("../Craft/CraftRules")
local ItemAccess = require("../ItemAccess")
local ItemInfo = require("./ItemInfo")
local Types = require("../Defs/Types")

-- "tools", "weapons", "armor", "food", "build" ou "resources" (string: o
-- verificador de tipos alarga os literais e a união só atrapalhava).
export type Tab = string

local BookInfo = {}

-- Ordem das abas no livro; o nome de cada uma é "book.tab.<aba>".
local TABS: { Tab } = { "tools", "weapons", "armor", "food", "build", "resources" }
BookInfo.TABS = TABS

-- Categorias de item de cada aba (a de recursos tem regra própria).
local TAB_CATEGORIES: { [string]: { [string]: boolean } } = {
	tools = { tool = true, misc = true },
	weapons = { weapon = true },
	armor = { armor = true, bag = true }, -- a mochila também se veste
	food = { food = true },
	build = { placeable = true },
}

-- Receita cujo resultado é o item (nil = item primário).
function BookInfo.recipeOf(itemId: string): Types.RecipeDef?
	for _, recipe in Defs.Recipes do
		if recipe.result == itemId then
			return recipe
		end
	end
	return nil
end

local function inTab(tab: string, def: Types.ItemDef): boolean
	if tab == "resources" then
		-- Materiais (inclusive os feitos, ex. papel) e a comida crua (sem receita).
		-- Construção, ferramenta ou balde sem receita não é recurso.
		return def.category == "resource" or (def.category == "food" and BookInfo.recipeOf(def.id) == nil)
	end
	return TAB_CATEGORIES[tab][def.category] == true
end

-- Itens da aba: primeiro os com receita (pela ordem das receitas), depois os
-- sem receita (por id). Um item pode estar em mais de uma aba.
function BookInfo.items(tab: Tab, inStudio: boolean): { string }
	local crafted: { { id: string, order: number } } = {}
	local raw: { string } = {}
	for id, def in Defs.Items do
		if ItemAccess.isAvailable(id, inStudio) and inTab(tab, def) then
			local recipe = BookInfo.recipeOf(id)
			if recipe then
				table.insert(crafted, { id = id, order = recipe.order })
			else
				table.insert(raw, id)
			end
		end
	end
	table.sort(crafted, function(a, b)
		return if a.order == b.order then a.id < b.id else a.order < b.order
	end)
	table.sort(raw)
	local out: { string } = {}
	for _, entry in crafted do
		table.insert(out, entry.id)
	end
	for _, id in raw do
		table.insert(out, id)
	end
	return out
end

-- Primeira aba (na ordem do livro) que tem o item; nil se nenhuma.
function BookInfo.firstTab(itemId: string, inStudio: boolean): Tab?
	local def = Defs.Items[itemId]
	if def == nil or not ItemAccess.isAvailable(itemId, inStudio) then
		return nil
	end
	for _, tab in TABS do
		if inTab(tab, def) then
			return tab
		end
	end
	return nil
end

-- Estações de craft: texto e ícone (BookImages.STATION[icon]). A ficha monta
-- "Precisa de" só por esta tabela: a água ainda não existe nas receitas, mas
-- quando a primeira receita com station = "water" chegar, aparece sozinha.
BookInfo.STATIONS = {
	workbench = { key = "book.station.workbench", icon = "workbench" },
	fire = { key = "book.station.fire", icon = "fire" },
	water = { key = "book.station.water", icon = "water" },
} :: { [string]: { key: string, icon: string } }

export type Craft = {
	ingredients: { Types.RecipeIngredient },
	count: number, -- quantos a receita faz
	station: string?,
	seconds: number, -- tempo sem item na mão
}

-- Como fazer o item; nil para item primário.
function BookInfo.craft(itemId: string): Craft?
	local recipe = BookInfo.recipeOf(itemId)
	if recipe == nil then
		return nil
	end
	return {
		ingredients = recipe.ingredients,
		count = recipe.count,
		station = recipe.station :: string?,
		seconds = CraftRules.duration(recipe, nil),
	}
end

-- Todos os dados do item (a dica mostra só os 3 primeiros).
function BookInfo.stats(itemId: string): { ItemInfo.Line }
	local def = Defs.Items[itemId]
	return if def then ItemInfo.lines(def, math.huge) else {}
end

-- De onde vem um item: mob que deixa ao morrer, ou recurso do mapa que dá na
-- coleta. hardness: nil = rende com qualquer coisa na mão (ex. frutinha);
-- 0 = mão; N = picareta nível N. Recurso sem `gather` (pedrinha) nunca entra.
export type Source = { kind: "mob", id: string, count: number } | { kind: "resource", id: string, hardness: number? }

function BookInfo.sources(itemId: string): { Source }
	local mobs: { Source } = {}
	for mobId, mob in Defs.Mobs do
		local loots: { Types.MobLoot } = mob.loot or {}
		for _, loot in loots do
			if loot.id == itemId then
				table.insert(mobs, { kind = "mob", id = mobId, count = loot.count })
			end
		end
	end
	table.sort(mobs, function(a, b)
		return a.id < b.id
	end)
	local resources: { Source } = {}
	for resourceId, resource in Defs.Resources do
		local gather = resource.gather
		if gather and gather.item == itemId then
			table.insert(resources, { kind = "resource", id = resourceId, hardness = gather.hardness })
		end
	end
	table.sort(resources, function(a, b)
		return a.id < b.id
	end)
	for _, source in resources do
		table.insert(mobs, source)
	end
	return mobs
end

-- Itens cujas receitas usam este (pela ordem das receitas).
function BookInfo.usedIn(itemId: string, inStudio: boolean): { string }
	local found: { Types.RecipeDef } = {}
	for _, recipe in Defs.Recipes do
		if ItemAccess.recipeAvailable(recipe, inStudio) then
			for _, ingredient in recipe.ingredients do
				if ingredient.id == itemId then
					table.insert(found, recipe)
					break
				end
			end
		end
	end
	table.sort(found, function(a, b)
		return a.order < b.order
	end)
	local out: { string } = {}
	for _, recipe in found do
		table.insert(out, recipe.result)
	end
	return out
end

-- Dá para fazer agora? (todos os ingredientes e a estação por perto). Item
-- sem receita: sempre true (recurso nunca fica apagado no livro).
function BookInfo.craftableNow(itemId: string, counts: { [string]: number }, near: { [string]: boolean }): boolean
	local recipe = BookInfo.recipeOf(itemId)
	if recipe == nil then
		return true
	end
	for _, ingredient in recipe.ingredients do
		if (counts[ingredient.id] or 0) < ingredient.count then
			return false
		end
	end
	return recipe.station == nil or near[recipe.station] == true
end

return BookInfo
