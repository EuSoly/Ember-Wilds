--!strict
-- Estado da hotbar no cliente: os 10 primeiros slots do inventário e qual está
-- selecionado. Selecionar avisa o servidor (que mostra o item na mão).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local InventoryConfig = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("InventoryConfig"))
local InventoryState = require(script.Parent:WaitForChild("InventoryState"))
local Net = require(script.Parent:WaitForChild("Net"))

local SLOT_COUNT = InventoryConfig.HOTBAR_SLOTS

local HotbarState = {}

HotbarState.SLOT_COUNT = SLOT_COUNT

-- A hotbar são os slots 1 a 10 do inventário.
HotbarState.slots = InventoryState.slots

-- Slot selecionado (1 a 10).
HotbarState.selected = vide.source(1)

function HotbarState.select(index: number)
	if index >= 1 and index <= SLOT_COUNT and index ~= vide.untrack(HotbarState.selected) then
		HotbarState.selected(index)
		Net.SelectSlot.Fire(index)
	end
end

return HotbarState
