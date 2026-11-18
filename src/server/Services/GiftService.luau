--!strict
-- Presentes: um jogador compra um item da loja para outro do mesmo servidor
-- (spec 2026-11-18-presentes-design). Regras em Shop/GiftRules.
--
-- - RequestGift: confere (GiftRules contra o perfil de quem recebe, giros
--   bloqueados dos dois lados), grava no perfil de quem paga para quem é o
--   próximo "Presente: X" (Shop.GiftPending), espera o save e abre a compra.
-- - Recibo (RobuxService.onGift, dentro do receiptAsync de quem pagou):
--   quem recebe está aqui → entrega no perfil dele (uma vez por PurchaseId,
--   Shop.GiftIds), põe na fila de presentes (Shop.GiftInbox) e espera o save
--   dele; saiu → mensagem no perfil dele (DataService.messageAsync), entregue
--   quando ele abrir o perfil. Só no fim tira o pendente de quem pagou: um erro
--   no meio deixa o recibo para depois, com o destinatário ainda guardado.
--   Sem pendente (não deveria acontecer): o item fica com quem pagou.
-- - Cancelou a compra: tira o pendente.
-- - GiftInbox: a fila inteira ao entrar e a cada mudança; RequestOpenGift
--   tira o primeiro (o pop-up do cliente abriu).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Shared = ReplicatedStorage.Shared
local GiftRules = require(Shared.Shop.GiftRules)
local Products = require(Shared.Shop.Products)
local ShopData = require(Shared.Shop.ShopData)
local Throttle = require(Shared.Shop.Throttle)
local DataService = require(script.Parent.DataService)
local RobuxService = require(script.Parent.RobuxService)
local ShopService = require(script.Parent.ShopService)
local Net = require(script.Parent.Parent.Net)

local REQUEST_COOLDOWN = 0.3

local GiftService = {}

local throttle = Throttle.new(REQUEST_COOLDOWN)

local function shopOf(player: Player): ShopData.ShopData?
	local data = DataService.data(player)
	return if data then data.Shop :: ShopData.ShopData else nil
end

local function fail(player: Player, productId: string, reason: string)
	Net.GiftResult.Fire(player, { ProductId = productId, Ok = false, Reason = reason })
end

-- Manda a fila de presentes não abertos.
local function sendInbox(player: Player)
	local d = shopOf(player)
	if d == nil or player.Parent ~= Players then
		return
	end
	local gifts = {}
	for _, entry in d.GiftInbox do
		table.insert(gifts, { From = entry.from, ProductId = entry.productId })
	end
	Net.GiftInbox.Fire(player, { Gifts = gifts })
end

-- Entrega o presente no perfil de quem recebe e põe na fila dele. false se
-- este PurchaseId já foi entregue (recibo repetido).
local function receive(
	recipient: Player,
	d: ShopData.ShopData,
	productId: string,
	from: string,
	purchaseId: string
): boolean
	if not ShopData.rememberGift(d, purchaseId) then
		return false
	end
	-- Já tinha o item de uma vez: ganhou Golden Ember no lugar, e é isso que a
	-- caixa mostra ("ember:<quantidade>").
	local product = Products.get(productId)
	local shown = productId
	if product ~= nil and product.once and GiftRules.alreadyHas(product, d) then
		shown = `ember:{GiftRules.emberFallback(product.price.amount)}`
	end
	ShopService.deliverTo(recipient, productId, `gift:{purchaseId}`)
	ShopData.pushInbox(d, from, shown)
	sendInbox(recipient)
	return true
end

local function onRequest(player: Player, request: { ProductId: string, RecipientUserId: number })
	local productId = request.ProductId
	if not Throttle.allow(throttle, player, "gift", os.clock()) then
		return
	end
	local payerShop = shopOf(player)
	if payerShop == nil then
		fail(player, productId, "error")
		return
	end
	local recipient = Players:GetPlayerByUserId(request.RecipientUserId)
	local recipientShop = if recipient then shopOf(recipient) else nil
	if recipient == nil or recipientShop == nil then
		fail(player, productId, "gone")
		return
	end
	local refusal = GiftRules.check(
		Products.get(productId),
		recipientShop,
		os.time(),
		ShopService.randomBlocked(player),
		ShopService.randomBlocked(recipient),
		recipient == player
	)
	if refusal ~= nil then
		fail(player, productId, refusal)
		return
	end
	ShopData.setGiftPending(payerShop, productId, recipient.UserId, recipient.DisplayName)
	-- O destinatário precisa estar salvo antes de alguém pagar.
	if not DataService.saveAsync(player) then
		fail(player, productId, "error")
		return
	end
	if not RobuxService.promptGift(player, productId) then
		ShopData.takeGiftPending(payerShop, productId)
		fail(player, productId, "error")
	end
end

-- Recibo pago de um "Presente: X" (pode pausar; um erro deixa o recibo para depois).
local function onGift(payer: Player, productId: string, purchaseId: string)
	local payerShop = shopOf(payer)
	assert(payerShop ~= nil, "presente sem o perfil de quem pagou")
	local pending = payerShop.GiftPending[productId]
	if pending == nil then
		warn(`[GiftService] presente {productId} de {payer.Name} sem destinatário: fica com quem pagou`)
		ShopService.deliverTo(payer, productId, `gift_self:{purchaseId}`)
		Net.GiftResult.Fire(payer, { ProductId = productId, Ok = true, To = payer.DisplayName })
		return
	end
	local recipient = Players:GetPlayerByUserId(pending.to)
	local recipientShop = if recipient then shopOf(recipient) else nil
	if recipient ~= nil and recipientShop ~= nil then
		receive(recipient, recipientShop, productId, payer.DisplayName, purchaseId)
		assert(DataService.saveAsync(recipient), "o perfil de quem recebe não salvou")
	else
		local sent = DataService.messageAsync(pending.to, {
			kind = "gift",
			productId = productId,
			from = payer.DisplayName,
			purchaseId = purchaseId,
		})
		assert(sent, "a mensagem do presente não foi")
	end
	ShopData.takeGiftPending(payerShop, productId)
	Net.GiftResult.Fire(payer, { ProductId = productId, Ok = true, To = pending.name })
end

local function onCancelled(payer: Player, productId: string)
	local payerShop = shopOf(payer)
	if payerShop ~= nil and ShopData.takeGiftPending(payerShop, productId) ~= nil then
		DataService.save(payer)
	end
	fail(payer, productId, "cancelled")
end

-- Presente que chegou por mensagem (quem recebe estava fora ou em outro servidor).
local function onMessage(player: Player, message: { [string]: any }): boolean
	if message.kind ~= "gift" then
		return false
	end
	local d = shopOf(player)
	if d == nil then
		return false
	end
	if receive(player, d, tostring(message.productId), tostring(message.from), tostring(message.purchaseId)) then
		DataService.save(player)
	end
	return true
end

local function onOpen(player: Player, request: { ProductId: string })
	if not Throttle.allow(throttle, player, "giftOpen", os.clock()) then
		return
	end
	local d = shopOf(player)
	local first = if d then d.GiftInbox[1] else nil
	if d == nil or first == nil or first.productId ~= request.ProductId then
		return
	end
	ShopData.popInbox(d)
	DataService.save(player)
	sendInbox(player)
end

-- SÓ Studio: ServerStorage.DevGift:Invoke(player, productId, deQuem) simula
-- um presente recebido (entrega, fila e a caixa no menu), sem compra.
local function devGift()
	if not RunService:IsStudio() then
		return
	end
	local fn = Instance.new("BindableFunction")
	fn.Name = "DevGift"
	fn.OnInvoke = function(player: Player, productId: string, from: string?): boolean
		local d = shopOf(player)
		if d == nil or Products.get(productId) == nil then
			return false
		end
		receive(player, d, productId, from or "Studio", `dev:{os.clock()}`)
		DataService.save(player)
		return true
	end
	fn.Parent = ServerStorage
end

function GiftService.Start(_self)
	devGift()
	RobuxService.onGift(onGift)
	RobuxService.onGiftCancelled(onCancelled)
	DataService.onMessage(onMessage)
	DataService.onLoaded(function(player: Player, _data)
		sendInbox(player)
	end)
	Net.RequestGift.On(onRequest)
	Net.RequestOpenGift.On(onOpen)
	Players.PlayerRemoving:Connect(function(player)
		Throttle.forget(throttle, player)
	end)
end

return GiftService
