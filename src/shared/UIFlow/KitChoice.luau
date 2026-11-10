--!strict
-- Qual kit vai nesta vida e de onde ele sai (puro; o servidor decide ao nascer).
-- Vai UM kit por vida:
--   1. o kit pedido, pela origem pedida: "points" (pontos da última vida,
--      KitPoints) ou "balance" (saldo de 1 vida comprado, gasta 1);
--   2. se o pedido não der (sem pontos, sem saldo, kit que não existe), o kit
--      para sempre ativo ("permanent", grátis);
--   3. senão, nenhum.
-- Pedido que não dá nunca troca de origem sozinho (sem pontos não gasta saldo).
local Types = require("../Defs/Types")
local KitRules = require("./KitRules")

export type Source = "points" | "balance" | "permanent"
export type Request = { kitId: string?, source: Source? }
export type State = {
	points: number,
	balance: { [string]: number },
	owned: { [string]: boolean },
	active: string?,
}

type Kits = { [string]: Types.KitDef }

local KitChoice = {}

function KitChoice.resolve(request: Request, state: State, kits: Kits): (string?, Source?)
	local kitId = request.kitId
	local kit = if kitId ~= nil then kits[kitId] else nil
	if kit ~= nil and kitId ~= nil then
		if request.source == "points" and KitRules.canBuy(kit, state.points) then
			return kitId, "points"
		end
		if request.source == "balance" and (state.balance[kitId] or 0) >= 1 then
			return kitId, "balance"
		end
	end
	local active = state.active
	if active ~= nil and kits[active] ~= nil and state.owned[active] == true then
		return active, "permanent"
	end
	return nil, nil
end

-- Origem para quem só escolheu o kit (clique na linha): pontos se der, para
-- guardar o saldo; senão o saldo, se houver; senão nenhuma (não pode escolher).
function KitChoice.auto(kitId: string, points: number, balance: { [string]: number }, kits: Kits): Source?
	local kit = kits[kitId]
	if kit == nil then
		return nil
	end
	if KitRules.canBuy(kit, points) then
		return "points"
	end
	if (balance[kitId] or 0) >= 1 then
		return "balance"
	end
	return nil
end

return KitChoice
