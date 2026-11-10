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
	Passes: { [string]: boolean }, -- passes (ex. vip)
}

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

function ShopData.markPurchased(d: ShopData, productId: string)
	d.Purchased[productId] = true
end

-- Ao carregar o perfil: o que os produtos comprados dão para sempre (kit,
-- passe) volta a valer, e marcas `false` (não deveriam existir) somem.
-- Rede de segurança: em 10/11 um perfil de teste apareceu com os kits para
-- sempre gravados como false, com as compras certas em Purchased; a causa
-- não foi achada. Idempotente: não mexe em saldos nem no kit ativo.
function ShopData.restoreOwned(d: ShopData, products: { ShopTypes.Product })
	for _, set in { d.KitsOwned, d.Passes, d.Purchased } :: { { [string]: boolean } } do
		for key, value in set do
			if value ~= true then
				set[key] = nil
			end
		end
	end
	for _, product in products do
		if d.Purchased[product.id] == true then
			for _, reward in product.rewards do
				if reward.kind == "kit" and reward.id then
					d.KitsOwned[reward.id] = true
				elseif reward.kind == "pass" and reward.id then
					d.Passes[reward.id] = true
				end
			end
		end
	end
end

return ShopData
