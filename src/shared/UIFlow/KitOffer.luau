--!strict
-- Regras dos três jeitos de levar um kit (puras, testadas no Lune):
--   1. pontos, 1 vida (o de verdade: escolha em KitList.selected, cobrado no servidor);
--   2. Robux, 1 vida (mockup);
--   3. Robux, permanente (mockup): depois de ativado, vem em toda vida.
-- Vai UM kit por vida. Ordem de quem vale: escolha de pontos → compra de 1 vida
-- com Robux → permanente ativo → nenhum.
--
-- O estado é imutável: cada função devolve um estado novo (assim a fonte do
-- Vide sempre recebe uma tabela diferente e a tela atualiza).
local KitOffer = {}

export type State = {
	owned: { [string]: boolean }, -- kits permanentes que o jogador tem
	active: string?, -- permanente ativado (vem sozinho em toda vida)
	robuxOnce: string?, -- comprado com Robux para esta vida
}

export type Source = "points" | "robuxOnce" | "permanent"

local function copy(state: State): State
	return { owned = table.clone(state.owned), active = state.active, robuxOnce = state.robuxOnce }
end

-- Estado inicial com estes kits já permanentes (nenhum ativo).
function KitOffer.new(owned: { string }): State
	local set = {}
	for _, id in owned do
		set[id] = true
	end
	return { owned = set, active = nil, robuxOnce = nil }
end

function KitOffer.chooseRobuxOnce(state: State, kitId: string): State
	local nextState = copy(state)
	nextState.robuxOnce = kitId
	return nextState
end

function KitOffer.clearRobuxOnce(state: State): State
	local nextState = copy(state)
	nextState.robuxOnce = nil
	return nextState
end

-- Comprar para sempre só dá a posse: ativar é uma escolha separada.
function KitOffer.buyPermanent(state: State, kitId: string): State
	local nextState = copy(state)
	nextState.owned[kitId] = true
	return nextState
end

-- Ativa (trocando o anterior) ou, se já está ativo, desativa. Kit que o
-- jogador não tem não muda nada.
function KitOffer.toggleActive(state: State, kitId: string): State
	if state.owned[kitId] ~= true then
		return state
	end
	local nextState = copy(state)
	nextState.active = if state.active == kitId then nil else kitId
	return nextState
end

-- Kit que vai nesta vida e de onde ele vem (nil, nil = sem kit).
function KitOffer.current(state: State, pointsKit: string?): (string?, Source?)
	if pointsKit ~= nil then
		return pointsKit, "points"
	elseif state.robuxOnce ~= nil then
		return state.robuxOnce, "robuxOnce"
	elseif state.active ~= nil then
		return state.active, "permanent"
	end
	return nil, nil
end

-- Nasceu: a compra de 1 vida foi usada; o permanente ativo continua.
function KitOffer.spend(state: State): State
	return KitOffer.clearRobuxOnce(state)
end

return KitOffer
