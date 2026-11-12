--!strict
-- Cavar com a pá (puro, testado no Lune). Com uma pá na mão (item com `dig`),
-- o golpe que não acerta nada cava o chão: terra (`ground`) no chão da
-- floresta, areia (`sand`) nas margens da água, nada na água. Cada golpe dá
-- `dig` unidades (config do Starve: pá de pedra 1, ouro 2, diamante 3, ametista
-- e reidite 4) e pode achar mais um item de sorte (dig_items da config).
-- Quem decide onde é areia é o mapa (MapService.isSandAt); quem dá os itens é
-- o GatherService.
local Types = require("../Defs/Types")

export type Surface = "ground" | "sand"
export type Find = { id: string, count: number }

local DigRules = {}

-- Pontos por unidade cavada (como os outros recursos baratos).
DigRules.POINTS = 1

-- Achados de sorte por golpe (dig_items da config do Starve), na ordem dos
-- sorteios: chance de vir 1 a mais desse item. Item testOnly fica de fora.
DigRules.LUCK = table.freeze({
	table.freeze({ id = "stone", chance = 0.05 }),
	table.freeze({ id = "gold", chance = 0.0153846153846 }),
	table.freeze({ id = "diamond", chance = 0.00166666666667 }),
})

-- O item na mão cava?
function DigRules.canDig(tool: Types.ItemDef?): boolean
	return tool ~= nil and type(tool.dig) == "number" and tool.dig > 0
end

-- O que tem no chão do golpe: água = nada; margem = areia; resto = terra.
function DigRules.surfaceAt(isWater: boolean, isSand: boolean): Surface?
	if isWater then
		return nil
	end
	return if isSand then "sand" else "ground"
end

-- O que um golpe cava: `dig` do chão e os achados de sorte. `rolls` são os
-- sorteios (0 a 1), um por entrada de LUCK, na ordem.
function DigRules.dig(tool: Types.ItemDef?, surface: Surface, rolls: { number }, defs: Types.DefsTables): { Find }
	if tool == nil or not DigRules.canDig(tool) then
		return {}
	end
	local finds: { Find } = { { id = surface, count = tool.dig :: number } }
	for index, luck in DigRules.LUCK do
		local item = defs.Items[luck.id]
		local roll = rolls[index]
		if item ~= nil and not item.testOnly and type(roll) == "number" and roll < luck.chance then
			table.insert(finds, { id = luck.id, count = 1 })
		end
	end
	return finds
end

return DigRules
