--!strict
-- Vantagens valendo no jogo: VIP por tempo, gamepasses (2× e livro) e o
-- Premium do Roblox. A regra é pura (Shared/Shop/Perks); aqui ficam a foto de
-- cada vida, os espaços extras e os atributos para o cliente.
--
-- - current: o que vale AGORA (perfil + MembershipType).
-- - forLife: foto tirada quando a vida começa (LifeService.onStarted) e que vale
--   até o fim dela, inclusive depois da morte (tela de morte, revive). Sem foto
--   (antes da primeira vida) = current.
-- - Ganhar uma vantagem com a vida ativa entra na foto na hora (VIP comprado
--   vivo dá os +3 espaços já); perder (VIP vencido, passe tirado, Premium
--   cancelado) só vale na próxima vida.
-- - Atributos na pasta Player.Shop (StatNames.ShopFolder, criada pelo
--   ShopService; NÃO no Player, que tem o limite de ~1 KB de atributos):
--   Perk_vip/ember2x/book/premium = a foto da vida enquanto há vida ativa, e
--   current() sem vida (morto / no menu); VipUntil, XpBoostStart, XpBoostUntil
--   = o perfil (unix).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Defs = require(Shared.Defs)
local InventoryConfig = require(Shared.InventoryConfig)
local StatNames = require(Shared.StatNames)
local Perks = require(Shared.Shop.Perks)
local ShopData = require(Shared.Shop.ShopData)
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)
local LifeService = require(script.Parent.LifeService)

type PerkSet = Perks.PerkSet

local PerkService = {}

local snapshots: { [Player]: PerkSet } = {}

local function shopOf(player: Player): ShopData.ShopData?
	local data = DataService.data(player)
	return if data then data.Shop :: ShopData.ShopData else nil
end

local function isPremium(player: Player): boolean
	return player.MembershipType == Enum.MembershipType.Premium
end

function PerkService.current(player: Player): PerkSet
	local d = shopOf(player)
	if d == nil then
		return { vip = false, ember2x = false, book = false, premium = isPremium(player) }
	end
	return Perks.resolve(d, isPremium(player), os.time())
end

function PerkService.forLife(player: Player): PerkSet
	local snapshot = snapshots[player]
	return if snapshot then table.clone(snapshot) else PerkService.current(player)
end

function PerkService.emberMultiplier(player: Player): number
	return Perks.emberMultiplier(PerkService.forLife(player))
end

function PerkService.unlockedKits(player: Player): { [string]: boolean }
	return Perks.unlockedKits(PerkService.forLife(player), Defs.Kits)
end

-- Espaços extras do VIP desta vida (0 tira o bônus).
local function applySlots(player: Player, set: PerkSet)
	InventoryService.setPerkBonus(player, if set.vip then InventoryConfig.vipPass.bonusSlots else 0)
end

-- Escreve os atributos das vantagens em `folder` (a pasta Player.Shop). O
-- ShopService chama ao montar a pasta, antes de ela ir para o Player: ele é o
-- único que cria a pasta. Com vida ativa, Perk_* = a foto da vida; sem vida
-- (morto, menu), o que vale agora.
function PerkService.writeAttributes(player: Player, folder: Instance)
	local snapshot = snapshots[player]
	local set = if snapshot ~= nil and LifeService.lifeKey(player) ~= nil then snapshot else PerkService.current(player)
	folder:SetAttribute(StatNames.PerkVip, set.vip)
	folder:SetAttribute(StatNames.PerkEmber2x, set.ember2x)
	folder:SetAttribute(StatNames.PerkBook, set.book)
	folder:SetAttribute(StatNames.PerkPremium, set.premium)
	local d = shopOf(player)
	folder:SetAttribute(StatNames.VipUntil, if d then d.VipUntil else 0)
	folder:SetAttribute(StatNames.XpBoostStart, if d then d.BoostStart else 0)
	folder:SetAttribute(StatNames.XpBoostUntil, if d then d.BoostUntil else 0)
end

-- Atualiza a pasta Player.Shop, se já existe (sem ela, o ShopService escreve
-- tudo quando a criar).
local function publish(player: Player)
	if player.Parent ~= Players then
		return
	end
	local folder = player:FindFirstChild(StatNames.ShopFolder)
	if folder ~= nil and folder:IsA("Folder") then
		PerkService.writeAttributes(player, folder)
	end
end

-- Republica os atributos depois de compra, presente ou mudança de Premium.
-- Com a vida ativa, o que foi GANHO entra na foto desta vida na hora.
function PerkService.refresh(player: Player)
	local snapshot = snapshots[player]
	if snapshot ~= nil and LifeService.lifeKey(player) ~= nil then
		local now = PerkService.current(player)
		local gainedVip = now.vip and not snapshot.vip
		snapshot.vip = snapshot.vip or now.vip
		snapshot.ember2x = snapshot.ember2x or now.ember2x
		snapshot.book = snapshot.book or now.book
		snapshot.premium = snapshot.premium or now.premium
		if gainedVip then
			applySlots(player, snapshot)
		end
	end
	publish(player)
end

-- Foto da vida que começa: espaços extras antes do kit (SpawnService chama
-- LifeService.begin logo depois de nascer, antes de dar os itens).
local function onLifeStarted(player: Player)
	if player.Parent ~= Players then
		return
	end
	local set = PerkService.current(player)
	snapshots[player] = set
	applySlots(player, set)
	publish(player)
end

-- No Init (antes de qualquer Start): nenhuma vida começa sem a foto nem
-- termina com o multiplicador padrão.
function PerkService.Init(_self)
	LifeService.setMultiplierSource(PerkService.emberMultiplier)
	LifeService.onStarted(onLifeStarted)
	-- Sem vida, Perk_* passa a mostrar o que vale agora.
	LifeService.onEnded(publish)
end

function PerkService.Start(_self)
	Players.PlayerMembershipChanged:Connect(PerkService.refresh)
	-- task.defer: o fim de vida da saída (DataService.onUnloading) ainda lê a foto.
	Players.PlayerRemoving:Connect(function(player)
		task.defer(function()
			snapshots[player] = nil
		end)
	end)
end

return PerkService
