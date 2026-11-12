--!strict
-- Regras puras do som (sem APIs do Roblox; testadas em tests/soundrules.spec):
-- qual som toca para cada material, bicho e botão, o limite de sons ao mesmo
-- tempo e o cooldown dos repetitivos, a escolha da faixa de música e o
-- crossfade, e as contas do ambiente (água pela distância, fogos mais perto).
-- Os ids e volumes ficam em Audio/SoundConfig; quem toca é o cliente
-- (client/Audio). Veja docs/guia/sons.md.

export type MobEvent = "attack" | "hurt" | "death"
export type MusicMode = "menu" | "day" | "night" | "death"
-- cooldown = s mínimos entre dois toques da mesma chave; max = vozes
-- simultâneas da chave; length = duração (s) contada para a voz acabar.
export type LimitRule = { cooldown: number, max: number, length: number }
export type Limiter = {
	last: { [string]: number }, -- chave → instante do último toque
	ends: { [string]: { number } }, -- chave → instantes em que cada voz acaba
}
type Item = { id: string, count: number }

local SoundRules = {}

-- Som do golpe num recurso (GatherDef.material). Material sem som próprio usa
-- o da pedra, para um recurso novo nunca ficar mudo.
function SoundRules.hitKey(material: string, known: (key: string) -> boolean): string
	local key = "hit_" .. material
	return if known(key) then key else "hit_stone"
end

-- Som de um bicho: o próprio ("mob_wolf_attack") ou o genérico ("mob_attack").
function SoundRules.mobKey(mobId: string, event: MobEvent, known: (key: string) -> boolean): string
	local own = `mob_{mobId}_{event}`
	return if known(own) then own else "mob_" .. event
end

-- Clique de um botão pelo nome da instância: slots do inventário ("Slot3") e
-- células do livro ("Cell"); abas e trocas de página ("Tab_x", "Nav_x" do
-- menu, "Chip_x" do livro); e o resto.
function SoundRules.uiKey(name: string): string
	if string.match(name, "^Slot%d+$") or name == "Cell" then
		return "ui_slot"
	end
	if string.sub(name, 1, 3) == "Tab" or string.sub(name, 1, 4) == "Nav_" or string.sub(name, 1, 5) == "Chip_" then
		return "ui_tab"
	end
	return "ui_click"
end

function SoundRules.newLimiter(): Limiter
	return { last = {}, ends = {} }
end

-- Quantas vozes ainda tocam em `now` (as acabadas saem da conta).
function SoundRules.voices(limiter: Limiter, now: number): number
	local total = 0
	for key, ends in limiter.ends do
		for i = #ends, 1, -1 do
			if ends[i] <= now then
				table.remove(ends, i)
			end
		end
		if #ends == 0 then
			limiter.ends[key] = nil
		else
			total += #ends
		end
	end
	return total
end

-- Pode tocar `key` agora? Recusa dentro do cooldown, com `rule.max` vozes da
-- chave ou `maxTotal` vozes no total. Se pode, já conta a voz nova.
function SoundRules.allow(limiter: Limiter, key: string, now: number, rule: LimitRule, maxTotal: number): boolean
	local last = limiter.last[key]
	if last ~= nil and now - last < rule.cooldown - 1e-9 then
		return false
	end
	local total = SoundRules.voices(limiter, now)
	local ends = limiter.ends[key]
	if total >= maxTotal or (ends ~= nil and #ends >= rule.max) then
		return false
	end
	if ends == nil then
		ends = {}
		limiter.ends[key] = ends
	end
	table.insert(ends, now + rule.length)
	limiter.last[key] = now
	return true
end

-- Música de cada tela: menu, dia/noite jogando e tela de morte. Carregando
-- não toca nada. Sem saber a hora (isNight nil) conta como dia.
function SoundRules.musicMode(screen: string, isNight: boolean?): MusicMode?
	if screen == "menu" then
		return "menu"
	elseif screen == "dead" then
		return "death"
	elseif screen == "playing" then
		local mode: MusicMode = if isNight == true then "night" else "day"
		return mode
	end
	return nil
end

-- Próxima faixa de uma lista de `count`: sorteia (roll em [0, 1)) entre as
-- outras, sem repetir a última. nil com a lista vazia.
function SoundRules.nextTrack(count: number, last: number?, roll: number): number?
	if count <= 0 then
		return nil
	end
	if count == 1 then
		return 1
	end
	roll = math.clamp(roll, 0, 0.999999)
	if last == nil or last < 1 or last > count then
		return math.floor(roll * count) + 1
	end
	local pick = math.floor(roll * (count - 1)) + 1
	return if pick >= last then pick + 1 else pick
end

-- Anda `current` na direção de `target` na velocidade de um fade de `seconds`
-- (0 a 1 em `seconds`), sem passar do alvo.
function SoundRules.approach(current: number, target: number, dt: number, seconds: number): number
	if seconds <= 0 then
		return target
	end
	local step = dt / seconds
	if current < target then
		return math.min(current + step, target)
	end
	return math.max(current - step, target)
end

-- Volumes (antiga, nova) no progresso `t` (0 a 1) do crossfade: somam 1.
function SoundRules.crossfade(t: number): (number, number)
	t = math.clamp(t, 0, 1)
	return 1 - t, t
end

-- A faixa está nos últimos `fade` segundos? (Hora de emendar a próxima.) Faixa
-- não carregada (length 0) nunca troca; faixa curta só troca no finzinho.
function SoundRules.shouldAdvance(position: number, length: number, fade: number): boolean
	if length <= 0 then
		return false
	end
	local window = math.min(fade, length / 4)
	return position >= length - window
end

-- Quantos itens entraram no inventário de `before` para `after` (soma, por
-- item, do que aumentou). Mover de slot não conta; gastar não desconta.
function SoundRules.gained(before: { [number]: Item }, after: { [number]: Item }): number
	local had: { [string]: number } = {}
	for _, item in before do
		had[item.id] = (had[item.id] or 0) + item.count
	end
	local has: { [string]: number } = {}
	for _, item in after do
		has[item.id] = (has[item.id] or 0) + item.count
	end
	local total = 0
	for id, count in has do
		local delta = count - (had[id] or 0)
		if delta > 0 then
			total += delta
		end
	end
	return total
end

-- Contador de eventos (MobAttack, MobHurt) subiu? A primeira leitura (before
-- nil) não conta: o bicho acabou de aparecer no cliente.
function SoundRules.bumped(before: number?, after: number): boolean
	return before ~= nil and after > before
end

-- Volume (0 a 1) do som da água a `distance` studs da beira (0 = dentro).
function SoundRules.waterVolume(distance: number, radius: number): number
	if radius <= 0 or distance >= radius then
		return 0
	end
	local t = 1 - math.max(distance, 0) / radius
	return t * t
end

-- Índices das `count` menores distâncias até `range`, da menor para a maior
-- (quais fogos ganham o som em loop).
function SoundRules.nearest(distances: { number }, count: number, range: number): { number }
	local indexes: { number } = {}
	for i, distance in distances do
		if distance <= range then
			table.insert(indexes, i)
		end
	end
	table.sort(indexes, function(a, b)
		return distances[a] < distances[b]
	end)
	for i = #indexes, count + 1, -1 do
		indexes[i] = nil
	end
	return indexes
end

-- Batimento cardíaco: vivo e com a vida abaixo de `fraction` do máximo.
function SoundRules.heartbeat(health: number, max: number, fraction: number): boolean
	return health > 0 and max > 0 and health / max < fraction
end

return SoundRules
