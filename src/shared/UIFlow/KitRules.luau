--!strict
-- Regras de compra de kit inicial (puras, testadas no Lune). O servidor usa
-- para cobrar e o cliente para mostrar o que dá para comprar.
local Types = require("../Defs/Types")

type KitDef = Types.KitDef

local KitRules = {}

-- Kits numa lista, na ordem da tela (campo order).
function KitRules.sorted(kits: { [string]: KitDef }): { KitDef }
	local list: { KitDef } = {}
	for _, kit in kits do
		table.insert(list, kit)
	end
	table.sort(list, function(a: KitDef, b: KitDef): boolean
		return a.order < b.order
	end)
	return list
end

-- Kits que o jogador vê, na ordem da tela: os exclusivos (só de conquista)
-- só para quem tem a posse (Shop.KitsOwned). Os vipOnly aparecem para todos
-- (vitrine do VIP); quem pode usar é decidido por Shop/Perks.
function KitRules.shows(kit: KitDef, owned: boolean): boolean
	return not kit.exclusive or kit.vipOnly == true or owned
end

function KitRules.visible(kits: { [string]: KitDef }, owned: { [string]: boolean }): { KitDef }
	local list: { KitDef } = {}
	for _, kit in KitRules.sorted(kits) do
		if KitRules.shows(kit, owned[kit.id] == true) then
			table.insert(list, kit)
		end
	end
	return list
end

-- Como o jogador pode levar o kit sem pagar por ele:
--   "owned"   comprado para sempre (ou ganho);
--   "vip"     liberado pelo VIP desta vida;
--   "premium" liberado pelo Premium do Roblox;
--   "locked"  kit só do VIP, e o jogador não é VIP (cadeado, "Só VIP");
--   "none"    kit comum: compra por pontos/saldo/Robux como sempre.
-- `unlocked` vem de Shop/Perks.unlockedKits (kits liberados pelas vantagens).
export type Access = "owned" | "vip" | "premium" | "locked" | "none"

function KitRules.access(kit: KitDef, owned: boolean, unlocked: { [string]: boolean }): Access
	if owned then
		return "owned"
	end
	if unlocked[kit.id] == true then
		return if kit.vipOnly == true then "vip" else "premium"
	end
	if kit.vipOnly == true then
		return "locked"
	end
	return "none"
end

-- Kit existe, não é exclusivo e os pontos (finitos) pagam o preço. Pontos vêm de atributo,
-- então NaN/infinito são tratados como inválidos.
function KitRules.canBuy(kit: KitDef?, points: number): boolean
	if kit == nil or kit.exclusive or type(points) ~= "number" or points ~= points then
		return false
	end
	if points == math.huge or points == -math.huge then
		return false
	end
	return points >= kit.price
end

-- (comprou?, pontos que sobram). Se não pode comprar, os pontos não mudam.
function KitRules.buy(kit: KitDef?, points: number): (boolean, number)
	if kit == nil or not KitRules.canBuy(kit, points) then
		return false, points
	end
	return true, points - kit.price
end

return KitRules
