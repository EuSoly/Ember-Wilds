--!strict
-- Estrutura de usar de perto (G8: extrator, fornalha, poço, cama, placa) mais
-- perto do jogador, no cliente. A cada 0,25 s procura a peça (tag de construção)
-- mais perto cujo tipo tem ações (InteractRules.actionsFor), a até
-- InteractRules.RANGE studs (XZ, do centro da peça; o servidor usa o mesmo
-- número), e copia o estado dos atributos do modelo (Wood, Stock, Drinks).
-- Só lê e pede: quem decide é o servidor (InteractService e o serviço do tipo).
-- Tudo por polling, como no baú (ChestState).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local InteractRules = require(Shared:WaitForChild("Build"):WaitForChild("InteractRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Net = require(script.Parent:WaitForChild("Net"))

local REFRESH = 0.25 -- segundos entre conferências

-- Estado da peça lido dos atributos do modelo; nil = a peça não tem esse atributo.
export type Status = { wood: number?, stock: number?, drinks: number?, symbol: number? }

local EMPTY: Status = table.freeze({})

local InteractState = {
	-- Peça interativa mais perto dentro do alcance, ou nil.
	near = vide.source(nil :: Model?),
	-- Estado da peça perto (vazio sem peça ou sem atributos).
	status = vide.source(EMPTY),
}

-- Item (Defs) que virou a peça, ou nil (não é peça ou o atributo ainda não chegou).
function InteractState.itemOf(model: Instance): Defs.ItemDef?
	local itemId = model:GetAttribute(StatNames.StructureItem)
	local def = if type(itemId) == "string" then Defs.Items[itemId] else nil
	if def == nil or def.structure == nil then
		return nil
	end
	return def
end

-- Tipo (def.structure.kind) da peça, ou nil.
function InteractState.kindOf(model: Instance): string?
	local def = InteractState.itemOf(model)
	local structure = def and def.structure
	return if structure then structure.kind else nil
end

local function isInteractive(model: Instance): boolean
	if not model:IsA("Model") or not model:IsDescendantOf(Workspace) then
		return false
	end
	local kind = InteractState.kindOf(model)
	return kind ~= nil and #InteractRules.actionsFor(kind) > 0
end

local function findNearest(): Model?
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return nil
	end
	local best: Model? = nil
	local bestDistance = InteractRules.RANGE * InteractRules.RANGE
	for _, tagged in CollectionService:GetTagged(StatNames.StructureTag) do
		if isInteractive(tagged) then
			local model = tagged :: Model
			local point = model:GetPivot().Position
			local dx, dz = point.X - root.Position.X, point.Z - root.Position.Z
			local distance = dx * dx + dz * dz
			if distance <= bestDistance then
				best, bestDistance = model, distance
			end
		end
	end
	return best
end

local function numberAttribute(model: Model, name: string): number?
	local value = model:GetAttribute(name)
	return if type(value) == "number" then value else nil
end

local function readStatus(model: Model?): Status
	if model == nil then
		return EMPTY
	end
	return {
		wood = numberAttribute(model, StatNames.Wood),
		stock = numberAttribute(model, StatNames.Stock),
		drinks = numberAttribute(model, StatNames.Drinks),
		symbol = numberAttribute(model, StatNames.Symbol),
	}
end

local function refresh()
	local model = findNearest()
	if InteractState.near() ~= model then
		InteractState.near(model)
	end
	local now = readStatus(model)
	local before = InteractState.status()
	if
		now.wood ~= before.wood
		or now.stock ~= before.stock
		or now.drinks ~= before.drinks
		or now.symbol ~= before.symbol
	then
		InteractState.status(now)
	end
end

-- Pede ao servidor a ação `action` (InteractRules.ACTIONS) na peça perto;
-- `arg` = extra da ação (ex.: símbolo da placa), 0 quando não usa.
function InteractState.act(action: number, arg: number?)
	local model = vide.untrack(InteractState.near)
	if model then
		Net.StructureAction.Fire({ Target = model, Action = action, Arg = arg or 0 })
	end
end

function InteractState.Start(_self)
	task.spawn(function()
		while true do
			refresh()
			task.wait(REFRESH)
		end
	end)
end

return InteractState
