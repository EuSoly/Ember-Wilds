--!strict
-- Escolha do cosmético de um slot a partir do id gravado no personagem.
-- Puro (sem APIs do Roblox): roda no servidor, no cliente e nos testes do Lune.
local Types = require("./Defs/Types")

local Cosmetic = {}

-- Devolve o cosmético `id` se ele existir e for deste slot; senão o padrão do
-- slot. Um id desconhecido (ex. skin removida num update) não quebra o boneco:
-- cai no padrão com um aviso. Slot inexistente é erro de programação.
function Cosmetic.resolve(defs: Types.DefsTables, slot: string, id: string?): Types.CosmeticDef
	local slotDef = defs.CosmeticSlots[slot]
	if slotDef == nil then
		error(`[Cosmetic] slot "{slot}" não existe em CosmeticSlots`)
	end
	if id ~= nil then
		local cosmetic = defs.Cosmetics[id]
		if cosmetic ~= nil and cosmetic.slot == slot then
			return cosmetic
		end
		warn(`[Cosmetic] "{id}" não é um cosmético do slot "{slot}"; usando o padrão`)
	end
	return defs.Cosmetics[slotDef.default]
end

return Cosmetic
