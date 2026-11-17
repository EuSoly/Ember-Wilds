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
--   - sim (protegido por pcall: um erro vira "não" e devolve o cobrado): cobra
--     (grátis do VIP, revive guardado ou Robux pelo degrau; `state.paid`
--     guarda o que foi cobrado até a entrega) → nasce no totem do time ou na
--     floresta (SpawnService.spawnAt) → tira a caixa do mundo → devolve a foto
--     (InventoryService.restore) → vida e barras cheias → SHIELD_SECONDS de
--     proteção (SpawnShieldUntil no modelo do personagem) → ReviveClosed
--     { Revived = true }. A caixa só some DEPOIS de nascer, e só se ainda está
--     trancada: senão conta como "não". Os itens nunca duplicam: a caixa
--     trancada não é aberta por ninguém e some antes de a foto voltar.
--   - não, o tempo acabou, o teto duro (HARD_CAP, vale também para a janela
--     aceita que não terminou), saiu do jogo ou nasceu pelo menu: destranca a
--     caixa, devolve o que foi cobrado e não entregue (grátis do VIP volta;
--     senão 1 revive guardado; na saída, ainda com o perfil carregado),
--     DeathService.finalize (peças somem, real_deaths) e ReviveClosed
--     { Revived = false }. Quem fecha a janela é quem devolve (uma vez só).
-- - Corrida: da entrada pelo menu até a morte final. A contagem de revives
--   (grátis inclusos, para o degrau) e o grátis do VIP usado zeram no
--   nascimento pelo menu (SpawnService.onSpawned com viaMenu), não no revive.
-- - Compra do Roblox (fase 9): purchaseStarted/purchaseEnded pausam a janela,
--   aceita ou não (até PURCHASE_PAUSE_MAX); purchaseEnded(player, false) =
--   compra cancelada: a janela aceita, sem nada cobrado, volta para sem
--   resposta (o jogador escolhe de novo). Pagamento confirmado com a janela já
--   fechada = lateRevive (1 revive guardado no perfil). Nesta branch a
--   cobrança é instantânea e ninguém chama esses três.
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
	-- Cobrado e ainda não entregue (nil = nada a devolver). Quem fechar a
	-- janela como "não" devolve isto e zera; a entrega também zera.
	paid: Paid?,
	-- Conta os "sim" desta janela (uma compra cancelada reabre a resposta):
	-- só a tentativa mais nova segue depois da cobrança.
	attempt: number,
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

-- Pagamento confirmado depois que a janela fechou (ou revive que falhou
-- depois de cobrado): 1 revive guardado no perfil. Nunca se paga sem receber.
function ReviveService.lateRevive(player: Player)
	local ok, problem = ShopService.give(player, { kind = "reviveCredit", count = 1 } :: any, "revive_late")
	if not ok then
		warn(`[ReviveService] revive guardado de {player.Name} falhou: {problem}`)
	end
end

-- Desfaz a cobrança de um revive que não aconteceu.
local function refund(player: Player, paid: Paid)
	if paid == "vip" then
		vipFreeUsed[player] = nil
	else
		ReviveService.lateRevive(player)
	end
end

-- Fecha a janela como "não": a caixa destranca para qualquer um, o que foi
-- cobrado e não entregue volta, as peças somem e conta a morte de verdade. Só
-- se `state` ainda é a janela aberta (quem fecha devolve, uma vez só).
local function closeDecline(player: Player, state: State)
	if pendings[player] ~= state then
		return
	end
	pendings[player] = nil
	ReviveRules.answer(state.rules, false)
	local model = CrateService.lastPlayerCrate(player)
	if model then
		CrateService.setLocked(model, false)
	end
	local paid: Paid? = state.paid
	state.paid = nil
	if paid ~= nil then
		refund(player, paid)
	end
	DeathService.finalize(player)
	if player.Parent == Players then
		Net.ReviveClosed.Fire(player, { Revived = false })
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

-- Vida e barras cheias (como o nascimento e a pedra da ressurreição).
local function fillBars(player: Player)
	player:SetAttribute(StatNames.Health, StatNames.HealthMax)
	for _, bar in { StatNames.Hunger, StatNames.Cold, StatNames.Thirst, StatNames.Oxygen } do
		player:SetAttribute(bar, StatNames.StatusMax)
	end
	player:SetAttribute(StatNames.Heat, 0)
end

-- Proteção de SHIELD_SECONDS no modelo do personagem (não no Player); o
-- atributo some depois (se não mudou) ou junto com o corpo.
local function shield(player: Player)
	local character = player.Character
	if character == nil then
		return
	end
	local untilAt = Workspace:GetServerTimeNow() + ReviveRules.SHIELD_SECONDS
	character:SetAttribute(StatNames.SpawnShieldUntil, untilAt)
	task.delay(ReviveRules.SHIELD_SECONDS, function()
		if character:GetAttribute(StatNames.SpawnShieldUntil) == untilAt then
			character:SetAttribute(StatNames.SpawnShieldUntil, nil)
		end
	end)
end

-- "Sim": cobra, nasce, tira a caixa e devolve os itens. Pausa na cobrança
-- (fase 9) e no spawnAt; depois de cada pausa confere se a janela segue sua.
local function accept(player: Player, state: State)
	state.attempt += 1
	local attempt = state.attempt
	-- A caixa trancada desta morte (nil = a morte não deixou caixa).
	local crate = CrateService.lastPlayerCrate(player)
	local paid: Paid? = pay(player, state.offer)
	-- Fechou durante a cobrança, ou a compra foi cancelada e outro "sim"
	-- começou: esta tentativa não vale (devolve o que ela cobrou).
	if pendings[player] ~= state or state.attempt ~= attempt then
		if paid ~= nil then
			refund(player, paid)
		end
		return
	end
	if paid == nil then
		-- Compra cancelada (purchaseEnded com false): a janela já voltou para
		-- sem resposta e espera a nova escolha.
		if state.rules.answer == nil then
			return
		end
		closeDecline(player, state)
		return
	end
	state.paid = paid
	local born = SpawnService.spawnAt(player, SpawnService.reviveSpot(player))
	-- Outro caminho fechou a janela durante o nascimento (saiu, teto, menu):
	-- quem fechou já devolveu `state.paid`.
	if pendings[player] ~= state then
		return
	end
	-- Não nasceu, passou do teto (o laço ainda não viu) ou a caixa já não está
	-- trancada (alguém pode ter mexido): "não", e o cobrado volta.
	if
		not born
		or ReviveRules.capped(state.rules, os.clock())
		or (crate ~= nil and not CrateService.isLocked(crate))
	then
		closeDecline(player, state)
		return
	end
	-- Daqui até o fim sem pausa: ninguém vê a caixa sumir sem os itens voltarem.
	pendings[player] = nil
	state.paid = nil
	usedThisRun[player] = (usedThisRun[player] or 0) + 1
	if crate then
		CrateService.removeModel(crate)
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
	pendings[player] = { rules = ReviveRules.open(os.clock()), offer = offer, snapshot = snap, paid = nil, attempt = 0 }
	return true, { Robux = offer.robux, Free = offer.free }
end

local function onRequest(player: Player, data: { Accept: boolean })
	local state = pendings[player]
	if state == nil then
		return
	end
	-- Passou do limite e o laço ainda não viu: vale como "não".
	local wants = data.Accept == true and not ReviveRules.timedOut(state.rules, os.clock())
	local result = ReviveRules.answer(state.rules, wants)
	if result == "revive" then
		-- Protegido: um erro no meio fecha como "não" e devolve o que foi
		-- cobrado (os itens seguem na caixa, que destranca).
		local ok, err = pcall(accept :: any, player, state)
		if not ok then
			warn(`[ReviveService] revive de {player.Name} falhou: {err}`)
			closeDecline(player, state)
		end
	elseif result == "decline" then
		closeDecline(player, state)
	end
end

-- Saiu do jogo com a janela aberta: "não" (as peças somem, conta a morte).
-- Roda no DataService.onUnloading, com o perfil ainda carregado: o que foi
-- cobrado e não entregue (o "sim" ainda nascendo) volta aqui, e o accept, ao
-- ver a janela fechada, não devolve de novo.
local function onLeave(player: Player)
	local state = pendings[player]
	if state then
		closeDecline(player, state)
	end
end

-- A janela de compra do Roblox abriu (fase 9): o tempo pausa, com ou sem
-- resposta (o "sim" esperando a compra também pausa).
function ReviveService.purchaseStarted(player: Player)
	local state = pendings[player]
	if state then
		ReviveRules.pause(state.rules, os.clock())
	end
end

-- A janela de compra fechou (fase 9). `paid == false` = cancelada: a janela
-- aceita, sem nada cobrado, volta para sem resposta e o jogador escolhe de
-- novo (o cliente reativa os botões ao ver a compra cancelada).
function ReviveService.purchaseEnded(player: Player, paid: boolean?)
	local state = pendings[player]
	if state == nil then
		return
	end
	ReviveRules.resume(state.rules, os.clock())
	if paid == false and state.paid == nil then
		ReviveRules.reopen(state.rules)
	end
end

-- true enquanto o jogador tem a janela do revive aberta.
function ReviveService.isPending(player: Player): boolean
	return pendings[player] ~= nil
end

-- Fecha quem passou do tempo: sem resposta pelo relógio da decisão; aceita
-- (cobrando ou nascendo) pelo teto duro.
local function checkExpired()
	local now = os.clock()
	for player, state in pendings do
		if ReviveRules.timedOut(state.rules, now) then
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
		-- Nasceu pelo menu com a janela aberta (respondida ou não): escolheu não
		-- reviver. Um "sim" ainda em andamento vê a janela fechada e para.
		local state = pendings[player]
		if state then
			closeDecline(player, state)
		end
		-- Corrida nova.
		usedThisRun[player] = nil
		vipFreeUsed[player] = nil
	end)
end

function ReviveService.Start(_self)
	Net.RequestRevive.On(onRequest)
	-- Antes do último save (o real_deaths e o revive guardado entram no
	-- perfil); o PlayerRemoving cobre quem saiu sem perfil.
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
