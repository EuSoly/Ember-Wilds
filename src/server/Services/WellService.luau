--!strict
-- Poço e balde (G8). Regras no WellRules.
--
-- Balde: com `bucket` na mão, apertar/segurar o botão de usar (atributo Using
-- do personagem, como o FoodService) perto de água (WaterSim.isWaterAt, até
-- FILL_RANGE studs) troca o balde, no mesmo slot, por `water_bucket`.
-- Poço: `fill` com `water_bucket` na mão esvazia o balde nele (+drinksPerBucket
-- goles, até maxDrinks) e volta a `bucket`; `drink` gasta 1 gole e mata a sede
-- (SurvivalService.applyFood, recusa se a sede já está cheia). Qualquer um bebe.
--
-- O número de goles vive SÓ aqui no servidor, por peça (nasce com ela, some com
-- ela); o atributo Drinks no modelo é a cópia que todos veem.
-- Os pedidos de ação chegam já conferidos pelo InteractService.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local InteractRules = require(ReplicatedStorage.Shared.Build.InteractRules)
local WellRules = require(ReplicatedStorage.Shared.Build.WellRules)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local WaterSim = require(ReplicatedStorage.Shared.Simulation.WaterSim)
local InteractService = require(script.Parent.InteractService)
local InventoryService = require(script.Parent.InventoryService)
local StructureService = require(script.Parent.StructureService)
local SurvivalService = require(script.Parent.SurvivalService)

local BUCKET = "bucket"
local WATER_BUCKET = "water_bucket"
-- Água "perto": até tantos studs da raiz do jogador (centro + 8 pontos do círculo).
local FILL_RANGE = 3
local FILL_POINTS = 8
-- Segundos mínimos entre dois enchimentos do mesmo jogador.
local FILL_INTERVAL = 0.5
local REPEAT_CHECK = 0.1 -- segundos entre conferências de quem está segurando

type Entry = StructureService.Entry

local drinks: { [Entry]: number } = {}
local lastFill: { [Player]: number } = {}

local WellService = {}

local function heldItem(player: Player): string?
	local character = player.Character
	local id = if character then character:GetAttribute(StatNames.Equipped) else nil
	return if type(id) == "string" then id else nil
end

-- Há água a até FILL_RANGE studs de (x, z)? Amostra o centro e FILL_POINTS pontos.
local function waterNear(x: number, z: number): boolean
	if WaterSim.isWaterAt(x, z) then
		return true
	end
	for i = 0, FILL_POINTS - 1 do
		local angle = i * (2 * math.pi / FILL_POINTS)
		if WaterSim.isWaterAt(x + math.cos(angle) * FILL_RANGE, z + math.sin(angle) * FILL_RANGE) then
			return true
		end
	end
	return false
end

local function tryFillBucket(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if root == nil or not root:IsA("BasePart") or heldItem(player) ~= BUCKET then
		return
	end
	local now = os.clock()
	local last = lastFill[player]
	if last and now - last < FILL_INTERVAL then
		return
	end
	if not waterNear(root.Position.X, root.Position.Z) then
		return
	end
	if InventoryService.swapAt(player, InventoryService.selectedSlot(player), BUCKET, WATER_BUCKET) then
		lastFill[player] = now
	end
end

local function setupCharacter(player: Player, character: Model)
	character:GetAttributeChangedSignal(StatNames.Using):Connect(function()
		if character:GetAttribute(StatNames.Using) == true and player.Character == character then
			tryFillBucket(player)
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

local function onWell(player: Player, entry: Entry, action: number, _arg: number)
	local count = drinks[entry]
	local def = entry.def.well
	if count == nil or def == nil then
		return
	end
	if action == InteractRules.ACTIONS.drink then
		local after = WellRules.drink(count)
		local food = { thirst = def.thirstPerDrink }
		if after == nil or not SurvivalService.canEat(player, food) then
			return
		end
		if not SurvivalService.applyFood(player, food) then
			return
		end
		drinks[entry] = after
	elseif action == InteractRules.ACTIONS.fill then
		local after = WellRules.fill(count, def)
		if after == nil or heldItem(player) ~= WATER_BUCKET then
			return
		end
		if not InventoryService.swapAt(player, InventoryService.selectedSlot(player), WATER_BUCKET, BUCKET) then
			return
		end
		drinks[entry] = after
	else
		return
	end
	entry.model:SetAttribute(StatNames.Drinks, drinks[entry])
end

function WellService.Start(_self)
	StructureService.onCreated(function(entry: Entry)
		if entry.def.kind == "well" and entry.def.well then
			drinks[entry] = 0
			entry.model:SetAttribute(StatNames.Drinks, 0)
		end
	end)
	StructureService.onRemoved(function(entry: Entry)
		drinks[entry] = nil
	end)
	InteractService.register("well", onWell)

	Players.PlayerAdded:Connect(setupPlayer)
	Players.PlayerRemoving:Connect(function(player)
		lastFill[player] = nil
	end)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end

	-- Segurar o botão também enche (o sinal acima só pega o aperto).
	task.spawn(function()
		while true do
			task.wait(REPEAT_CHECK)
			for _, player in Players:GetPlayers() do
				local character = player.Character
				if character and character:GetAttribute(StatNames.Using) == true then
					tryFillBucket(player)
				end
			end
		end
	end)
end

return WellService
