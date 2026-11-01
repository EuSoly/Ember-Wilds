--!strict
-- Baú perto do jogador, no cliente. A cada 0,25 s procura o baú (peça com tag
-- de construção e kind "chest") mais perto, a até ChestRules.RANGE studs (XZ,
-- do centro do baú; o servidor usa o mesmo número), e copia o conteúdo dos
-- atributos do modelo. Só lê e pede: quem decide é o servidor (ChestService).
-- Os atributos do personagem previsto não avisam mudança (Server Authority),
-- então tudo é lido por polling.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local ChestRules = require(Shared:WaitForChild("Build"):WaitForChild("ChestRules"))
local Defs = require(Shared:WaitForChild("Defs"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Net = require(script.Parent:WaitForChild("Net"))

local REFRESH = 0.25 -- segundos entre conferências

export type Item = { id: string, count: number }

local ChestState = {
	-- Baú mais perto dentro do alcance, ou nil.
	near = vide.source(nil :: Model?),
	-- Conteúdo do baú perto (nil = vazio ou sem baú).
	contents = vide.source(nil :: Item?),
}

local function isChest(model: Instance): boolean
	if not model:IsA("Model") or not model:IsDescendantOf(Workspace) then
		return false
	end
	local itemId = model:GetAttribute(StatNames.StructureItem)
	local def = if type(itemId) == "string" then Defs.Items[itemId] else nil
	return def ~= nil and def.structure ~= nil and def.structure.kind == "chest"
end

local function findNearest(): Model?
	local character = Players.LocalPlayer.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") then
		return nil
	end
	local best: Model? = nil
	local bestDistance = ChestRules.RANGE * ChestRules.RANGE
	for _, tagged in CollectionService:GetTagged(StatNames.StructureTag) do
		if isChest(tagged) then
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

local function readContents(chest: Model?): Item?
	if chest == nil then
		return nil
	end
	local id = chest:GetAttribute(StatNames.ChestItem)
	local count = chest:GetAttribute(StatNames.ChestCount)
	-- Baú novo não tem os atributos até o primeiro "pôr": conta como vazio.
	if type(id) ~= "string" or type(count) ~= "number" or count <= 0 then
		return nil
	end
	return { id = id, count = count }
end

local function refresh()
	local chest = findNearest()
	if ChestState.near() ~= chest then
		ChestState.near(chest)
	end
	local now = readContents(chest)
	local before = ChestState.contents()
	local same = (now == nil and before == nil)
		or (now ~= nil and before ~= nil and now.id == before.id and now.count == before.count)
	if not same then
		ChestState.contents(now)
	end
end

-- Pede ao servidor para pôr `count` (1 ou 10) do slot do inventário no baú perto.
function ChestState.put(slot: number, count: number)
	local chest = vide.untrack(ChestState.near)
	if chest then
		Net.ChestPut.Fire({ Chest = chest, Slot = slot, Count = count })
	end
end

-- Pede ao servidor para tirar do baú perto o quanto couber no inventário.
function ChestState.take()
	local chest = vide.untrack(ChestState.near)
	if chest then
		Net.ChestTake.Fire(chest)
	end
end

function ChestState.Start(_self)
	task.spawn(function()
		while true do
			refresh()
			task.wait(REFRESH)
		end
	end)
end

return ChestState
