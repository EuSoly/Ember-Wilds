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
export type Slots = { [number]: Item? }

local ChestState = {
	-- Baú mais perto dentro do alcance, ou nil.
	near = vide.source(nil :: Model?),
	-- Conteúdo dos 3 slots do baú perto (1..ChestRules.SLOTS; nil no slot = vazio).
	slots = vide.source({} :: Slots),
	-- Compatibilidade: o primeiro slot ocupado, ou nil se todos vazios.
	contents = vide.source(nil :: Item?),
	-- Celular: modo "Guardar" ligado (tocar num slot põe no baú). Desliga
	-- sozinho ao se afastar do baú.
	storing = vide.source(false),
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

local function readSlot(chest: Model, slot: number): Item?
	local id = chest:GetAttribute(StatNames.chestItem(slot))
	local count = chest:GetAttribute(StatNames.chestCount(slot))
	if type(id) ~= "string" or type(count) ~= "number" or count <= 0 then
		return nil
	end
	return { id = id, count = count }
end

local function sameItem(a: Item?, b: Item?): boolean
	return (a == nil and b == nil) or (a ~= nil and b ~= nil and a.id == b.id and a.count == b.count)
end

local function refresh()
	local chest = findNearest()
	if ChestState.near() ~= chest then
		ChestState.near(chest)
		if chest == nil and ChestState.storing() then
			ChestState.storing(false)
		end
	end
	local nowSlots: Slots = {}
	local first: Item? = nil
	if chest ~= nil then
		for i = 1, ChestRules.SLOTS do
			local item = readSlot(chest, i)
			nowSlots[i] = item
			if first == nil and item ~= nil then
				first = item
			end
		end
	end
	local beforeSlots = ChestState.slots()
	local changed = false
	for i = 1, ChestRules.SLOTS do
		if not sameItem(nowSlots[i], beforeSlots[i]) then
			changed = true
			break
		end
	end
	if changed then
		ChestState.slots(nowSlots)
	end
	if not sameItem(first, ChestState.contents()) then
		ChestState.contents(first)
	end
end

-- Pede ao servidor para pôr `count` (1 ou 10) do slot do inventário no baú perto.
function ChestState.put(slot: number, count: number)
	local chest = vide.untrack(ChestState.near)
	if chest then
		Net.ChestPut.Fire({ Chest = chest, Slot = slot, Count = count })
	end
end

-- Pede ao servidor para tirar do slot `slot` (1..3) do baú perto o quanto couber no inventário.
function ChestState.take(slot: number?)
	local chest = vide.untrack(ChestState.near)
	if chest then
		Net.ChestTake.Fire({ Chest = chest, Slot = slot or 1 })
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
