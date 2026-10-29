--!strict
-- Sobrevivência (G1): dono dos atributos Health, Hunger, Cold e Thirst do
-- Player (o HUD lê). A cada SurvivalConfig.TICK, para cada jogador vivo, monta
-- o contexto (noite, água, fôlego, fogo perto, armadura) e chama
-- SurvivalRules.step; o dano das barras vazias vai para CharacterService.hurt
-- (que mata com a causa certa quando a vida zera). Cada vida nova começa cheia.
-- Números em SurvivalConfig; veja docs/guia/sobrevivencia.md.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local DayCycle = require(ReplicatedStorage.Shared.DayCycle)
local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local SurvivalConfig = require(ReplicatedStorage.Shared.SurvivalConfig)
local SurvivalRules = require(ReplicatedStorage.Shared.Survival.SurvivalRules)
local ArmorService = require(script.Parent.ArmorService)
local CharacterService = require(script.Parent.CharacterService)

local SurvivalService = {}

-- Grava o valor exato: arredondar a cada passo acumula erro (com passos de
-- 0,25 a barra caía 0,3 por passo, ~18% rápido demais).
local function setIfChanged(player: Player, name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

local function readBars(player: Player): SurvivalRules.Bars
	-- Valores estranhos (nil, NaN) as regras tratam como cheio.
	return {
		health = player:GetAttribute(StatNames.Health) :: any,
		hunger = player:GetAttribute(StatNames.Hunger) :: any,
		cold = player:GetAttribute(StatNames.Cold) :: any,
		thirst = player:GetAttribute(StatNames.Thirst) :: any,
	}
end

local function writeBars(player: Player, bars: SurvivalRules.Bars)
	setIfChanged(player, StatNames.Health, bars.health)
	setIfChanged(player, StatNames.Hunger, bars.hunger)
	setIfChanged(player, StatNames.Cold, bars.cold)
	setIfChanged(player, StatNames.Thirst, bars.thirst)
end

-- Raiz do personagem vivo do jogador (nil no menu, morto ou montando).
local function aliveRoot(player: Player): BasePart?
	local character = player.Character
	if character == nil or character:FindFirstChildOfClass("Humanoid") == nil then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	return if root and root:IsA("BasePart") then root else nil
end

local function isNight(): boolean
	local start = Workspace:GetAttribute(StatNames.CycleStart)
	if type(start) ~= "number" then
		return false
	end
	return DayCycle.at(Workspace:GetServerTimeNow() - start).isNight
end

-- Alguma fonte de calor (tag HeatSource) alcança `position` no plano XZ?
local function nearFire(position: Vector3): boolean
	for _, source in CollectionService:GetTagged(StatNames.HeatSourceTag) do
		-- Fogueira apagada/destruída no meio do tick: ignora.
		if source.Parent == nil then
			continue
		end
		local radius = source:GetAttribute(StatNames.HeatRadius)
		if type(radius) ~= "number" then
			continue
		end
		local center: Vector3
		if source:IsA("Model") then
			center = source:GetPivot().Position
		elseif source:IsA("BasePart") then
			center = source.Position
		else
			continue
		end
		local dx, dz = center.X - position.X, center.Z - position.Z
		if dx * dx + dz * dz <= radius * radius then
			return true
		end
	end
	return false
end

local function step(player: Player, dt: number, night: boolean)
	local root = aliveRoot(player)
	if root == nil then
		return
	end
	local oxygen = player:GetAttribute(StatNames.Oxygen)
	local result = SurvivalRules.step(readBars(player), {
		isNight = night,
		inWater = player:GetAttribute(StatNames.InWater) == true,
		nearFire = nearFire(root.Position),
		oxygen = if type(oxygen) == "number" then oxygen else StatNames.StatusMax,
		mods = ArmorService.modifiers(player),
		-- Só a floresta é jogável; o inverno (N2) vai escolher pelo bioma da posição.
		biomeColdFactor = SurvivalConfig.BIOME_COLD_FACTOR.forest,
	}, dt)
	writeBars(player, result.bars)
	local cause = result.cause
	if result.damage > 0 and cause then
		local character = player.Character
		if character then
			CharacterService.hurt(character, result.damage, SurvivalRules.CAUSE_KEYS[cause :: any], "survival")
		end
	end
end

-- Aplica uma comida às barras do jogador. false = nada a repor (tudo cheio).
function SurvivalService.applyFood(player: Player, food: Defs.FoodEffect): boolean
	local after = SurvivalRules.eat(readBars(player), food)
	if after == nil then
		return false
	end
	writeBars(player, after)
	return true
end

-- true se comer `food` agora repõe alguma barra (sem gravar nada).
function SurvivalService.canEat(player: Player, food: Defs.FoodEffect): boolean
	return SurvivalRules.eat(readBars(player), food) ~= nil
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function()
		writeBars(player, SurvivalRules.full())
	end)
	if player.Character then
		writeBars(player, SurvivalRules.full())
	end
end

function SurvivalService.Start(_self)
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end

	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(SurvivalConfig.TICK)
			local now = os.clock()
			local dt = now - last
			last = now
			local night = isNight()
			for _, player in Players:GetPlayers() do
				-- Um erro com um jogador não para as barras dos outros.
				local ok, err = pcall(step :: any, player, dt, night)
				if not ok then
					warn(`[SurvivalService] {player.Name}: {err}`)
				end
			end
		end
	end)
end

return SurvivalService
