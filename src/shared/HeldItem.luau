--!strict
-- Efeitos do item na mão no corpo do jogador (puro, testado no Lune):
-- velocidade de andar, alcance do golpe e a trava da arma recém-equipada.
-- Os números ficam nos itens (Defs/Items: moveSpeed, reach, equipLock).
local Types = require("./Defs/Types")

local HeldItem = {}

-- Fração da velocidade de andar com o item na mão (1 = normal).
function HeldItem.speedFactor(item: Types.ItemDef?): number
	return if item and item.moveSpeed then item.moveSpeed else 1
end

-- Studs a mais de alcance do golpe.
function HeldItem.reach(item: Types.ItemDef?): number
	return if item and item.reach then item.reach else 0
end

-- Studs que o golpe empurra o mob para longe de quem bateu.
function HeldItem.knockback(item: Types.ItemDef?): number
	return if item and item.knockback then item.knockback else 0
end

-- O item na mão ainda está preso (não dá para trocar de slot)? `lockUntil` é
-- o atributo EquipLockUntil do personagem (instante do servidor).
function HeldItem.isLocked(item: Types.ItemDef?, lockUntil: any, now: number): boolean
	if item == nil or item.equipLock == nil then
		return false
	end
	return type(lockUntil) == "number" and lockUntil == lockUntil and now < lockUntil
end

return HeldItem
