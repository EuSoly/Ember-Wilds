--!strict
-- Regras puras do "chegar perto e agir" das estruturas (G8): quais ações cada
-- tipo de peça (def.structure.kind) tem e quem pode usá-las. Servidor
-- (InteractService) e cliente (InteractState, InteractPanel) usam as mesmas.
--
-- As ações vão pela rede como número (u8 no Net.StructureAction).

local InteractRules = {}

-- Número de cada ação (o que vai na rede).
InteractRules.ACTIONS = table.freeze({
	put_wood = 1,
	take = 2,
	drink = 3,
	sleep = 4,
	symbol = 5,
	fill = 6,
})

-- Studs do centro da peça (XZ), como o baú (ChestRules.RANGE).
InteractRules.RANGE = 8

local A = InteractRules.ACTIONS

-- Ações de cada tipo, na ordem dos botões do painel. Tipo fora daqui não tem
-- painel de interação (o baú tem o painel próprio).
local BY_KIND: { [string]: { number } } = table.freeze({
	extractor = table.freeze({ A.put_wood, A.take }),
	furnace = table.freeze({ A.put_wood }),
	well = table.freeze({ A.drink, A.fill }),
	bed = table.freeze({ A.sleep }),
	sign = table.freeze({ A.symbol }),
})

-- Ações só do dono (e aliados), por tipo. O resto é de qualquer jogador, como o baú.
local OWNER_ONLY: { [string]: { [number]: boolean } } = table.freeze({
	sign = table.freeze({ [A.symbol] = true }),
})

local NONE: { number } = table.freeze({})

-- Ações do tipo (lista vazia = sem ações). A lista é congelada: não mude.
function InteractRules.actionsFor(kind: string): { number }
	return BY_KIND[kind] or NONE
end

-- O jogador pode fazer `action` numa peça do tipo `kind`? `isOwner` = é o dono
-- ou aliado dele (BuildRules.areAllies). Ação fora da lista do tipo: não.
function InteractRules.allowed(kind: string, action: number, isOwner: boolean): boolean
	if not table.find(InteractRules.actionsFor(kind), action) then
		return false
	end
	local ownerOnly = OWNER_ONLY[kind]
	if ownerOnly ~= nil and ownerOnly[action] then
		return isOwner
	end
	return true
end

return table.freeze(InteractRules)
