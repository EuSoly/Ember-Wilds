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

-- Kit existe e os pontos (finitos) pagam o preço. Pontos vêm de atributo,
-- então NaN/infinito são tratados como inválidos.
function KitRules.canBuy(kit: KitDef?, points: number): boolean
	if kit == nil or type(points) ~= "number" or points ~= points then
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
