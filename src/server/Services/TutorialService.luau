--!strict
-- Tutorial da primeira partida (docs/superpowers/specs/2026-11-10-tutorial-design.md):
-- - perfil sem Tutorial.Done: cada vida começa o tutorial da etapa 1 (o
--   progresso não é salvo; cair no meio = recomeça);
-- - acompanha as etapas (Shared/Tutorial) e publica no Player os atributos
--   TutorialStep, TutorialProtected, TutorialPending e SpinPopupPending;
-- - protegido (TutorialRules.PROTECTION_SECONDS depois de nascer, ou até
--   completar): os portões ficam nos serviços de dano e de acesso, que
--   perguntam a isProtected;
-- - ao completar: Done, 2 giros normais (ShopService.give) e o pop-up da
--   roleta pendente, mostrado no menu (o cliente avisa com TutorialPopupSeen).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StatNames = require(ReplicatedStorage.Shared.StatNames)
local TutorialRules = require(ReplicatedStorage.Shared.Tutorial.TutorialRules)
local TutorialSteps = require(ReplicatedStorage.Shared.Tutorial.TutorialSteps)
local DataService = require(script.Parent.DataService)
local DeathService = require(script.Parent.DeathService)
local InventoryService = require(script.Parent.InventoryService)
local ShopService = require(script.Parent.ShopService)
local StructureService = require(script.Parent.StructureService)
local Net = require(script.Parent.Parent.Net)

local TICK = 0.25 -- s entre conferências das etapas

type State = {
	index: number,
	startedAt: number,
	protected: boolean,
	facts: TutorialRules.Facts,
}

local TutorialService = {}

local states: { [Player]: State } = {}

local function tutorialData(player: Player): { Done: boolean, SpinPopup: boolean }?
	local data = DataService.data(player)
	return if data then data.Tutorial else nil
end

local function setIfChanged(player: Player, name: string, value: any)
	if player:GetAttribute(name) ~= value then
		player:SetAttribute(name, value)
	end
end

local function publishProfile(player: Player)
	local tutorial = tutorialData(player)
	setIfChanged(player, StatNames.TutorialPending, tutorial ~= nil and not tutorial.Done)
	setIfChanged(player, StatNames.SpinPopupPending, tutorial ~= nil and tutorial.SpinPopup)
end

local function stop(player: Player)
	states[player] = nil
	setIfChanged(player, StatNames.TutorialStep, 0)
	setIfChanged(player, StatNames.TutorialProtected, false)
end

-- true se o perfil ainda não completou o tutorial (a próxima vida é de tutorial).
function TutorialService.pending(player: Player): boolean
	local tutorial = tutorialData(player)
	return tutorial ~= nil and not tutorial.Done
end

-- true enquanto o jogador está protegido (nem leva nem causa dano).
function TutorialService.isProtected(player: Player): boolean
	local state = states[player]
	return state ~= nil and state.protected
end

-- Começa o tutorial desta vida, da etapa 1 (chamado pelo SpawnService).
function TutorialService.begin(player: Player)
	if not TutorialService.pending(player) then
		stop(player)
		return
	end
	states[player] = {
		index = 1,
		startedAt = os.clock(),
		protected = true,
		facts = { counts = {}, placed = {}, viewed = {}, wetSeconds = 0 },
	}
	setIfChanged(player, StatNames.TutorialStep, 1)
	setIfChanged(player, StatNames.TutorialProtected, true)
end

local function complete(player: Player)
	stop(player)
	local tutorial = tutorialData(player)
	if tutorial == nil or tutorial.Done then
		return
	end
	tutorial.Done = true
	tutorial.SpinPopup = true
	local ok, problem = ShopService.give(
		player,
		{ kind = "spins", spin = "normal", count = TutorialRules.REWARD_SPINS } :: any,
		"tutorial"
	)
	if not ok then
		warn(`[TutorialService] prêmio de {player.Name} falhou: {problem}`)
	end
	DataService.save(player)
	publishProfile(player)
	Net.TutorialDone.Fire(player, { Spins = TutorialRules.REWARD_SPINS })
end

local function countsOf(player: Player): { [string]: number }
	local counts: { [string]: number } = {}
	local inv = InventoryService.get(player)
	if inv then
		for _, slot in inv.slots do
			counts[slot.id] = (counts[slot.id] or 0) + slot.count
		end
	end
	return counts
end

local function step(player: Player, state: State, dt: number)
	local facts = state.facts
	facts.counts = countsOf(player)
	local current = TutorialSteps.LIST[state.index]
	if current and current.goal.kind == "drink" and player:GetAttribute(StatNames.InWater) == true then
		facts.wetSeconds += dt
	end
	if state.protected and not TutorialRules.protected(state.startedAt, os.clock()) then
		state.protected = false
		setIfChanged(player, StatNames.TutorialProtected, false)
	end
	state.index = TutorialRules.advance(state.index, facts)
	if state.index > #TutorialSteps.LIST then
		complete(player)
	else
		setIfChanged(player, StatNames.TutorialStep, state.index)
	end
end

function TutorialService.Start(_self)
	DataService.onLoaded(function(player)
		publishProfile(player)
	end)
	for _, player in Players:GetPlayers() do
		if DataService.data(player) then
			publishProfile(player)
		end
	end
	DeathService.onDeath(function(player)
		stop(player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		states[player] = nil
	end)

	StructureService.onCreated(function(entry)
		local state = states[entry.owner]
		if state then
			state.facts.placed[entry.itemId] = true
		end
	end)
	Net.TutorialBookViewed.On(function(player: Player, request: { ItemId: string })
		-- Só conta na etapa de ver a ficha e do item dela (nada de encher a
		-- tabela com qualquer texto, nem pular a etapa antes da hora).
		local state = states[player]
		if state and TutorialRules.acceptsView(TutorialSteps.LIST[state.index], request.ItemId) then
			state.facts.viewed[request.ItemId] = true
		end
	end)
	Net.TutorialPopupSeen.On(function(player: Player)
		local tutorial = tutorialData(player)
		if tutorial and tutorial.SpinPopup then
			tutorial.SpinPopup = false
			DataService.save(player)
			publishProfile(player)
		end
	end)

	local elapsed = 0
	RunService.Heartbeat:Connect(function(dt)
		elapsed += dt
		if elapsed < TICK then
			return
		end
		local stepDt = elapsed
		elapsed = 0
		for player, state in states do
			step(player, state, stepDt)
		end
	end)
end

-- Comandos de dev (DevDataService): zera ou dá como feito o tutorial do perfil.
function TutorialService.devReset(player: Player): boolean
	local tutorial = tutorialData(player)
	if tutorial == nil then
		return false
	end
	tutorial.Done = false
	tutorial.SpinPopup = false
	DataService.save(player)
	publishProfile(player)
	return true
end

function TutorialService.devDone(player: Player): boolean
	local tutorial = tutorialData(player)
	if tutorial == nil then
		return false
	end
	tutorial.Done = true
	stop(player)
	DataService.save(player)
	publishProfile(player)
	return true
end

return TutorialService
