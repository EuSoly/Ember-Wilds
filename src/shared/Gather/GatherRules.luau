--!strict
-- Regras da coleta (só números: testável no Lune). O GatherService usa para
-- decidir o golpe; o cliente usa berriesVisible para as frutinhas do arbusto.
-- Números do Starve.io; veja docs/guia/coleta.md.
local Types = require("../Defs/Types")

export type Target = { x: number, z: number, radius: number }

local GatherRules = {}

GatherRules.HIT_INTERVAL = 0.5 -- segundos entre golpes (2 por segundo)
GatherRules.HIT_REACH = 3.5 -- studs da raiz até o centro do golpe, na direção do olhar
GatherRules.HIT_RADIUS = 2.5 -- raio do círculo do golpe

-- Instante do próximo golpe, depois de um golpe dado em `now`. Segurando, conta
-- a partir do golpe previsto (`due`), não de quando o laço conferiu: assim o
-- golpe não escorrega e cai junto com o braço do boneco (que bate a cada
-- HIT_INTERVAL exatos). Se o previsto ficou para trás (soltou o botão), recomeça.
function GatherRules.nextHit(due: number?, now: number): number
	if due and now - due < GatherRules.HIT_INTERVAL then
		return due + GatherRules.HIT_INTERVAL
	end
	return now + GatherRules.HIT_INTERVAL
end

-- Nível de coleta do que está na mão: picareta = o nível dela; mão ou qualquer
-- outro item = 0.
local function levelOf(tool: Types.ItemDef?): number
	local pickaxe = tool and tool.pickaxe
	return if pickaxe then pickaxe.level else 0
end

-- Quanto um golpe rende com `tool` na mão (nil = mão). nil = ferramenta fraca
-- demais para esse recurso. Rendimento fixo (frutinha) vale com qualquer coisa.
function GatherRules.yield(tool: Types.ItemDef?, gather: Types.GatherDef): number?
	if gather.fixedYield then
		return gather.fixedYield
	end
	local hardness = gather.hardness or 0
	local level = levelOf(tool)
	if level < hardness then
		return nil
	end
	return level - hardness + 1
end

-- A picareta mais fraca que coleta essa dureza (para o aviso). Empate de
-- nível: o menor id. nil = nenhuma picareta serve.
function GatherRules.requiredPickaxe(items: { [string]: Types.ItemDef }, hardness: number): string?
	local best: string? = nil
	local bestLevel = math.huge
	for id, item in items do
		local pickaxe = item.pickaxe
		if pickaxe and pickaxe.level >= hardness then
			if pickaxe.level < bestLevel or (pickaxe.level == bestLevel and best ~= nil and id < best) then
				best, bestLevel = id, pickaxe.level
			end
		end
	end
	return best
end

-- Reserva máxima de um exemplar de tamanho `scale` (Scatter.sizeFactor, que
-- varia em [1 - jitter, 1 + jitter]): linear de amount.min (o menor) a
-- amount.max (o maior). Sem variação de tamanho = o meio.
function GatherRules.maxAmount(gather: Types.GatherDef, scale: number, jitter: number): number
	local low, high = gather.amount.min, gather.amount.max
	if low == high then
		return low
	end
	local t = if jitter > 0 then math.clamp((scale - (1 - jitter)) / (2 * jitter), 0, 1) else 0.5
	return math.floor(low + (high - low) * t + 0.5)
end

-- Reserva depois de uma volta da regeneração (sem passar do máximo).
function GatherRules.regen(amount: number, max: number, gather: Types.GatherDef): number
	return math.min(amount + gather.regen.amount, max)
end

-- Quantas peças Berry mostrar: proporção da reserva, arredondando para cima
-- (enquanto houver alguma, ao menos uma aparece).
function GatherRules.berriesVisible(amount: number, max: number, parts: number): number
	if amount <= 0 or max <= 0 then
		return 0
	end
	return math.min(math.ceil(amount / max * parts), parts)
end

-- Alvo do golpe: entre os candidatos cuja peça de colisão encosta no círculo
-- do golpe (centro px, pz e raio hitRadius), o de borda mais perto do centro.
function GatherRules.pickTarget<T>(candidates: { T }, px: number, pz: number, hitRadius: number): T?
	local best: T? = nil
	local bestGap = math.huge
	for _, candidate in candidates do
		local c = candidate :: any
		local distance = math.sqrt((c.x - px) ^ 2 + (c.z - pz) ^ 2)
		local gap = distance - c.radius
		if gap <= hitRadius and gap < bestGap then
			best, bestGap = candidate, gap
		end
	end
	return best
end

return GatherRules
