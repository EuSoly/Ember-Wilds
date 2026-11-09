--!strict
-- O que o livro de receitas mostra (puro, testado no Lune com os Defs reais).
-- A tela (Screens/RecipeBookScreen + UI/BookSheet) só desenha. Tudo vem dos
-- Defs: item novo, receita, mob ou recurso entra no livro sozinho.
-- Veja docs/superpowers/specs/2026-11-09-livro-receitas-design.md.
local Defs = require("../Defs")
local ItemAccess = require("../ItemAccess")
local Types = require("../Defs/Types")

export type Tab = "tools" | "weapons" | "armor" | "food" | "build" | "resources"

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
		-- Tudo que não tem receita, mais os materiais feitos (ex. papel).
		return def.category == "resource" or BookInfo.recipeOf(def.id) == nil
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
			return tab :: any
		end
	end
	return nil
end

return BookInfo
