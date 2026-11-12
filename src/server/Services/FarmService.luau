--!strict
-- Fazenda (12/11): canteiros e plantas. Regras puras no PlantRules; números de
-- cada cultura no bloco `structure.plant` da semente (Defs/Items).
--
-- Canteiro (kind "plot"): peça da camada do chão, em grade. Guarda a rega da
-- planta que estiver nele, e a terra do modelo mostra se está molhada.
-- Planta (kind "plant"): nasce no centro do canteiro (o StructureService
-- encaixa) ou no chão da floresta, com a rega própria. Um passo de STEP_EVERY
-- avança todas (PlantRules.step), troca o estágio do modelo, mostra os frutos,
-- amarela as folhas da planta seca no chão e tira as velhas.
--
-- Golpe (GatherService → FarmService.hit): regador cheio na mão rega a planta
-- ou o canteiro (a túnica de quem rega acelera a planta enquanto durar a rega);
-- planta com fruto é colhida (forcado: harvest). Sem isso, o golpe é o de
-- construção (StructureService.hit) e tira vida.
-- Regador vazio: segurar o botão de usar perto da água troca pelo cheio, como
-- o balde do WellService.
-- O estado vive só no servidor, por peça (nasce e some com ela).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Defs = require(ReplicatedStorage.Shared.Defs)
local PlantRules = require(ReplicatedStorage.Shared.Farm.PlantRules)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local StructureModel = require(ReplicatedStorage.Shared.Models.StructureModel)
local WaterSim = require(ReplicatedStorage.Shared.Simulation.WaterSim)
local ArmorService = require(script.Parent.ArmorService)
local InventoryService = require(script.Parent.InventoryService)
local ScoreService = require(script.Parent.ScoreService)
local StatsService = require(script.Parent.StatsService)
local StructureService = require(script.Parent.StructureService)

type Entry = StructureService.Entry

local STEP_EVERY = 1 -- segundos (plantas a 1 Hz, como o resto do mundo)
local CAN = "watering_can"
local CAN_FULL = "watering_can_full"
local FILL_RANGE = 3 -- studs da raiz até a água para encher o regador
local FILL_INTERVAL = 0.5
local REPEAT_CHECK = 0.1

type Plot = { entry: Entry, water: PlantRules.Water, plant: Entry? }
type Plant = {
	entry: Entry,
	def: Defs.PlantDef,
	state: PlantRules.State,
	-- Rega própria (planta no chão); no canteiro vale a do canteiro.
	water: PlantRules.Water,
	plot: Plot?,
}

local plots: { [Entry]: Plot } = {}
local plants: { [Entry]: Plant } = {}
local lastFill: { [Player]: number } = {}

local FarmService = {}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function waterOf(plant: Plant): PlantRules.Water
	local plot = plant.plot
	return if plot then plot.water else plant.water
end

-- Visual da planta pelo estado: estágio, frutos e (no chão) folhas secas.
local function refreshPlant(plant: Plant, t: number)
	local model = plant.entry.model
	local lift = if plant.plot then StructureModel.soilHeight() else 0
	StructureModel.setPlantStage(model, plant.def.crop, PlantRules.stage(plant.state), lift)
	StructureModel.setPlantFruit(model, plant.state.fruit)
	StructureModel.setPlantDry(model, plant.plot == nil and not PlantRules.isWet(plant.water, t))
	model:SetAttribute(StatNames.PlantFruit, plant.state.fruit)
	model:SetAttribute(StatNames.PlantWet, PlantRules.isWet(waterOf(plant), t))
end

local function refreshPlot(plot: Plot, t: number)
	local wet = PlantRules.isWet(plot.water, t)
	StructureModel.setSoilWet(plot.entry.model, wet)
	plot.entry.model:SetAttribute(StatNames.PlantWet, wet)
end

-- O canteiro com o centro em (x, z), se houver (a semente encaixada vai nele).
local function plotAt(x: number, z: number): Plot?
	for _, entry in StructureService.near(x, z, 0) do
		local plot = plots[entry]
		if plot and math.abs(entry.x - x) < 1e-3 and math.abs(entry.z - z) < 1e-3 then
			return plot
		end
	end
	return nil
end

local function onCreated(entry: Entry)
	local t = now()
	if entry.def.kind == "plot" then
		local plot: Plot = { entry = entry, water = PlantRules.newWater() }
		plots[entry] = plot
		refreshPlot(plot, t)
	elseif entry.def.kind == "plant" and entry.def.plant then
		local plant: Plant = {
			entry = entry,
			def = entry.def.plant,
			state = PlantRules.new(t),
			water = PlantRules.newWater(),
		}
		local plot = plotAt(entry.x, entry.z)
		if plot and plot.plant == nil then
			plant.plot = plot
			plot.plant = entry
		end
		plants[entry] = plant
		refreshPlant(plant, t)
	end
end

local function onRemoved(entry: Entry)
	local plant = plants[entry]
	if plant then
		plants[entry] = nil
		if plant.plot and plant.plot.plant == entry then
			plant.plot.plant = nil
		end
	end
	local plot = plots[entry]
	if plot then
		plots[entry] = nil
		-- A planta vai junto com o canteiro.
		local onIt = plot.plant
		if onIt then
			StructureService.remove(onIt)
		end
	end
end

local function step(dt: number)
	local t = now()
	local dead: { Entry } = {}
	for entry, plant in plants do
		PlantRules.step(plant.state, plant.def, t, dt, waterOf(plant), plant.plot ~= nil)
		if PlantRules.isDead(plant.state, plant.def, t) then
			table.insert(dead, entry)
		else
			refreshPlant(plant, t)
		end
	end
	for _, plot in plots do
		refreshPlot(plot, t)
	end
	for _, entry in dead do
		StructureService.remove(entry)
	end
end

-- Regar: a planta (ou o canteiro dela) fica molhada por waterSeconds, com o
-- bônus da túnica de quem regou.
local function water(target: Entry, player: Player): boolean
	local t = now()
	local worn = ArmorService.worn(player)
	local cropGrowth = worn and worn.armor and worn.armor.cropGrowth
	local plant = plants[target]
	local plot = if plant then plant.plot else plots[target]
	if plot then
		-- O canteiro vazio guarda a rega para a próxima semente (tempo da baga se não tiver planta).
		local onIt = plot.plant and plants[plot.plant]
		local def = if onIt then onIt.def else (Defs.Items.berry_seed.structure :: any).plant
		PlantRules.water(plot.water, def, t, cropGrowth)
		refreshPlot(plot, t)
		if onIt then
			refreshPlant(onIt, t)
		end
		return true
	end
	if plant then
		PlantRules.water(plant.water, plant.def, t, cropGrowth)
		refreshPlant(plant, t)
		return true
	end
	return false
end

local function harvest(plant: Plant, player: Player, tool: Defs.ItemDef?): boolean
	if plant.state.fruit <= 0 then
		return false
	end
	local wanted = math.min(PlantRules.harvestOf(tool), plant.state.fruit)
	local given = wanted - InventoryService.give(player, plant.def.fruit, wanted)
	if given > 0 then
		PlantRules.harvest(plant.state, given)
		ScoreService.add(player, given * plant.def.fruitPoints)
		StatsService.add(player, "resources_gathered", given, plant.def.fruit)
		refreshPlant(plant, now())
	end
	-- Mochila cheia: o golpe não quebra a planta (fica com os frutos).
	return true
end

export type HitResult = "water" | "harvest" | "full"

-- Golpe numa peça. Devolve o que a fazenda fez (nil = não é com ela: segue o
-- golpe de construção). `tool` = item na mão (nil = mão).
function FarmService.hit(entry: Entry, player: Player, tool: Defs.ItemDef?): HitResult?
	if tool and tool.waters and (plants[entry] or plots[entry]) then
		return if water(entry, player) then "water" else nil
	end
	local plant = plants[entry]
	if plant and plant.state.fruit > 0 then
		local before = plant.state.fruit
		harvest(plant, player, tool)
		return if plant.state.fruit < before then "harvest" else "full"
	end
	return nil
end

-- Planta madura com espinho (arbusto) machuca quem encosta (SpikeService).
function FarmService.hurts(entry: Entry): boolean
	local plant = plants[entry]
	return plant ~= nil and entry.def.spikeDamage ~= nil and PlantRules.hurts(plant.state)
end

-- Encher o regador: regador vazio na mão, segurando o botão perto da água.
local function tryFillCan(player: Player)
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if character == nil or root == nil or not root:IsA("BasePart") then
		return
	end
	if character:GetAttribute(StatNames.Equipped) ~= CAN then
		return
	end
	local t = os.clock()
	local last = lastFill[player]
	if last and t - last < FILL_INTERVAL then
		return
	end
	if not WaterSim.isNearWater(root.Position.X, root.Position.Z, FILL_RANGE) then
		return
	end
	if InventoryService.swapAt(player, InventoryService.selectedSlot(player), CAN, CAN_FULL) then
		lastFill[player] = t
	end
end

function FarmService.Start(_self)
	StructureService.onCreated(onCreated)
	StructureService.onRemoved(onRemoved)
	-- SÓ NO STUDIO: ServerStorage.DevFarm:Invoke(segundos) avança as plantas
	-- (como se tivessem passado molhadas, se a rega cobrir) e devolve um resumo.
	if RunService:IsStudio() then
		local command = Instance.new("BindableFunction")
		command.Name = "DevFarm"
		command.OnInvoke = function(seconds: number): string
			if type(seconds) == "number" and seconds > 0 then
				step(seconds)
			end
			local lines = {}
			for entry, plant in plants do
				table.insert(
					lines,
					string.format(
						"%s grown=%.2f stage=%d fruit=%d wet=%s plot=%s",
						entry.itemId,
						plant.state.grown,
						PlantRules.stage(plant.state),
						plant.state.fruit,
						tostring(PlantRules.isWet(waterOf(plant), now())),
						tostring(plant.plot ~= nil)
					)
				)
			end
			return table.concat(lines, " | ")
		end
		command.Parent = ServerStorage
	end
	Players.PlayerRemoving:Connect(function(player)
		lastFill[player] = nil
	end)
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(STEP_EVERY)
			local t = os.clock()
			local ok, err = pcall(step :: any, t - last)
			last = t
			if not ok then
				warn(`[FarmService] {err}`)
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(REPEAT_CHECK)
			for _, player in Players:GetPlayers() do
				local character = player.Character
				if character and character:GetAttribute(StatNames.Using) == true then
					tryFillCan(player)
				end
			end
		end
	end)
end

return FarmService
