--!strict
-- Estado da hotbar no cliente: os 10 primeiros slots do inventário e qual está
-- selecionado. Selecionar avisa o servidor (que mostra o item na mão).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Defs = require(Shared:WaitForChild("Defs"))
local HeldItem = require(Shared:WaitForChild("HeldItem"))
local InventoryConfig = require(Shared:WaitForChild("InventoryConfig"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local InventoryState = require(script.Parent:WaitForChild("InventoryState"))
local Net = require(script.Parent:WaitForChild("Net"))

local SLOT_COUNT = InventoryConfig.HOTBAR_SLOTS

local HotbarState = {}

HotbarState.SLOT_COUNT = SLOT_COUNT

-- A hotbar são os slots 1 a 10 do inventário.
HotbarState.slots = InventoryState.slots

-- Slot selecionado (1 a 10).
HotbarState.selected = vide.source(1)

-- A arma na mão ainda está presa (o servidor também recusa; checar aqui evita
-- a hotbar mostrar um slot que o servidor não trocou). Lido na hora: atributo do
-- personagem previsto não avisa quando muda.
function HotbarState.isLocked(): boolean
	local character = Players.LocalPlayer.Character
	if character == nil then
		return false
	end
	local equipped = character:GetAttribute(StatNames.Equipped)
	local item = if type(equipped) == "string" then Defs.Items[equipped] else nil
	return HeldItem.isLocked(item, character:GetAttribute(StatNames.EquipLockUntil), Workspace:GetServerTimeNow())
end

function HotbarState.select(index: number)
	if
		index >= 1
		and index <= SLOT_COUNT
		and index ~= vide.untrack(HotbarState.selected)
		and not HotbarState.isLocked()
	then
		HotbarState.selected(index)
		Net.SelectSlot.Fire(index)
	end
end

return HotbarState
