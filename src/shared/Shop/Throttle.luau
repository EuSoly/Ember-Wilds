--!strict
-- Limite de frequência dos pedidos da loja (puro): um intervalo mínimo por
-- jogador E por tipo de pedido. Separado por tipo para comprar "+1" e girar
-- logo em seguida não descartar o giro. Chave do jogador: qualquer valor
-- (o servidor usa o próprio Player).
export type Throttle = { cooldown: number, last: { [any]: { [string]: number } } }

local Throttle = {}

function Throttle.new(cooldown: number): Throttle
	return { cooldown = cooldown, last = {} }
end

-- true (e marca a hora) se o pedido `kind` de `who` pode seguir em `now`.
function Throttle.allow(t: Throttle, who: any, kind: string, now: number): boolean
	local byKind = t.last[who]
	if byKind == nil then
		byKind = {}
		t.last[who] = byKind
	end
	local last = byKind[kind]
	if last ~= nil and now - last < t.cooldown then
		return false
	end
	byKind[kind] = now
	return true
end

function Throttle.forget(t: Throttle, who: any)
	t.last[who] = nil
end

return Throttle
