--!strict
-- Regras do modo criativo (puras, testadas no Lune). Quem liga é a marca
-- Creative do perfil (CreativeService); veja docs/guia/modo-criativo.md.
local Types = require("../Defs/Types")

local CreativeRules = {}

-- Segundos mínimos entre dois pedidos de item (o botão Pegar).
CreativeRules.GIVE_EVERY = 0.2

-- Quanto um clique em Pegar entrega: uma ferramenta, ou uma pilha de até 100.
CreativeRules.MAX_GIVE = 100

function CreativeRules.giveCount(def: Types.ItemDef): number
	return math.min(def.maxStack, CreativeRules.MAX_GIVE)
end

-- Pode pedir de novo? `last` = instante do último pedido (nil = nunca).
function CreativeRules.canGive(last: number?, now: number): boolean
	return last == nil or now - last >= CreativeRules.GIVE_EVERY
end

-- Os itens do jogador podem ir para outros? Do criativo, não: ao morrer não
-- vira caixa e não guarda em baú (senão o amigo farma com os itens dele).
function CreativeRules.sharesItems(creative: boolean): boolean
	return not creative
end

return CreativeRules
