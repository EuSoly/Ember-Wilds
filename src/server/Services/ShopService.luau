--!strict
-- Loja de verdade no servidor: compra de produtos (Shop/Products), giro da
-- roleta e kits (saldo de 1 vida, para sempre, ativo). Tudo o que vem do
-- cliente é só o pedido; preço, conteúdo, sorteio e saldo são daqui.
--
-- Robux AINDA NÃO É COBRADO: `charge` entrega de graça os produtos com preço
-- em Robux. É o único lugar onde a cobrança real (MarketplaceService) entra.
--
-- O estado vai para o cliente na pasta Player.Shop (StatNames.ShopFolder):
-- atributos com os saldos de giros e o kit ativo, e subpastas com um objeto
-- por kit possuído, saldo de kit, produto "once" comprado e passe.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local InventoryConfig = require(Shared.InventoryConfig)
local StatNames = require(Shared.StatNames)
local Products = require(Shared.Shop.Products)
local PurchaseRules = require(Shared.Shop.PurchaseRules)
local ShopData = require(Shared.Shop.ShopData)
local ShopTypes = require(Shared.Shop.Types)
local Throttle = require(Shared.Shop.Throttle)
local SpinRoll = require(Shared.Shop.SpinRoll)
local CosmeticService = require(script.Parent.CosmeticService)
local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Parent.Net)

type Reward = ShopTypes.Reward
type Price = ShopTypes.Price

-- Intervalo mínimo entre pedidos do mesmo tipo do mesmo jogador (clique
-- duplo, rajada). Por tipo: comprar "+1" e girar logo depois não se atrapalham.
local REQUEST_COOLDOWN = 0.3

local ShopService = {}

local throttle = Throttle.new(REQUEST_COOLDOWN)
local rng = Random.new()

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

local function fill(root: Folder, d: ShopData.ShopData)
	root:SetAttribute(StatNames.SpinsNormal, d.Spins.normal)
	root:SetAttribute(StatNames.SpinsPaid, d.Spins.paid)
	root:SetAttribute(StatNames.KitActive, d.KitActive)
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
		fill(existing, d)
		return
	end
	local root = Instance.new("Folder")
	root.Name = StatNames.ShopFolder
	fill(root, d)
	root.Parent = player
end

-- ===== Cobrança e entrega =====

-- Cobra o preço. Robux: grátis por enquanto (aqui entra o MarketplaceService).
function ShopService.charge(player: Player, price: Price, reason: string): boolean
	if price.currency == "robux" then
		return true
	end
	return CurrencyService.spend(player, price.amount, reason)
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
		local id = reward.id :: string
		ShopData.setPass(d, id)
		if id == "vip" then
			InventoryService.setPassBonus(player, InventoryConfig.vipPass.bonusSlots)
		end
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

-- Compra um produto. Devolve (true) ou (false, motivo de PurchaseRules ou "error").
function ShopService.purchase(player: Player, productId: string): (boolean, string?)
	local d = shopOf(player)
	if d == nil then
		return false, "error"
	end
	local product = Products.get(productId)
	local refusal = PurchaseRules.check(product, d, os.time(), CurrencyService.balance(player))
	if refusal ~= nil or product == nil then
		return false, refusal or "unknown"
	end
	for _, reward in product.rewards do
		if GRANTS[reward.kind] == nil then
			return false, "error" -- tipo sem entrega no servidor: não cobra nada
		end
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
		publish(player)
		local d = data.Shop :: ShopData.ShopData
		if d.Passes.vip == true then
			InventoryService.setPassBonus(player, InventoryConfig.vipPass.bonusSlots)
		end
	end)
	Net.RequestPurchase.On(onPurchase)
	Net.RequestSpin.On(onSpin)
	Net.SetActiveKit.On(onSetActive)
	Players.PlayerRemoving:Connect(function(player)
		Throttle.forget(throttle, player)
	end)
end

return ShopService
