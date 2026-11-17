--!strict
-- Revive pago (spec 2026-11-17-monetizacao, seção 4.6; regras em
-- Shared/Survival/ReviveRules).
--
-- - Gancho do DeathService (depois do fantasma, antes dos ouvintes): se o
--   morto é elegível (fora do criativo e do tutorial, com perfil e com algum
--   item), tira a foto do inventário (InventoryService.snapshot), calcula a
--   oferta e abre a janela. A caixa cai trancada (CrateService), as peças e o
--   totem ficam, e o LifeEnded leva a oferta para a tela de morte.
-- - Resposta (Net.RequestRevive; só a 1ª vale):
--   - sim: cobra (revive guardado, grátis do VIP ou Robux pelo degrau) →
--     nasce no totem do time ou na floresta (SpawnService.spawnAt) → tira a
--     caixa do mundo → devolve a foto (InventoryService.restore) → vida e
--     barras cheias → SHIELD_SECONDS de proteção (SpawnShieldUntil) →
--     ReviveClosed { Revived = true }. A caixa só some DEPOIS de nascer: se o
--     nascimento falhar, a cobrança volta como revive guardado (ou o grátis
--     do VIP volta) e conta como "não". Os itens nunca duplicam: a caixa
--     trancada não é aberta por ninguém e some antes de a foto voltar.
--   - não, o tempo acabou (DECISION_SECONDS, laço único a cada TICK) ou saiu
--     do jogo: destranca a caixa, DeathService.finalize (peças somem,
--     real_deaths) e ReviveClosed { Revived = false }.
--   - nasceu pelo menu com a janela aberta: conta como "não".
-- - Corrida: da entrada pelo menu até a morte final. A contagem de revives
--   (grátis inclusos, para o degrau) e o grátis do VIP usado zeram no
--   nascimento pelo menu (SpawnService.onSpawned com viaMenu), não no revive.
-- - Compra do Roblox (fase 9): purchaseStarted/purchaseEnded pausam a janela
--   (até PURCHASE_PAUSE_MAX); pagamento confirmado com a janela já fechada =
--   lateRevive (1 revive guardado no perfil). Nesta branch a cobrança é
--   instantânea e ninguém chama esses três.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local InventorySnapshot = require(ReplicatedStorage.Shared.InventorySnapshot)
local ReviveRules = require(ReplicatedStorage.Shared.Survival.ReviveRules)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local CrateService = require(script.Parent.CrateService)
local CreativeService = require(script.Parent.CreativeService)
local DataService = require(script.Parent.DataService)
local DeathService = require(script.Parent.DeathService)
local InventoryService = require(script.Parent.InventoryService)
local PerkService = require(script.Parent.PerkService)
local ShopService = require(script.Parent.ShopService)
local SpawnService = require(script.Parent.SpawnService)
local TutorialService = require(script.Parent.TutorialService)
local Net = require(script.Parent.Parent.Net)

local TICK = 0.5 -- s entre conferências do tempo das janelas

type Paid = "credit" | "vip" | "robux"

type State = {
	rules: ReviveRules.Pending,
	offer: ReviveRules.Offer,
	snapshot: InventorySnapshot.Snapshot,
}

local ReviveService = {}

-- Janela aberta de cada morto (nil = sem revive pendente).
local pendings: { [Player]: State } = {}
-- Revives usados nesta corrida (grátis inclusos) e se o grátis do VIP já foi.
local usedThisRun: { [Player]: number } = {}
local vipFreeUsed: { [Player]: boolean } = {}

local function hasItems(snap: InventorySnapshot.Snapshot): boolean
	return next(snap.slots) ~= nil or snap.bag ~= nil or snap.armor ~= nil
end

-- Fecha a janela como "não": a caixa destranca para qualquer um, as peças
-- somem e conta a morte de verdade. Só se `state` ainda é a janela aberta.
local function closeDecline(player: Player, state: State)
	if pendings[player] ~= state then
		return
	end
	pendings[player] = nil
	local model = CrateService.lastPlayerCrate(player)
	if model then
		CrateService.setLocked(model, false)
	end
	DeathService.finalize(player)
	if player.Parent == Players then
		Net.ReviveClosed.Fire(player, { Revived = false })
	end
end

-- Pagamento confirmado depois que a janela fechou (ou revive que falhou
-- depois de cobrado): 1 revive guardado no perfil. Nunca se paga sem receber.
function ReviveService.lateRevive(player: Player)
	local ok, problem = ShopService.give(player, { kind = "reviveCredit", count = 1 } :: any, "revive_late")
	if not ok then
		warn(`[ReviveService] revive guardado de {player.Name} falhou: {problem}`)
	end
end

-- Cobra a oferta. Devolve como pagou, ou nil se não deu.
local function pay(player: Player, offer: ReviveRules.Offer): Paid?
	if offer.credit then
		return if ShopService.useReviveCredit(player) then "credit" :: Paid else nil
	end
	if offer.free then
		vipFreeUsed[player] = true
		return "vip" :: Paid
	end
	local charged =
		ShopService.charge(player, { currency = "robux", amount = offer.robux } :: any, `revive_{offer.step}`)
	return if charged then "robux" :: Paid else nil
end

-- Desfaz a cobrança de um revive que não aconteceu.
local function refund(player: Player, paid: string)
	if paid == "vip" then
		vipFreeUsed[player] = nil
	else
		ReviveService.lateRevive(player)
	end
end

-- Vida e barras cheias (como o nascimento e a pedra da ressurreição).
local function fillBars(player: Player)
	player:SetAttribute(StatNames.Health, StatNames.HealthMax)
	for _, bar in { StatNames.Hunger, StatNames.Cold, StatNames.Thirst, StatNames.Oxygen } do
		player:SetAttribute(bar, StatNames.StatusMax)
	end
	player:SetAttribute(StatNames.Heat, 0)
end

-- Proteção de SHIELD_SECONDS; o atributo some depois (se não mudou).
local function shield(player: Player)
	local untilAt = Workspace:GetServerTimeNow() + ReviveRules.SHIELD_SECONDS
	player:SetAttribute(StatNames.SpawnShieldUntil, untilAt)
	task.delay(ReviveRules.SHIELD_SECONDS, function()
		if player:GetAttribute(StatNames.SpawnShieldUntil) == untilAt then
			player:SetAttribute(StatNames.SpawnShieldUntil, nil)
		end
	end)
end

-- "Sim": cobra, nasce, tira a caixa e devolve os itens. Pausa no spawnAt.
local function accept(player: Player, state: State)
	local paid = pay(player, state.offer)
	if paid == nil then
		closeDecline(player, state)
		return
	end
	local born = SpawnService.spawnAt(player, SpawnService.reviveSpot(player))
	-- Outro caminho fechou a janela durante o nascimento (saiu do jogo).
	if pendings[player] ~= state then
		refund(player, paid)
		return
	end
	if not born then
		refund(player, paid)
		closeDecline(player, state)
		return
	end
	-- Daqui até o fim sem pausa: ninguém vê a caixa sumir sem os itens voltarem.
	pendings[player] = nil
	usedThisRun[player] = (usedThisRun[player] or 0) + 1
	local model = CrateService.lastPlayerCrate(player)
	if model then
		CrateService.removeModel(model)
	end
	InventoryService.restore(player, state.snapshot)
	fillBars(player)
	shield(player)
	Net.ReviveClosed.Fire(player, { Revived = true })
end

-- Gancho do DeathService: abre a janela se o morto é elegível. Sem pausa.
local function reviveHook(player: Player, _character: Model, _killer: Player?): (boolean, DeathService.ReviveOffer?)
	-- Uma janela velha ainda aberta (não deveria: sem personagem não se morre)
	-- fecha como "não" antes da nova morte.
	local old = pendings[player]
	if old then
		ReviveRules.answer(old.rules, false)
		closeDecline(player, old)
	end
	local snap = InventoryService.snapshot(player)
	local tutorial = TutorialService.pending(player) or TutorialService.isProtected(player)
	local hasProfile = DataService.data(player) ~= nil
	local items = snap ~= nil and hasItems(snap)
	if snap == nil or not ReviveRules.eligible(CreativeService.isOn(player), tutorial, hasProfile, items) then
		return false, nil
	end
	local vipFreeLeft = PerkService.forLife(player).vip and not vipFreeUsed[player]
	local offer = ReviveRules.offer(usedThisRun[player] or 0, vipFreeLeft, ShopService.reviveCredits(player))
	pendings[player] = { rules = ReviveRules.open(os.clock()), offer = offer, snapshot = snap }
	return true, { Robux = offer.robux, Free = offer.free }
end

local function onRequest(player: Player, data: { Accept: boolean })
	local state = pendings[player]
	if state == nil then
		return
	end
	-- Passou do limite e o laço ainda não viu: vale como "não".
	local wants = data.Accept == true and not ReviveRules.expired(state.rules, os.clock())
	local result = ReviveRules.answer(state.rules, wants)
	if result == "revive" then
		accept(player, state)
	elseif result == "decline" then
		closeDecline(player, state)
	end
end

-- Saiu do jogo com a janela aberta: "não" (as peças somem, conta a morte).
-- Também se o "sim" ainda está nascendo: ele vê a janela fechada e devolve.
local function onLeave(player: Player)
	local state = pendings[player]
	if state then
		ReviveRules.onLeave(state.rules)
		closeDecline(player, state)
	end
end

-- A janela de compra do Roblox abriu / fechou (fase 9): o tempo pausa.
function ReviveService.purchaseStarted(player: Player)
	local state = pendings[player]
	if state and state.rules.answer == nil then
		ReviveRules.pause(state.rules, os.clock())
	end
end

function ReviveService.purchaseEnded(player: Player)
	local state = pendings[player]
	if state then
		ReviveRules.resume(state.rules, os.clock())
	end
end

-- true enquanto o jogador tem a janela do revive aberta.
function ReviveService.isPending(player: Player): boolean
	return pendings[player] ~= nil
end

local function checkExpired()
	local now = os.clock()
	for player, state in pendings do
		if state.rules.answer == nil and ReviveRules.expired(state.rules, now) then
			ReviveRules.answer(state.rules, false)
			-- Thread própria: um erro no fechamento nunca derruba este laço.
			task.spawn(closeDecline, player, state)
		end
	end
end

function ReviveService.Init(_self)
	DeathService.setReviveHook(reviveHook)
	SpawnService.onSpawned(function(player: Player, viaMenu: boolean)
		if not viaMenu then
			return
		end
		-- Nasceu pelo menu com a janela aberta: escolheu não reviver.
		local state = pendings[player]
		if state and ReviveRules.answer(state.rules, false) ~= nil then
			closeDecline(player, state)
		end
		-- Corrida nova.
		usedThisRun[player] = nil
		vipFreeUsed[player] = nil
	end)
end

function ReviveService.Start(_self)
	Net.RequestRevive.On(onRequest)
	-- Antes do último save (o real_deaths entra no perfil); o PlayerRemoving
	-- cobre quem saiu sem perfil.
	DataService.onUnloading(onLeave)
	Players.PlayerRemoving:Connect(function(player)
		onLeave(player)
		usedThisRun[player] = nil
		vipFreeUsed[player] = nil
	end)
	task.spawn(function()
		while true do
			task.wait(TICK)
			checkExpired()
		end
	end)
end

return ReviveService
