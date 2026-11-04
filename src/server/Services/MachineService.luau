--!strict
-- Extrator e fornalha (G8): máquinas a madeira, regras no MachineRules.
--
-- Extrator: o jogador põe madeira (put_wood) e ele a troca devagar por
-- pedra/ouro (def.extractor.output), que fica no estoque até alguém pegar
-- (take: o que couber no inventário; o resto fica). Fornalha: só põe madeira
-- (não volta); queima 1 a cada def.furnace.burnEvery e, enquanto tem madeira,
-- está acesa: esquenta (tag HeatSource + HeatRadius = def.heatRadius, sem
-- BurnRadius: não queima quem está em cima) e é estação "fire". Apagada, sai
-- das duas tags (a estação também; o StructureModel a pôs na montagem).
--
-- O estado vive SÓ aqui no servidor, por peça; os atributos Wood/Stock/Working
-- (extrator) e Wood/Lit (fornalha) no modelo são a cópia que todos veem.
-- Nasce com a peça (StructureService.onCreated) e some com ela (onRemoved).
-- Um loop só, a cada TICK segundos, avança todas as máquinas.
--
-- Os pedidos chegam já conferidos pelo InteractService (taxa, distância, ação
-- do tipo). Entre conferir e mudar não há pausa (yield), como no baú.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Inventory = require(ReplicatedStorage.Shared.Inventory)
local InteractRules = require(ReplicatedStorage.Shared.Build.InteractRules)
local MachineRules = require(ReplicatedStorage.Shared.Build.MachineRules)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local InteractService = require(script.Parent.InteractService)
local InventoryService = require(script.Parent.InventoryService)
local StructureService = require(script.Parent.StructureService)

-- Segundos entre passos do loop das máquinas.
local TICK = 0.5

type Entry = StructureService.Entry

local extractors: { [Entry]: MachineRules.ExtractorState } = {}
local furnaces: { [Entry]: MachineRules.FurnaceState } = {}

local MachineService = {}

-- Copia o estado do extrator para os atributos do modelo (todos veem).
local function publishExtractor(entry: Entry, state: MachineRules.ExtractorState, def: MachineRules.ExtractorDef)
	local model = entry.model
	model:SetAttribute(StatNames.Wood, state.wood)
	model:SetAttribute(StatNames.Stock, state.stock)
	model:SetAttribute(StatNames.Working, MachineRules.isWorking(state, def))
end

-- Copia o estado da fornalha para o modelo: madeira, Lit e as tags de calor e
-- de estação (só acesa).
local function publishFurnace(entry: Entry, state: MachineRules.FurnaceState)
	local model = entry.model
	local lit = MachineRules.isLit(state)
	model:SetAttribute(StatNames.Wood, state.wood)
	model:SetAttribute(StatNames.Lit, lit)
	if lit then
		model:SetAttribute(StatNames.HeatRadius, entry.def.heatRadius)
		model:AddTag(StatNames.HeatSourceTag)
		if entry.def.station then
			model:AddTag(StatNames.CraftStationTag)
		end
	else
		model:RemoveTag(StatNames.HeatSourceTag)
		model:RemoveTag(StatNames.CraftStationTag)
		model:SetAttribute(StatNames.HeatRadius, nil)
	end
end

-- Peça nova: extrator e fornalha começam vazios (a fornalha, apagada).
local function onCreated(entry: Entry)
	local def = entry.def
	if def.kind == "extractor" and def.extractor then
		local state = { wood = 0, stock = 0, timer = 0 }
		extractors[entry] = state
		publishExtractor(entry, state, def.extractor)
	elseif def.kind == "furnace" and def.furnace then
		local state = { wood = 0, timer = 0 }
		furnaces[entry] = state
		publishFurnace(entry, state)
	end
end

-- Quantas madeiras o jogador tem (todos os slots).
local function woodOf(player: Player): number
	local inv = InventoryService.get(player)
	return if inv then Inventory.count(inv, MachineRules.FUEL) else 0
end

-- Tira até MachineRules.WOOD_PER_PUT madeiras do jogador (qualquer slot) para
-- a máquina, até o máximo dela. Devolve quanto entrou (0 = nada mudou).
local function putWood(player: Player, wood: number, maxWood: number): number
	local amount = MachineRules.putWood(wood, woodOf(player), maxWood)
	if amount <= 0 or not InventoryService.take(player, MachineRules.FUEL, amount) then
		return 0
	end
	return amount
end

local function onExtractor(player: Player, entry: Entry, action: number, _arg: number)
	local state = extractors[entry]
	local def = entry.def.extractor
	if state == nil or def == nil then
		return
	end
	if action == InteractRules.ACTIONS.put_wood then
		local amount = putWood(player, state.wood, def.maxWood)
		if amount <= 0 then
			return
		end
		state.wood += amount
	elseif action == InteractRules.ACTIONS.take then
		local id = def.output
		-- Quanto cabe é calculado sem mudar o inventário; só depois tira e dá.
		local amount = math.min(state.stock, InventoryService.spaceFor(player, id))
		if amount <= 0 then
			return
		end
		state.stock -= amount
		-- Não sobra (spaceFor = o que give aceita); se sobrar, volta ao estoque.
		state.stock += InventoryService.give(player, id, amount)
	else
		return
	end
	publishExtractor(entry, state, def)
end

local function onFurnace(player: Player, entry: Entry, action: number, _arg: number)
	local state = furnaces[entry]
	local def = entry.def.furnace
	if state == nil or def == nil or action ~= InteractRules.ACTIONS.put_wood then
		return
	end
	local amount = putWood(player, state.wood, def.maxWood)
	if amount <= 0 then
		return
	end
	state.wood += amount
	publishFurnace(entry, state)
end

-- Avança todas as máquinas `dt` segundos e publica o que mudou.
local function step(dt: number)
	for entry, state in extractors do
		local def = entry.def.extractor
		if def == nil then
			continue
		end
		local nextState = MachineRules.extractorStep(state, def, dt)
		extractors[entry] = nextState
		if nextState.wood ~= state.wood or nextState.stock ~= state.stock then
			publishExtractor(entry, nextState, def)
		end
	end
	for entry, state in furnaces do
		local def = entry.def.furnace
		if def == nil then
			continue
		end
		local nextState = MachineRules.furnaceStep(state, def, dt)
		furnaces[entry] = nextState
		if nextState.wood ~= state.wood then
			publishFurnace(entry, nextState)
		end
	end
end

function MachineService.Start(_self)
	StructureService.onCreated(onCreated)
	-- O estado some com a peça (a "ficha" da peça nunca é reaproveitada).
	StructureService.onRemoved(function(entry: Entry)
		extractors[entry] = nil
		furnaces[entry] = nil
	end)
	InteractService.register("extractor", onExtractor)
	InteractService.register("furnace", onFurnace)
	task.spawn(function()
		local last = os.clock()
		while true do
			task.wait(TICK)
			local now = os.clock()
			local ok, err = pcall(step :: any, now - last)
			if not ok then
				warn(`[MachineService] {err}`)
			end
			last = now
		end
	end)
end

return MachineService
