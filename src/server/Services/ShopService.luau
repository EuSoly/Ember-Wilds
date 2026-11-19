--!strict
-- Loja de verdade no servidor: compra de produtos (Shop/Products), giro da
-- roleta e kits (saldo de 1 vida, para sempre, ativo). Tudo o que vem do
-- cliente é só o pedido; preço, conteúdo, sorteio e saldo são daqui.
--
-- Robux é cobrado de verdade (desde 18/11/2026) pelo RobuxService: a compra
-- com Robux só abre a janela do Roblox; a entrega vem depois (recibo pago,
-- gamepass comprada, assinatura ativa) por deliver / passOwned / subscription.
-- Golden Ember continua sendo cobrada aqui (charge).
--
-- O estado vai para o cliente na pasta Player.Shop (StatNames.ShopFolder):
-- atributos com os saldos de giros, o kit ativo e as vantagens (PerkService),
-- e subpastas com um objeto
-- por kit possuído, saldo de kit, produto "once" comprado e passe.
local Players = game:GetService("Players")
local PolicyService = game:GetService("PolicyService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage.Shared
local StatNames = require(Shared.StatNames)
local Defs = require(Shared.Defs)
local GiftRules = require(Shared.Shop.GiftRules)
local Products = require(Shared.Shop.Products)
local Rewards = require(Shared.Shop.Rewards)
local PurchaseRules = require(Shared.Shop.PurchaseRules)
local ShopData = require(Shared.Shop.ShopData)
local ShopTypes = require(Shared.Shop.Types)
local Throttle = require(Shared.Shop.Throttle)
local SpinRoll = require(Shared.Shop.SpinRoll)
local CheckInRules = require(Shared.Shop.CheckInRules)
local RankRules = require(Shared.Data.RankRules)
local CosmeticService = require(script.Parent.CosmeticService)
local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local PerkService = require(script.Parent.PerkService)
local RobuxService = require(script.Parent.RobuxService)
local Net = require(script.Parent.Parent.Net)

type Reward = ShopTypes.Reward
type Price = ShopTypes.Price

-- Intervalo mínimo entre pedidos do mesmo tipo do mesmo jogador (clique
-- duplo, rajada). Por tipo: comprar "+1" e girar logo depois não se atrapalham.
local REQUEST_COOLDOWN = 0.3

local ShopService = {}

local throttle = Throttle.new(REQUEST_COOLDOWN)
local rng = Random.new()

-- Item aleatório pago proibido por jogador (PolicyService). Sem resposta ainda
-- (ou consulta falhou) = bloqueado: o lado seguro. true/false só vem da consulta.
local randomBlocked: { [Player]: boolean } = {}
-- Abriu a janela da assinatura do VIP: a próxima ativação avisa "Comprado!".
local vipPrompted: { [Player]: boolean } = {}

-- Giros comprados (e pacotes com giros) estão bloqueados para o jogador?
function ShopService.randomBlocked(player: Player): boolean
	return randomBlocked[player] ~= false
end

local function shopOf(player: Player): ShopData.ShopData?
	local data = DataService.data(player)
	return if data then data.Shop :: ShopData.ShopData else nil
end

-- ===== Publicação para o cliente (pasta Player.Shop) =====

local function folderIn(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

-- Deixa a pasta com um BoolValue por chave verdadeira de `set`.
local function syncFlags(folder: Folder, set: { [string]: boolean })
	for _, child in folder:GetChildren() do
		if set[child.Name] ~= true then
			child:Destroy()
		end
	end
	for id, on in set do
		if on == true and folder:FindFirstChild(id) == nil then
			local flag = Instance.new("BoolValue")
			flag.Name = id
			flag.Value = true
			flag.Parent = folder
		end
	end
end

-- Deixa a pasta com um IntValue por chave de `counts` (> 0).
local function syncCounts(folder: Folder, counts: { [string]: number })
	for _, child in folder:GetChildren() do
		if (counts[child.Name] or 0) <= 0 then
			child:Destroy()
		end
	end
	for id, count in counts do
		if count > 0 then
			local value = folder:FindFirstChild(id)
			if value == nil or not value:IsA("IntValue") then
				local created = Instance.new("IntValue")
				created.Name = id
				created.Parent = folder
				value = created
			end
			(value :: IntValue).Value = count
		end
	end
end

local function fill(player: Player, root: Folder, d: ShopData.ShopData)
	-- Vantagens (Perk_*, VipUntil, XpBoost*): escritas pelo PerkService.
	PerkService.writeAttributes(player, root)
	root:SetAttribute(StatNames.SpinsNormal, d.Spins.normal)
	root:SetAttribute(StatNames.SpinsPaid, d.Spins.paid)
	root:SetAttribute(StatNames.KitActive, d.KitActive)
	-- Check-in: o servidor decide se há prêmio hoje (dia de Brasília); o cliente só lê.
	root:SetAttribute(StatNames.PaidRandomBlocked, ShopService.randomBlocked(player))
	root:SetAttribute(StatNames.CheckInDay, d.CheckIn.Day)
	root:SetAttribute(StatNames.CheckInReady, CheckInRules.canClaim(d.CheckIn, RankRules.dayIndex(os.time())))
	syncFlags(folderIn(root, StatNames.KitsOwnedFolder), d.KitsOwned)
	syncCounts(folderIn(root, StatNames.KitBalanceFolder), d.KitBalance)
	syncFlags(folderIn(root, StatNames.PurchasedFolder), d.Purchased)
	syncFlags(folderIn(root, StatNames.PassesFolder), d.Passes)
end

-- Publica o estado da loja. A pasta nova é preenchida antes de ir para o
-- Player, para chegar ao cliente de uma vez.
local function publish(player: Player)
	local d = shopOf(player)
	if d == nil then
		return
	end
	local existing = player:FindFirstChild(StatNames.ShopFolder)
	if existing and existing:IsA("Folder") then
		fill(player, existing, d)
		return
	end
	local root = Instance.new("Folder")
	root.Name = StatNames.ShopFolder
	fill(player, root, d)
	root.Parent = player
end

-- Republica o estado da loja (CheckInService, na virada do dia).
function ShopService.republish(player: Player)
	publish(player)
end

-- ===== Cobrança e entrega =====

-- Cobra um preço em Golden Ember. Robux não passa por aqui: é a janela do
-- Roblox (RobuxService.prompt / awaitProduct) e a entrega vem pelo recibo.
function ShopService.charge(player: Player, price: Price, reason: string): boolean
	if price.currency == "robux" then
		return false
	end
	return CurrencyService.spend(player, price.amount, reason)
end

-- Revives guardados no perfil (ShopData.ReviveCredits); 0 sem perfil.
function ShopService.reviveCredits(player: Player): number
	local d = shopOf(player)
	return if d then d.ReviveCredits else 0
end

-- Gasta 1 revive guardado (ReviveService) e salva. false se não há.
function ShopService.useReviveCredit(player: Player): boolean
	local d = shopOf(player)
	if d == nil or not (d.ReviveCredits >= 1) then
		return false
	end
	d.ReviveCredits -= 1
	DataService.save(player)
	return true
end

-- Como cada tipo de recompensa é entregue (tipo novo = uma entrada aqui, além
-- do validate em Shop/Rewards e do card em Menu/Shop/RewardView).
local GRANTS: { [string]: (player: Player, d: ShopData.ShopData, reward: Reward, reason: string) -> () } = {
	cosmetic = function(player, _d, reward, _reason)
		local id = reward.id :: string
		if not CosmeticService.owns(player, id) then
			CosmeticService.grantOwnership(player, id)
		end
	end,
	ember = function(player, _d, reward, reason)
		CurrencyService.grant(player, reward.amount :: number, reason)
	end,
	spins = function(_player, d, reward, _reason)
		ShopData.addSpins(d, reward.spin :: ShopTypes.SpinKind, reward.count :: number)
	end,
	kit = function(_player, d, reward, _reason)
		ShopData.ownKit(d, reward.id :: string)
	end,
	kitOnce = function(_player, d, reward, _reason)
		ShopData.addKitBalance(d, reward.id :: string, reward.count :: number)
	end,
	pass = function(player, d, reward, _reason)
		ShopData.setPass(d, reward.id :: string)
		PerkService.refresh(player)
	end,
	-- VIP por tempo: com a vida ativa, os +3 espaços entram na hora (PerkService).
	vip = function(player, d, reward, _reason)
		ShopData.addVipDays(d, reward.count :: number, os.time())
		PerkService.refresh(player)
	end,
	xpBoost = function(player, d, reward, _reason)
		ShopData.addBoost(d, reward.count :: number, os.time())
		PerkService.refresh(player)
	end,
	reviveCredit = function(_player, d, reward, _reason)
		d.ReviveCredits += reward.count :: number
	end,
}

-- Entrega uma recompensa (também usada por códigos de resgate no futuro).
function ShopService.grant(player: Player, reward: Reward, reason: string): boolean
	local d = shopOf(player)
	local handler = GRANTS[reward.kind]
	if d == nil or handler == nil then
		return false
	end
	handler(player, d, reward, reason)
	return true
end

-- Dá uma recompensa fora da compra (presente, código de resgate, Studio):
-- valida, entrega, publica e salva. Devolve (false, mensagem) se inválida.
function ShopService.give(player: Player, reward: Reward, reason: string): (boolean, string?)
	local problem = Rewards.validate(reward, Defs)
	if problem ~= nil then
		return false, problem
	end
	if not ShopService.grant(player, reward, reason) then
		return false, "sem perfil"
	end
	publish(player)
	DataService.save(player)
	return true, nil
end

-- Dá vários prêmios de uma vez (código de resgate): valida todos antes, entrega,
-- publica e salva uma vez. (false, mensagem) se algum é inválido (nada entra).
function ShopService.giveAll(player: Player, rewards: { Reward }, reason: string): (boolean, string?)
	for _, reward in rewards do
		local problem = Rewards.validate(reward, Defs)
		if problem ~= nil then
			return false, problem
		end
	end
	if shopOf(player) == nil then
		return false, "sem perfil"
	end
	for _, reward in rewards do
		ShopService.grant(player, reward, reason)
	end
	publish(player)
	DataService.save(player)
	return true, nil
end

-- Tira um kit ou passe para sempre (a posse no perfil é a verdade), ou o VIP
-- ("vip", id ignorado: acaba agora). O kit ativo, se for o tirado, desativa.
-- O que a vida atual já tinha (PerkService.forLife) vale até a próxima vida.
function ShopService.revoke(player: Player, kind: "kit" | "pass" | "vip", id: string): boolean
	local d = shopOf(player)
	if d == nil then
		return false
	end
	if kind == "kit" then
		d.KitsOwned[id] = nil
		if d.KitActive == id then
			d.KitActive = ""
		end
	elseif kind == "vip" then
		d.VipUntil = 0
	else
		d.Passes[id] = nil
	end
	publish(player)
	PerkService.refresh(player)
	DataService.save(player)
	return true
end

-- Compra um produto. Devolve (true) ou (false, motivo de PurchaseRules ou "error").
function ShopService.purchase(player: Player, productId: string): (boolean, string?)
	local d = shopOf(player)
	if d == nil then
		return false, "error"
	end
	local product = Products.get(productId)
	local refusal =
		PurchaseRules.check(product, d, os.time(), CurrencyService.balance(player), ShopService.randomBlocked(player))
	if refusal ~= nil or product == nil then
		return false, refusal or "unknown"
	end
	for _, reward in product.rewards do
		if GRANTS[reward.kind] == nil then
			return false, "error" -- tipo sem entrega no servidor: não cobra nada
		end
	end
	-- Robux: abre a janela do Roblox; a entrega vem pelo recibo (deliver).
	if product.price.currency == "robux" then
		if not RobuxService.prompt(player, product.id) then
			return false, "error"
		end
		if product.kind == "vip" then
			vipPrompted[player] = true
		end
		return false, "prompt"
	end
	local reason = `shop:{product.id}`
	if not ShopService.charge(player, product.price, reason) then
		return false, "balance"
	end
	for _, reward in product.rewards do
		ShopService.grant(player, reward, reason)
	end
	if product.once then
		ShopData.markPurchased(d, product.id)
	end
	publish(player)
	DataService.save(player)
	return true, nil
end

-- Entrega o produto `productId` pago com Robux no perfil de `player` (quem
-- comprou ou quem ganhou de presente). Sem pausa e sem aviso; quem chama salva.
-- Revive vira 1 revive guardado. Item de uma vez que `player` já tem vira
-- Golden Ember no valor do preço (GiftRules.emberFallback). false sem perfil.
function ShopService.deliverTo(player: Player, productId: string, reason: string): boolean
	local d = shopOf(player)
	local product = Products.get(productId)
	if d == nil or product == nil then
		return false
	end
	if product.kind == "revive" then
		ShopService.grant(player, { kind = "reviveCredit", count = 1 } :: any, reason)
	elseif product.once and GiftRules.alreadyHas(product, d) then
		CurrencyService.grant(player, GiftRules.emberFallback(product.price.amount), reason)
	else
		for _, reward in product.rewards do
			ShopService.grant(player, reward, reason)
		end
	end
	if product.once then
		ShopData.markPurchased(d, product.id)
	end
	publish(player)
	return true
end

-- Recibo de compra própria (RobuxService, dentro do DataService.receiptAsync,
-- que salva).
local function deliver(player: Player, productId: string)
	assert(ShopService.deliverTo(player, productId, `robux:{productId}`), `entrega sem perfil: {productId}`)
	local product = Products.get(productId)
	if product and product.kind ~= "revive" then
		Net.PurchaseResult.Fire(player, { ProductId = productId, Ok = true })
	end
end

-- Gamepass possuída: entrega o que ainda não está no perfil e salva.
local function passOwned(player: Player, productId: string, boughtNow: boolean)
	local d = shopOf(player)
	local product = Products.get(productId)
	if d == nil or product == nil then
		return
	end
	local fresh = false
	for _, reward in product.rewards do
		local has = if reward.kind == "kit"
			then d.KitsOwned[reward.id :: string] == true
			elseif reward.kind == "pass" then d.Passes[reward.id :: string] == true
			else false
		if not has then
			ShopService.grant(player, reward, `gamepass:{productId}`)
			fresh = true
		end
	end
	if product.once then
		ShopData.markPurchased(d, product.id)
	end
	if fresh then
		publish(player)
		DataService.save(player)
	end
	if boughtNow then
		Net.PurchaseResult.Fire(player, { ProductId = productId, Ok = true })
	end
end

-- Status da assinatura do VIP: o fim do período pago vira o VipUntil (o
-- resto do jogo lê só ele). Sem assinatura, o VipUntil fica como está e
-- vence sozinho.
local function subscription(player: Player, productId: string, untilUnix: number?)
	local d = shopOf(player)
	if d == nil or untilUnix == nil then
		return
	end
	local was = d.VipUntil
	if untilUnix > was then
		d.VipUntil = untilUnix
		publish(player)
		PerkService.refresh(player)
		DataService.save(player)
	end
	if vipPrompted[player] and was <= os.time() then
		vipPrompted[player] = nil
		Net.PurchaseResult.Fire(player, { ProductId = productId, Ok = true })
	end
end

-- Gira a roleta `typeId` gastando um giro do saldo `kind`. nil = não girou
-- (sem giro, roleta sem skins ou tipo inexistente): nada é gasto.
function ShopService.spin(player: Player, typeId: string, kind: ShopTypes.SpinKind): SpinRoll.Roll?
	local d = shopOf(player)
	if d == nil or (d.Spins[kind] or 0) < 1 then
		return nil
	end
	local roll = SpinRoll.roll(typeId, kind, function(id: string): boolean
		return CosmeticService.owns(player, id)
	end, rng:NextNumber(), rng:NextNumber())
	if roll == nil or not ShopData.useSpin(d, kind) then
		return nil
	end
	if roll.duplicate then
		CurrencyService.grant(player, roll.refund, `spin_duplicate:{roll.itemId}`)
	else
		CosmeticService.grantOwnership(player, roll.itemId)
	end
	publish(player)
	DataService.save(player)
	return roll
end

-- Estado dos kits para o nascimento (KitChoice). nil sem perfil.
function ShopService.kitState(
	player: Player
): { balance: { [string]: number }, owned: { [string]: boolean }, active: string? }?
	local d = shopOf(player)
	if d == nil then
		return nil
	end
	return {
		balance = d.KitBalance,
		owned = d.KitsOwned,
		active = if d.KitActive ~= "" then d.KitActive else nil,
	}
end

-- Gasta 1 do saldo de 1 vida do kit (ao nascer com ele). false sem saldo.
function ShopService.useKitBalance(player: Player, kitId: string): boolean
	local d = shopOf(player)
	if d == nil or not ShopData.useKitBalance(d, kitId) then
		return false
	end
	publish(player)
	DataService.save(player)
	return true
end

-- SÓ Studio (DevShopReset): zera a loja do perfil e republica.
function ShopService.resetForDev(player: Player): boolean
	local data = DataService.data(player)
	if not RunService:IsStudio() or data == nil then
		return false
	end
	data.Shop = ShopData.empty()
	publish(player)
	PerkService.refresh(player)
	DataService.save(player)
	return true
end

-- ===== Pedidos do cliente =====

local function onPurchase(player: Player, request: { ProductId: string })
	if not Throttle.allow(throttle, player, "purchase", os.clock()) then
		return
	end
	local ok, reason = ShopService.purchase(player, request.ProductId)
	Net.PurchaseResult.Fire(player, { ProductId = request.ProductId, Ok = ok, Reason = reason })
end

local function onSpin(player: Player, request: { TypeId: string, Paid: boolean })
	if not Throttle.allow(throttle, player, "spin", os.clock()) then
		-- Responde mesmo descartando: a tela do giro espera a resposta para destravar.
		Net.SpinResult.Fire(
			player,
			{ TypeId = request.TypeId, Paid = request.Paid, Ok = false, Duplicate = false, Refund = 0 }
		)
		return
	end
	local kind: ShopTypes.SpinKind = if request.Paid then "paid" else "normal"
	local roll = ShopService.spin(player, request.TypeId, kind)
	Net.SpinResult.Fire(player, {
		TypeId = request.TypeId,
		Paid = request.Paid,
		Ok = roll ~= nil,
		ItemId = if roll then roll.itemId else nil,
		Duplicate = if roll then roll.duplicate else false,
		Refund = if roll then roll.refund else 0,
	})
end

local function onSetActive(player: Player, request: { KitId: string? })
	if not Throttle.allow(throttle, player, "kit", os.clock()) then
		return
	end
	local d = shopOf(player)
	if d ~= nil and ShopData.setActive(d, request.KitId) then
		publish(player)
		DataService.save(player)
	end
end

function ShopService.Start(_self)
	DataService.onLoaded(function(player: Player, data: { [string]: any })
		local d = data.Shop :: ShopData.ShopData
		-- Posse no perfil é a verdade; só limpa marcas false (ShopData.clean).
		ShopData.clean(d)
		-- Os três produtos mantiveram os IDs comerciais quando suas skins mudaram.
		-- Complete a coleção de quem já comprou ou recebeu a edição anterior.
		local restored = false
		for _, id in { "bundle_mar", "bundle_floresta", "bundle_gelo" } do
			local product = if d.Purchased[id] then Products.get(id) else nil
			if product then
				for _, reward in product.rewards do
					local skin = reward.id
					if reward.kind == "cosmetic" and skin and not CosmeticService.owns(player, skin) then
						if CosmeticService.grantOwnership(player, skin) then
							restored = true
						end
					end
				end
			end
		end
		if restored then
			DataService.save(player)
		end
		publish(player)
		-- Consulta a política em segundo plano (não trava o carregamento). Até a
		-- resposta, e se ela falhar, o jogador fica restrito.
		task.spawn(function()
			local ok, info = pcall(function()
				return PolicyService:GetPolicyInfoForPlayerAsync(player)
			end)
			if not player.Parent then
				return
			end
			randomBlocked[player] = not (ok and type(info) == "table" and info.ArePaidRandomItemsRestricted == false)
			publish(player)
		end)
	end)
	RobuxService.onDeliver(deliver)
	RobuxService.onPassOwned(passOwned)
	RobuxService.onSubscription(subscription)
	Net.RequestPurchase.On(onPurchase)
	Net.RequestSpin.On(onSpin)
	Net.SetActiveKit.On(onSetActive)
	Players.PlayerRemoving:Connect(function(player)
		Throttle.forget(throttle, player)
		randomBlocked[player] = nil
		vipPrompted[player] = nil
	end)
end

return ShopService
