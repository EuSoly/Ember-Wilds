--!strict
-- Sorteio de um giro da roleta (puro; quem chama no servidor passa os números
-- aleatórios). Sorteia a raridade pelas chances do saldo gasto (normal ou
-- especial), escolhe a skin dessa raridade na roleta do tipo e diz se o
-- jogador já a tem: repetida devolve Golden Ember (ShopConfig.DUPLICATE_REFUND).
local MockStore = require("../UIFlow/MockStore")
local SpinRules = require("../UIFlow/SpinRules")
local ShopConfig = require("./ShopConfig")
local ShopTypes = require("./Types")

export type Roll = { itemId: string, rarity: number, duplicate: boolean, refund: number }

local SpinRoll = {}

-- Skins da roleta `typeId` (nil = tipo que não existe).
function SpinRoll.items(typeId: string): { SpinRules.Item }?
	for _, spinType in MockStore.SPIN_TYPES do
		if spinType.id == typeId then
			return spinType.items
		end
	end
	return nil
end

-- Um giro na roleta `typeId` gastando o saldo `kind`. `owns` diz se o jogador
-- já tem a skin; r1 sorteia a raridade e r2 a skin (ambos em [0, 1)).
-- nil = não dá para girar (tipo inexistente ou sem skins): nada deve ser gasto.
function SpinRoll.roll(
	typeId: string,
	kind: ShopTypes.SpinKind,
	owns: (string) -> boolean,
	r1: number,
	r2: number
): Roll?
	local items = SpinRoll.items(typeId)
	if items == nil or #items == 0 then
		return nil
	end
	local rarity = SpinRules.pickIndex(ShopConfig.SPIN_ODDS[kind], r1)
	local item = SpinRules.pickItem(items, rarity, r2)
	local duplicate = owns(item.id)
	return {
		itemId = item.id,
		rarity = item.rarity,
		duplicate = duplicate,
		refund = if duplicate then ShopConfig.DUPLICATE_REFUND[kind] else 0,
	}
end

return SpinRoll
