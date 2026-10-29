--!strict
-- SÓ PARA DESENVOLVIMENTO (roda apenas no Studio).
-- Dá um kit de itens ao entrar e libera a mochila, para testar o inventário
-- antes da coleta existir. Também cria ServerStorage.DevGive (BindableFunction)
-- para dar itens em testes: DevGive:Invoke(player, "wood", 300) -> sobra.
-- Some quando a coleta (fase de gameplay) estiver pronta.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local StatNames = require(ReplicatedStorage.Shared.StatNames)
local InventoryService = require(script.Parent.InventoryService)

local KIT: { { id: string, count: number } } = {
	{ id = "wood", count = 24 },
	{ id = "stone", count = 12 },
	{ id = "gold", count = 5 },
	{ id = "berry", count = 8 },
	{ id = "wood_pickaxe", count = 1 },
	{ id = "stone_pickaxe", count = 1 },
	{ id = "gold_pickaxe", count = 1 },
}

local DevItemsService = {}

local function giveKit(player: Player)
	player:SetAttribute(StatNames.HasBag, true)
	for _, item in KIT do
		InventoryService.give(player, item.id, item.count)
	end
end

function DevItemsService.Start(_self)
	if not RunService:IsStudio() then
		return
	end

	local devGive = Instance.new("BindableFunction")
	devGive.Name = "DevGive"
	devGive.OnInvoke = function(player: Player, id: string, count: number): number
		return InventoryService.give(player, id, count)
	end
	devGive.Parent = ServerStorage

	Players.PlayerAdded:Connect(giveKit)
	for _, player in Players:GetPlayers() do
		giveKit(player)
	end
end

return DevItemsService
