--!strict
-- Receita fixada no HUD (no cliente, só nesta sessão; continua depois de morrer).
-- O livro de receitas fixa e desafixa; o painel (UI/PinnedRecipe) mostra os
-- ingredientes com a contagem do inventário (Shared/UIFlow/PinRules).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local BookInfo = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("UIFlow"):WaitForChild("BookInfo"))
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

-- Estações exigidas pela receita fixada; vazio sem receita ou sem estação.
function PinState.stations(): { string }
	local id = PinState.pinned()
	local craft = if id then BookInfo.craft(id) else nil
	local out: { string } = {}
	if craft then
		for _, station in craft.stations do
			table.insert(out, station)
		end
	end
	return out
end

-- true se já dá para fazer a receita fixada (ingredientes; e estações se `near` for dado).
function PinState.ready(near: { [string]: boolean }?): boolean
	local id = PinState.pinned()
	if id == nil or not PinRules.ready(id, counts()) then
		return false
	end
	if near then
		for _, station in PinState.stations() do
			if not near[station] then
				return false
			end
		end
	end
	return true
end

return PinState
