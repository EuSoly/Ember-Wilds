--!strict
-- Regras dos giros da loja (puras, testadas no Lune): sorteio por peso,
-- escolha do item pela raridade, contadores de giros comprados e confete.
-- Raridade é um índice 1..5 na ordem de MockStore.RARITIES (Comum → Mítico).
-- Os contadores são imutáveis: cada função devolve uma tabela nova (assim a
-- fonte do Vide sempre muda e a tela atualiza).
local SpinRules = {}

export type Item = { id: string, nameKey: string, rarity: number, color: string }
export type Kind = "normal" | "paid"
export type Counts = { [string]: { normal: number, paid: number } }

-- Índice sorteado para r em [0, 1) com `weights` (qualquer escala: 100, 1…).
-- Se a soma ficar um pouco abaixo do total, r na ponta cai no último índice.
function SpinRules.pickIndex(weights: { number }, r: number): number
	local total = 0
	for _, w in weights do
		total += w
	end
	local acc = 0
	for i, w in weights do
		acc += w / total
		if r < acc then
			return i
		end
	end
	return #weights
end

local MAX_RARITY = 5

-- Item da raridade pedida (r escolhe entre eles). Sem nenhum dessa raridade,
-- desce até achar; sem nada abaixo, sobe: o sorteio nunca fica sem prêmio.
function SpinRules.pickItem(items: { Item }, rarity: number, r: number): Item
	local order: { number } = {}
	for wanted = rarity, 1, -1 do
		table.insert(order, wanted)
	end
	for wanted = rarity + 1, MAX_RARITY do
		table.insert(order, wanted)
	end
	for _, wanted in order do
		local pool: { Item } = {}
		for _, item in items do
			if item.rarity == wanted then
				table.insert(pool, item)
			end
		end
		if #pool > 0 then
			return pool[math.clamp(math.floor(r * #pool) + 1, 1, #pool)]
		end
	end
	error("[SpinRules] lista de itens vazia")
end

function SpinRules.newCounts(): Counts
	return {}
end

local function copy(counts: Counts): Counts
	local out: Counts = {}
	for typeId, entry in counts do
		out[typeId] = { normal = entry.normal, paid = entry.paid }
	end
	return out
end

local function entryOf(counts: Counts, typeId: string): { normal: number, paid: number }
	local entry = counts[typeId]
	if entry == nil then
		entry = { normal = 0, paid = 0 }
		counts[typeId] = entry
	end
	return entry
end

-- Soma `qty` giros do tipo (normal ou pago).
function SpinRules.addSpins(counts: Counts, typeId: string, kind: Kind, qty: number): Counts
	local out = copy(counts)
	local entry = entryOf(out, typeId)
	entry[kind] += qty
	return out
end

function SpinRules.canSpin(counts: Counts, typeId: string, kind: Kind): boolean
	local entry = counts[typeId]
	return entry ~= nil and entry[kind] > 0
end

-- Gasta um giro; sem giro, devolve o mesmo estado.
function SpinRules.useSpin(counts: Counts, typeId: string, kind: Kind): Counts
	if not SpinRules.canSpin(counts, typeId, kind) then
		return counts
	end
	local out = copy(counts)
	out[typeId][kind] -= 1
	return out
end

-- O saldo (atributo) paga o preço? NaN/infinito contam como inválidos.
function SpinRules.canAfford(balance: number, price: number): boolean
	if type(balance) ~= "number" or balance ~= balance or balance == math.huge or balance == -math.huge then
		return false
	end
	return balance >= price
end

-- Peças de confete na janelinha do prêmio: no pago sempre (mais quanto mais
-- raro); no normal só de Épico (3) para cima, com pouco.
local CONFETTI_PAID = { 20, 35, 60, 100, 150 }
local CONFETTI_NORMAL = 20
local NORMAL_FROM = 3

function SpinRules.confettiFor(rarity: number, paid: boolean): number
	if paid then
		return CONFETTI_PAID[math.clamp(rarity, 1, #CONFETTI_PAID)]
	end
	return if rarity >= NORMAL_FROM then CONFETTI_NORMAL else 0
end

return SpinRules
