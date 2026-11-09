--!strict
-- Comer (G1, com tempo desde 09/11): com uma comida na mão (atributo Equipped
-- do personagem), apertar o botão de usar (o mesmo de bater, atributo Using)
-- começa uma mordida de SurvivalConfig.EAT_DURATION segundos. Só no fim dela a
-- comida sai do inventário e repõe as barras; segurando o botão, a próxima
-- mordida emenda na hora.
-- O atributo EatUntil do personagem guarda quando a mordida termina: o boneco
-- anima por ele (todos veem) e a simulação deixa o jogador mais lento
-- (SurvivalConfig.EAT_SPEED_FACTOR, no WaterSim).
-- Trocar o item da mão (ou morrer) no meio cancela sem gastar a comida.
-- Levar dano não interrompe. Barras cheias não começam a mordida.
-- O que a comida repõe vem do bloco `food` do item em Defs/Items.
-- Com comida na mão o golpe é ignorado (GatherService).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local SurvivalConfig = require(ReplicatedStorage.Shared.SurvivalConfig)
local InventoryService = require(script.Parent.InventoryService)
local SurvivalService = require(script.Parent.SurvivalService)

local CHECK_EVERY = 0.05 -- segundos entre conferências (fim da mordida, cancelar, segurar)

local FoodService = {}

type Bite = { character: Model, itemId: string, finishAt: number }

-- Mordida em andamento de cada jogador.
local bites: { [Player]: Bite } = {}

local function equippedFood(character: Model): (string?, Defs.FoodEffect?)
	local itemId = character:GetAttribute(StatNames.Equipped)
	local def = if type(itemId) == "string" then Defs.Items[itemId] else nil
	if def == nil or def.food == nil then
		return nil, nil
	end
	return def.id, def.food
end

local function stop(player: Player)
	local bite = bites[player]
	if bite == nil then
		return
	end
	bites[player] = nil
	if bite.character.Parent ~= nil then
		bite.character:SetAttribute(StatNames.EatUntil, nil)
	end
end

-- Começa uma mordida se der: personagem vivo, comida na mão (o Equipped vem do
-- slot selecionado, então o item está no inventário) e alguma barra a repor.
local function tryStart(player: Player)
	if bites[player] then
		return
	end
	local character = player.Character
	if character == nil or character:FindFirstChildOfClass("Humanoid") == nil then
		return
	end
	local itemId, food = equippedFood(character)
	if itemId == nil or food == nil then
		return
	end
	if not SurvivalService.canEat(player, food) then
		return
	end
	local finishAt = Workspace:GetServerTimeNow() + SurvivalConfig.EAT_DURATION
	bites[player] = { character = character, itemId = itemId, finishAt = finishAt }
	character:SetAttribute(StatNames.EatUntil, finishAt)
end

-- Fim da mordida: tira a comida e repõe as barras (se ainda fizer sentido).
local function finish(player: Player, bite: Bite)
	stop(player)
	local def = Defs.Items[bite.itemId]
	local food = def and def.food
	if food == nil or not SurvivalService.canEat(player, food) then
		return
	end
	if InventoryService.take(player, bite.itemId, 1) then
		SurvivalService.applyFood(player, food)
	end
end

local function step()
	local now = Workspace:GetServerTimeNow()
	for player, bite in bites do
		local character = player.Character
		local itemId = if character ~= nil and character == bite.character then (equippedFood(character)) else nil
		if itemId ~= bite.itemId then
			-- Trocou de item, morreu ou trocou de personagem: cancela sem gastar.
			stop(player)
		elseif now >= bite.finishAt then
			finish(player, bite)
		end
	end
	-- Segurando o botão: começa (ou emenda) a próxima mordida.
	for _, player in Players:GetPlayers() do
		local character = player.Character
		if character and character:GetAttribute(StatNames.Using) == true then
			tryStart(player)
		end
	end
end

local function setupCharacter(player: Player, character: Model)
	character:GetAttributeChangedSignal(StatNames.Using):Connect(function()
		if character:GetAttribute(StatNames.Using) == true and player.Character == character then
			tryStart(player)
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
		bites[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end

	task.spawn(function()
		while true do
			task.wait(CHECK_EVERY)
			step()
		end
	end)
end

return FoodService
