--!strict
-- Comer (G1): com uma comida na mão (atributo Equipped do personagem), apertar
-- o botão de usar (o mesmo de bater, atributo Using) come uma unidade;
-- segurando, continua comendo a cada SurvivalConfig.EAT_INTERVAL.
-- O que a comida repõe vem do bloco `food` do item em Defs/Items.
-- Só come se a comida repõe alguma barra (barras cheias não gastam comida).
-- Para a fase de combate/coleta: com comida na mão, o golpe deve ser ignorado.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local SurvivalConfig = require(ReplicatedStorage.Shared.SurvivalConfig)
local InventoryService = require(script.Parent.InventoryService)
local SurvivalService = require(script.Parent.SurvivalService)

local REPEAT_CHECK = 0.1 -- segundos entre conferências de quem está segurando

local FoodService = {}

local lastEat: { [Player]: number } = {}

local function tryEat(player: Player)
	local character = player.Character
	if character == nil or character:FindFirstChildOfClass("Humanoid") == nil then
		return
	end
	local now = os.clock()
	local last = lastEat[player]
	if last and now - last < SurvivalConfig.EAT_INTERVAL then
		return
	end
	local itemId = character:GetAttribute(StatNames.Equipped)
	local def = if type(itemId) == "string" then Defs.Items[itemId] else nil
	local food = def and def.food
	if def == nil or food == nil then
		return
	end
	-- Confere antes de tirar o item: barras cheias não gastam comida.
	if not SurvivalService.canEat(player, food) then
		return
	end
	if not InventoryService.take(player, def.id, 1) then
		return
	end
	lastEat[player] = now
	SurvivalService.applyFood(player, food)
end

local function setupCharacter(player: Player, character: Model)
	character:GetAttributeChangedSignal(StatNames.Using):Connect(function()
		if character:GetAttribute(StatNames.Using) == true and player.Character == character then
			tryEat(player)
		end
	end)
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		setupCharacter(player, player.Character)
	end
end

function FoodService.Start(_self)
	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		lastEat[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end

	-- Segurar o botão continua comendo (o sinal acima só pega o aperto).
	task.spawn(function()
		while true do
			task.wait(REPEAT_CHECK)
			for _, player in Players:GetPlayers() do
				local character = player.Character
				if character and character:GetAttribute(StatNames.Using) == true then
					tryEat(player)
				end
			end
		end
	end)
end

return FoodService
