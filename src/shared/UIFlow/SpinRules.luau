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

-- Skin em destaque no cartão do giro (loja): uma das mais raras do tipo —
-- Míticas, ou a maior raridade que existir — escolhida por r em [0, 1).
-- Lista vazia: nil.
function SpinRules.featuredItem(items: { Item }, r: number): Item?
	local best = 0
	for _, item in items do
		best = math.max(best, item.rarity)
	end
	local pool: { Item } = {}
	for _, item in items do
		if item.rarity == best then
			table.insert(pool, item)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[math.clamp(math.floor(r * #pool) + 1, 1, #pool)]
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
-- O botão GIRAR da tela de roleta pode ser apertado: tem giro, não está
-- girando e a janelinha do prêmio já foi fechada (com o prêmio aberto, um
-- segundo giro começava por trás e o Pegar o cortava no meio: a tela travava
-- girando, sem fechar; visto em 10/11/2026).
function SpinRules.canPress(spins: number, spinning: boolean, prizeOpen: boolean): boolean
	return spins > 0 and not spinning and not prizeOpen
end

function SpinRules.canAfford(balance: number, price: number): boolean
	if type(balance) ~= "number" or balance ~= balance or balance == math.huge or balance == -math.huge then
		return false
	end
	return balance >= price
end

-- Peças de confete na janelinha do prêmio: no pago sempre (mais quanto mais
-- raro); no normal só de Épico (3) para cima, crescendo com a raridade.
local CONFETTI_PAID = { 20, 35, 60, 100, 150 }
local CONFETTI_NORMAL = { 0, 0, 20, 40, 70 }

function SpinRules.confettiFor(rarity: number, paid: boolean): number
	local list = if paid then CONFETTI_PAID else CONFETTI_NORMAL
	return list[math.clamp(rarity, 1, #list)]
end

-- Efeitos de quando o carrossel para e o prêmio aparece, na medida da
-- raridade (o giro pago ganha um degrau a mais):
--   hold  — s com o prêmio em destaque no carrossel antes da janelinha abrir
--           (a "respirada" do suspense; o tambor continua nela);
--   shake — px da tremida da caixa ao parar (0 = não treme);
--   flash — opacidade do clarão na cor da raridade quando a janelinha abre
--           (0 = sem clarão);
--   rays  — raios girando atrás da janelinha;
--   ring  — onda de choque (anel que cresce e some) atrás da janelinha;
--   mystic — comemoração mística (só Mítico, pago ou não): círculo mágico com
--           runas, aura respirando e luzinhas subindo no lugar do confete,
--           combinando com o som etéreo da revelação (12/11).
export type Reveal = { hold: number, shake: number, flash: number, rays: boolean, ring: boolean, mystic: boolean }

local HOLD = { 0.3, 0.4, 0.55, 0.7, 0.9 }
local SHAKE = { 0, 0, 3, 6, 9 }
local FLASH = { 0, 0.15, 0.3, 0.45, 0.6 }
local PAID_SHAKE = 3
local PAID_FLASH = 0.15
local RAYS_FROM = 2
local RING_FROM = 3
local MYSTIC_FROM = 5

function SpinRules.revealFor(rarity: number, paid: boolean): Reveal
	local r = math.clamp(rarity, 1, #HOLD)
	return {
		hold = HOLD[r],
		shake = SHAKE[r] + (if paid then PAID_SHAKE else 0),
		flash = FLASH[r] + (if paid then PAID_FLASH else 0),
		rays = paid or r >= RAYS_FROM,
		ring = paid or r >= RING_FROM,
		mystic = r >= MYSTIC_FROM,
	}
end

-- Tique do carrossel: `progress` é a fração do tempo do giro (0..1) e
-- `suspense` o quanto a raridade que vai sair aperta o som (0..1,
-- SpinSoundConfig.tension). O tom sobe um pouco em todo giro conforme freia e
-- sobe mais com o suspense; o volume começa baixo (no começo passam muitos
-- por segundo) e cresce até os últimos, que são os que contam.
local TICK_PITCH_BASE = 0.12
local TICK_PITCH_SUSPENSE = 0.35
local TICK_VOLUME_START = 0.55

function SpinRules.tickPitch(progress: number, suspense: number): number
	local p = math.clamp(progress, 0, 1)
	return 1 + p * (TICK_PITCH_BASE + TICK_PITCH_SUSPENSE * math.clamp(suspense, 0, 1))
end

function SpinRules.tickVolume(progress: number): number
	return TICK_VOLUME_START + (1 - TICK_VOLUME_START) * math.clamp(progress, 0, 1)
end

-- Suspense dos sons do giro: 0 até TENSION_START do giro (fração do tempo),
-- depois sobe em curva até 1 no fim — cresce mais quando o carrossel já está
-- quase parando. Quanto disso vira som depende da raridade (SpinSoundConfig).
SpinRules.TENSION_START = 0.3

function SpinRules.tensionRamp(progress: number): number
	local t = math.clamp((progress - SpinRules.TENSION_START) / (1 - SpinRules.TENSION_START), 0, 1)
	return t * t
end

-- Número do quadradinho embaixo do marcador (meio da janela) com a fita na
-- posição `stripX`. Cada vez que muda, um quadradinho passou: toca o tique.
function SpinRules.markerTile(stripX: number, step: number, windowWidth: number): number
	return math.floor((windowWidth / 2 - stripX) / step)
end

return SpinRules
