--!strict
-- Dados da loja no perfil salvo (data.Shop). As funções MUDAM a tabela
-- recebida (é a do perfil): quem chama no servidor republica e salva depois.
-- Puras e testadas; só o ShopService chama no jogo.
local ShopTypes = require("./Types")

export type ShopData = {
	Spins: { normal: number, paid: number }, -- saldos de giros (paid = especial)
	Purchased: { [string]: boolean }, -- produtos "once" já comprados
	KitsOwned: { [string]: boolean }, -- kits para sempre
	KitBalance: { [string]: number }, -- saldo de 1 vida por kit (sem a chave = 0)
	KitActive: string, -- kit para sempre ativo ("" = nenhum; o perfil não guarda nil)
	Passes: { [string]: boolean }, -- passes (ex. ember2x, book)
	VipUntil: number, -- unix em que o VIP acaba (0 = nunca teve)
	BoostStart: number, -- unix em que o boost de XP atual começou
	BoostUntil: number, -- unix em que o boost de XP acaba (<= agora = sem boost)
	ReviveCredits: number, -- revives de cortesia guardados
	CheckIn: { Day: number, LastDay: number }, -- Day = próximo prêmio (1..7); LastDay = RankRules.dayIndex do último resgate (0 = nunca)
	-- Presentes (GiftService): para quem é o próximo "Presente: X" que este
	-- jogador pagar (um por produto), presentes recebidos ainda não abertos
	-- (fila) e PurchaseIds de presentes já entregues a ele (sem entregar 2×).
	GiftPending: { [string]: GiftPending },
	GiftInbox: { GiftEntry },
	GiftIds: { string },
}

export type GiftPending = { to: number, name: string }
export type GiftEntry = { from: string, productId: string }

-- Quantos PurchaseIds de presente o perfil guarda (os mais velhos saem).
local GIFT_IDS_MAX = 100

local ShopData = {}

-- Tabela nova a cada chamada (vai no template do perfil).
function ShopData.empty(): ShopData
	return {
		Spins = { normal = 0, paid = 0 },
		Purchased = {},
		KitsOwned = {},
		KitBalance = {},
		KitActive = "",
		Passes = {},
		VipUntil = 0,
		BoostStart = 0,
		BoostUntil = 0,
		ReviveCredits = 0,
		CheckIn = { Day = 1, LastDay = 0 },
		GiftPending = {},
		GiftInbox = {},
		GiftIds = {},
	}
end

function ShopData.addSpins(d: ShopData, kind: ShopTypes.SpinKind, count: number)
	d.Spins[kind] = (d.Spins[kind] or 0) + count
end

-- Gasta um giro do saldo `kind`. false (e nada muda) sem saldo.
function ShopData.useSpin(d: ShopData, kind: ShopTypes.SpinKind): boolean
	local have = d.Spins[kind] or 0
	if have < 1 then
		return false
	end
	d.Spins[kind] = have - 1
	return true
end

function ShopData.addKitBalance(d: ShopData, kitId: string, count: number)
	d.KitBalance[kitId] = (d.KitBalance[kitId] or 0) + count
end

-- Gasta 1 do saldo do kit (some da lista ao chegar a 0). false sem saldo.
function ShopData.useKitBalance(d: ShopData, kitId: string): boolean
	local have = d.KitBalance[kitId] or 0
	if have < 1 then
		return false
	end
	if have > 1 then
		d.KitBalance[kitId] = have - 1
	else
		d.KitBalance[kitId] = nil
	end
	return true
end

function ShopData.ownKit(d: ShopData, kitId: string)
	d.KitsOwned[kitId] = true
end

-- Ativa um kit para sempre possuído (nil desativa). false se não possui.
function ShopData.setActive(d: ShopData, kitId: string?): boolean
	if kitId == nil then
		d.KitActive = ""
		return true
	end
	if d.KitsOwned[kitId] ~= true then
		return false
	end
	d.KitActive = kitId
	return true
end

function ShopData.setPass(d: ShopData, passId: string)
	d.Passes[passId] = true
end

-- Soma `days` de VIP a partir do mais tarde entre agora e o fim atual.
function ShopData.addVipDays(d: ShopData, days: number, now: number)
	d.VipUntil = math.max(now, d.VipUntil) + days * 86400
end

-- Soma `seconds` de boost de XP. Boost que já tinha acabado recomeça agora;
-- boost em andamento só estende o fim.
function ShopData.addBoost(d: ShopData, seconds: number, now: number)
	if d.BoostUntil <= now then
		d.BoostStart = now
	end
	d.BoostUntil = math.max(now, d.BoostUntil) + seconds
end

function ShopData.markPurchased(d: ShopData, productId: string)
	d.Purchased[productId] = true
end

-- O próximo "Presente: <productId>" que este jogador pagar vai para `toUserId`
-- (substitui o anterior do mesmo produto).
function ShopData.setGiftPending(d: ShopData, productId: string, toUserId: number, toName: string)
	d.GiftPending[productId] = { to = toUserId, name = toName }
end

-- Lê e apaga o destinatário do presente `productId` (nil se não há).
function ShopData.takeGiftPending(d: ShopData, productId: string): GiftPending?
	local pending = d.GiftPending[productId]
	d.GiftPending[productId] = nil
	return pending
end

-- Guarda o PurchaseId de um presente entregue. false se já estava (recibo
-- repetido: não entregar de novo).
function ShopData.rememberGift(d: ShopData, purchaseId: string): boolean
	if table.find(d.GiftIds, purchaseId) ~= nil then
		return false
	end
	while #d.GiftIds >= GIFT_IDS_MAX do
		table.remove(d.GiftIds, 1)
	end
	table.insert(d.GiftIds, purchaseId)
	return true
end

-- Presente recebido e ainda não aberto vai para o fim da fila.
function ShopData.pushInbox(d: ShopData, from: string, productId: string)
	table.insert(d.GiftInbox, { from = from, productId = productId })
end

-- Tira o primeiro presente da fila (nil se vazia).
function ShopData.popInbox(d: ShopData): GiftEntry?
	return table.remove(d.GiftInbox, 1)
end

-- Ao carregar o perfil: marcas que não são `true` (ex. alguém tirou um kit
-- editando o perfil e deixou false) somem. A POSSE NO PERFIL É A VERDADE:
-- nada é devolvido a partir de Purchased. Dar ou tirar um kit/passe de
-- alguém = mexer em KitsOwned/Passes (ShopService.grant, DevShopGrant).
function ShopData.clean(d: ShopData)
	for _, set in { d.KitsOwned, d.Passes, d.Purchased } :: { { [string]: boolean } } do
		for key, value in set do
			if value ~= true then
				set[key] = nil
			end
		end
	end
end

return ShopData
