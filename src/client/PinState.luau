--!strict
-- Receita fixada no HUD (no cliente, só nesta sessão; continua depois de morrer).
-- O livro de receitas fixa e desafixa; o painel (UI/PinnedRecipe) mostra os
-- ingredientes com a contagem do inventário (Shared/UIFlow/PinRules).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local PinRules = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIFlow"):WaitForChild("PinRules"))
local InventoryState = require(script.Parent:WaitForChild("InventoryState"))

type Source<T> = (() -> T) & ((T) -> T)

local PinState = {}

-- Id da receita fixada (= id do item que ela faz), ou nil.
PinState.pinned = vide.source(nil :: string?) :: Source<string?>

-- Fixa `recipeId`, ou desafixa se já era ele (uma receita por vez).
function PinState.toggle(recipeId: string)
	if vide.untrack(PinState.pinned) == recipeId then
		PinState.pinned(nil)
	else
		PinState.pinned(recipeId)
	end
end

-- Com a peça vestida somada (o capacete da cabeça vale na receita do próximo).
local function counts(): { [string]: number }
	return InventoryState.craftCounts()
end

-- Linhas do painel (ingredientes, tem/precisa); vazio sem receita fixada.
function PinState.lines(): { PinRules.Line }
	local id = PinState.pinned()
	return if id then PinRules.lines(id, counts()) else {}
end

-- true se já dá para fazer a receita fixada.
function PinState.ready(): boolean
	local id = PinState.pinned()
	return id ~= nil and PinRules.ready(id, counts())
end

return PinState
