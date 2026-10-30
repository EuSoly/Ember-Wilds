--!strict
-- Frutinhas visíveis (G2): nos recursos que têm peças chamadas "Berry" (o
-- arbusto), mostra só as que a reserva ainda tem (atributo Amount do modelo,
-- em proporção ao AmountMax) e esconde as outras, só neste cliente. Vale para
-- qualquer modelo futuro que tenha peças Berry.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local GatherRules = require(Shared:WaitForChild("Gather"):WaitForChild("GatherRules"))
local StatNames = require(Shared:WaitForChild("StatNames"))

local BERRY = "Berry"

local BerryDisplay = {}

-- Peças Berry do modelo, numa ordem estável (posição), para sumirem sempre na
-- mesma sequência.
local function berriesOf(model: Model): { BasePart }
	local list: { BasePart } = {}
	for _, descendant in model:GetDescendants() do
		if descendant.Name == BERRY and descendant:IsA("BasePart") then
			table.insert(list, descendant)
		end
	end
	table.sort(list, function(a, b)
		if a.Position.X ~= b.Position.X then
			return a.Position.X < b.Position.X
		end
		return a.Position.Z < b.Position.Z
	end)
	return list
end

local function refresh(model: Model, berries: { BasePart })
	local amount = model:GetAttribute(StatNames.Amount)
	local max = model:GetAttribute(StatNames.AmountMax)
	if type(amount) ~= "number" or type(max) ~= "number" then
		return
	end
	local visible = GatherRules.berriesVisible(amount, max, #berries)
	for i, berry in berries do
		berry.LocalTransparencyModifier = if i <= visible then 0 else 1
	end
end

local function watch(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	local berries = berriesOf(instance)
	if #berries == 0 then
		return
	end
	refresh(instance, berries)
	instance:GetAttributeChangedSignal(StatNames.Amount):Connect(function()
		refresh(instance, berries)
	end)
end

function BerryDisplay.start()
	-- Recursos chegam aos poucos (streaming).
	CollectionService:GetInstanceAddedSignal(StatNames.ResourceTag):Connect(watch)
	for _, instance in CollectionService:GetTagged(StatNames.ResourceTag) do
		watch(instance)
	end
end

return BerryDisplay
