--!strict
-- Cobrança de verdade com Robux (MarketplaceService). Ids em Shop/RobloxIds.
--
-- - prompt: abre a janela de compra do Roblox certa para o produto da loja
--   (produto de desenvolvedor, gamepass ou assinatura). Não espera.
-- - Produto de desenvolvedor: a entrega é no ProcessReceipt, pelo
--   DataService.receiptAsync (uma vez por PurchaseId, e só responde
--   PurchaseGranted depois que o perfil salvou). Quem entrega é o ShopService
--   (onDeliver). Jogador fora do servidor ou sem perfil: NotProcessedYet (o
--   Roblox manda de novo na próxima visita).
-- - awaitProduct (revive): abre a janela e PAUSA até o pagamento confirmar
--   (true) ou a janela fechar sem compra / passar do tempo (false). Recibo que
--   chega sem ninguém esperando (janela do revive já fechou, outra visita) é
--   entregue normalmente pelo onDeliver (o revive vira revive guardado).
-- - Gamepass: comprada agora (PromptGamePassPurchaseFinished) ou já possuída
--   ao entrar (UserOwnsGamePassAsync) → onPassOwned (ShopService entrega).
-- - Assinatura (VIP): ao entrar e quando o status muda → onSubscription com o
--   fim do período pago (unix) ou nil se não assina.
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Products = require(ReplicatedStorage.Shared.Shop.Products)
local RobloxIds = require(ReplicatedStorage.Shared.Shop.RobloxIds)
local DataService = require(script.Parent.DataService)
local Net = require(script.Parent.Parent.Net)

-- Janela fechada como "comprado" e o recibo não veio: desiste da espera
-- depois disto (o recibo, se vier, é entregue sem a espera).
local RECEIPT_WAIT_SECONDS = 20
-- Teto de qualquer espera do awaitProduct (janela que nunca fecha).
local AWAIT_MAX_SECONDS = 180
-- Assinatura ativa sem data de fim (pagamento da renovação pendente): vale
-- por mais isto e é conferida de novo quando o status mudar.
local SUBSCRIPTION_GRACE_SECONDS = 24 * 3600

type Waiter = { productId: string, thread: thread, done: boolean }

local RobuxService = {}

local deliverHandler: ((player: Player, productId: string) -> ())? = nil
local passHandler: ((player: Player, productId: string, boughtNow: boolean) -> ())? = nil
local subscriptionHandler: ((player: Player, productId: string, untilUnix: number?) -> ())? = nil

local waiters: { [Player]: Waiter } = {}

-- Entrega de um produto de desenvolvedor pago (sem pausa: só mexe no perfil).
function RobuxService.onDeliver(handler: (player: Player, productId: string) -> ())
	deliverHandler = handler
end

-- Gamepass possuída: comprada agora (`boughtNow`) ou de antes (ao entrar).
function RobuxService.onPassOwned(handler: (player: Player, productId: string, boughtNow: boolean) -> ())
	passHandler = handler
end

-- Status da assinatura: `untilUnix` = fim do período (nil = não assina).
function RobuxService.onSubscription(handler: (player: Player, productId: string, untilUnix: number?) -> ())
	subscriptionHandler = handler
end

-- Abre a janela de compra do Roblox para o produto da loja. false se o
-- produto não tem id no Roblox ou não se compra com Robux.
function RobuxService.prompt(player: Player, productId: string): boolean
	local product = Products.get(productId)
	if product == nil or product.price.currency ~= "robux" then
		return false
	end
	local home = RobloxIds.homeOf(product.kind)
	local ok, err = pcall(function()
		if home == "pass" then
			local id = RobloxIds.GAME_PASS[productId]
			assert(id ~= nil, "gamepass sem id")
			MarketplaceService:PromptGamePassPurchase(player, id)
		elseif home == "subscription" then
			local id = RobloxIds.SUBSCRIPTION[productId]
			assert(id ~= nil, "assinatura sem id")
			MarketplaceService:PromptSubscriptionPurchase(player, id)
		else
			local id = RobloxIds.PRODUCT[productId]
			assert(id ~= nil, "produto sem id")
			MarketplaceService:PromptProductPurchase(player, id)
		end
	end)
	if not ok then
		warn(`[RobuxService] não abriu a compra de {productId} para {player.Name}: {err}`)
	end
	return ok
end

local function finish(player: Player, waiter: Waiter, paid: boolean)
	if waiter.done then
		return
	end
	waiter.done = true
	if waiters[player] == waiter then
		waiters[player] = nil
	end
	task.spawn(waiter.thread, paid)
end

-- Abre a compra do produto e PAUSA até pagar (true) ou não (false). Uma
-- espera por jogador: uma nova encerra a anterior como não paga.
function RobuxService.awaitProduct(player: Player, productId: string): boolean
	local old = waiters[player]
	if old then
		finish(player, old, false)
	end
	local waiter: Waiter = { productId = productId, thread = coroutine.running(), done = false }
	waiters[player] = waiter
	if not RobuxService.prompt(player, productId) then
		waiter.done = true
		waiters[player] = nil
		return false
	end
	task.delay(AWAIT_MAX_SECONDS, function()
		finish(player, waiter, false)
	end)
	return coroutine.yield() == true
end

-- Recibo de produto de desenvolvedor.
local function processReceipt(receipt: { [string]: any }): Enum.ProductPurchaseDecision
	local player = Players:GetPlayerByUserId(receipt.PlayerId)
	if player == nil then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local productId = RobloxIds.fromProduct(receipt.ProductId)
	if productId == nil then
		warn(`[RobuxService] recibo de produto desconhecido {receipt.ProductId}`)
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	return DataService.receiptAsync(player, tostring(receipt.PurchaseId), function()
		local waiter = waiters[player]
		if waiter ~= nil and not waiter.done and waiter.productId == productId then
			-- Alguém espera este pagamento (revive): segue de lá.
			finish(player, waiter, true)
			return
		end
		assert(deliverHandler ~= nil, "sem entrega registrada")
		deliverHandler(player, productId)
	end)
end

-- A janela de compra de produto fechou.
local function onProductFinished(userId: number, robloxId: number, purchased: boolean)
	local player = Players:GetPlayerByUserId(userId)
	local productId = RobloxIds.fromProduct(robloxId)
	if player == nil or productId == nil then
		return
	end
	local waiter = waiters[player]
	local waiting = waiter ~= nil and not waiter.done and waiter.productId == productId
	if purchased then
		-- O recibo chega pelo ProcessReceipt; se não vier logo, a espera desiste
		-- (e o recibo atrasado é entregue sem ela).
		if waiting and waiter then
			task.delay(RECEIPT_WAIT_SECONDS, function()
				finish(player, waiter, false)
			end)
		end
		return
	end
	if waiting and waiter then
		finish(player, waiter, false)
	end
	Net.PurchaseResult.Fire(player, { ProductId = productId, Ok = false, Reason = "cancelled" })
end

local function onPassFinished(player: Player, robloxId: number, purchased: boolean)
	local productId = RobloxIds.fromGamePass(robloxId)
	if productId == nil then
		return
	end
	if purchased and passHandler then
		passHandler(player, productId, true)
	elseif not purchased then
		Net.PurchaseResult.Fire(player, { ProductId = productId, Ok = false, Reason = "cancelled" })
	end
end

-- Gamepasses que o jogador já tem (compradas no site ou em outra visita).
local function checkPasses(player: Player)
	for productId, id in RobloxIds.GAME_PASS do
		local ok, owns = pcall(function()
			return MarketplaceService:UserOwnsGamePassAsync(player.UserId, id)
		end)
		if not player.Parent then
			return
		end
		if ok and owns == true and passHandler then
			passHandler(player, productId, false)
		elseif not ok then
			warn(`[RobuxService] não conferiu a gamepass {productId} de {player.Name}: {owns}`)
		end
	end
end

local function isSubscribedState(state: any): boolean
	local name = if typeof(state) == "EnumItem" then state.Name else tostring(state)
	return string.sub(name, 1, 10) == "Subscribed"
end

-- Status da assinatura `productId` → onSubscription.
local function checkSubscription(player: Player, productId: string)
	local id = RobloxIds.SUBSCRIPTION[productId]
	if id == nil or subscriptionHandler == nil then
		return
	end
	local ok, details = pcall(function()
		return MarketplaceService:GetUserSubscriptionDetailsAsync(player, id)
	end)
	if not player.Parent then
		return
	end
	if not ok or type(details) ~= "table" then
		warn(`[RobuxService] não conferiu a assinatura de {player.Name}: {details}`)
		return
	end
	if not isSubscribedState(details.SubscriptionState) then
		subscriptionHandler(player, productId, nil)
		return
	end
	local untilUnix = 0
	for _, field in { "ExpireTime", "NextRenewTime" } do
		local time = details[field]
		if typeof(time) == "DateTime" then
			untilUnix = math.max(untilUnix, time.UnixTimestamp)
		end
	end
	if untilUnix <= os.time() then
		untilUnix = os.time() + SUBSCRIPTION_GRACE_SECONDS
	end
	subscriptionHandler(player, productId, untilUnix)
end

local function checkAllSubscriptions(player: Player)
	for productId in RobloxIds.SUBSCRIPTION do
		checkSubscription(player, productId)
	end
end

function RobuxService.Start(_self)
	MarketplaceService.ProcessReceipt = processReceipt
	MarketplaceService.PromptProductPurchaseFinished:Connect(onProductFinished)
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onPassFinished)
	Players.UserSubscriptionStatusChanged:Connect(function(player: Player, subscriptionId: string)
		local productId = RobloxIds.fromSubscription(subscriptionId)
		if productId then
			checkSubscription(player, productId)
		end
	end)
	-- Depois do perfil: as entregas precisam dele.
	DataService.onLoaded(function(player: Player, _data)
		task.spawn(checkPasses, player)
		task.spawn(checkAllSubscriptions, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		local waiter = waiters[player]
		if waiter then
			finish(player, waiter, false)
		end
	end)
end

return RobuxService
