--!strict
-- Ranking semanal (UI 6): guarda no perfil o valor da semana de cada jogador
-- (campo Ranking, regras em Shared/Data/RankRules), copia para o placar global
-- (um DataStore ordenado por categoria, escopo = semana) e responde ao
-- cliente com o top da categoria (Net.RequestRanking → Net.RankingData).
--
-- Fontes: LifeService (fim de vida: pontos, dias, XP), DeathService (golpe
-- final em jogador) e MobService (mob morto).
-- Gravação: as categorias que mudaram ficam marcadas e vão ao placar a cada
-- RankConfig.WRITE_MIN_INTERVAL, na hora no fim da vida e ao sair. Uma
-- gravação por jogador de cada vez; o valor é lido do perfil na hora de
-- gravar e a marca sai antes (se a gravação falhar, volta), então nada
-- contado durante a espera se perde nem um valor velho cobre um novo.
-- Na virada da semana, o que a semana velha ainda devia ao placar é gravado
-- no escopo dela antes de zerar (RankRules.rollover).
-- Servidor VIP (RankRules.counts) não conta: nem soma nem grava.
-- Leitura: top RankConfig.READ_SIZE por categoria, com cache de
-- RankConfig.CACHE_SECONDS; nomes (DisplayName) em cache também.
-- Spec: docs/superpowers/specs/2026-11-09-ranking-semanal-design.md.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserService = game:GetService("UserService")

local RankConfig = require(ReplicatedStorage.Shared.Data.RankConfig)
local RankRules = require(ReplicatedStorage.Shared.Data.RankRules)
local Net = require(script.Parent.Parent.Net)
local DataService = require(script.Parent.DataService)

type Entry = { UserId: number, Name: string, Value: number }
type Top = { ok: boolean, entries: { Entry }, at: number }

local RankService = {}

local IN_STUDIO = RunService:IsStudio()

-- Categorias que mudaram desde a última gravação no placar, por jogador.
local dirty: { [Player]: { [string]: boolean } } = {}
-- O que semanas velhas ainda devem ao placar (virada com marcas pendentes).
local owed: { [Player]: { RankRules.Owed } } = {}
-- Gravação em andamento por jogador, e se pediram outra durante ela.
local flushing: { [Player]: boolean } = {}
local flushAgain: { [Player]: boolean } = {}
local lastWrite: { [Player]: number } = {}
local lastRequest: { [Player]: number } = {}
local pendingRequest: { [Player]: number } = {}
-- Top lido por "categoria|semana".
local tops: { [string]: Top } = {}
local names: { [number]: string } = {}

local COUNTS_HERE = RankRules.counts(game.PrivateServerOwnerId)

local function store(category: string, week: number): OrderedDataStore
	return DataStoreService:GetOrderedDataStore(RankRules.storeName(category, IN_STUDIO), RankRules.weekScope(week))
end

local flush: (player: Player) -> ()

-- Estado da semana atual do jogador (já trocado no perfil se a semana virou),
-- ou nil sem perfil carregado. Na virada, guarda o que a semana velha devia.
function RankService.state(player: Player): RankRules.WeekState?
	local data = DataService.data(player)
	if data == nil then
		return nil
	end
	local week = RankRules.weekIndex(os.time())
	local raw = data.Ranking
	local turned = type(raw) ~= "table" or raw.Week ~= week
	local state, debt = RankRules.rollover(raw, week, if turned then dirty[player] else nil)
	data.Ranking = state
	if turned then
		-- As marcas eram da semana velha: viram dívida (gravada no escopo dela).
		dirty[player] = nil
		if debt then
			owed[player] = owed[player] or {}
			table.insert(owed[player], debt)
			task.spawn(flush, player)
		end
	end
	return state
end

local function markDirty(player: Player, categories: { string })
	if #categories == 0 then
		return
	end
	local set = dirty[player]
	if set == nil then
		set = {}
		dirty[player] = set
	end
	for _, category in categories do
		set[category] = true
	end
end

local function write(player: Player, category: string, week: number, value: number): boolean
	local ok, err = pcall(function()
		store(category, week):SetAsync(tostring(player.UserId), value)
	end)
	if not ok then
		warn(`[RankService] gravar {category} de {player.Name}: {err}`)
	end
	return ok
end

-- Uma passada: primeiro as dívidas de semanas velhas, depois as marcas da
-- semana atual. `data` é a tabela do perfil pega no começo (continua válida
-- mesmo se o perfil fechar durante a espera, na saída do jogador).
local function flushOnce(player: Player, data: any)
	local debts = owed[player]
	if debts then
		owed[player] = nil
		for _, debt in debts do
			for category, value in debt.values do
				if not write(player, category, debt.week, value) then
					-- Tenta de novo na próxima passada.
					owed[player] = owed[player] or {}
					table.insert(owed[player], { week = debt.week, values = { [category] = value } })
				end
			end
		end
	end
	local set = dirty[player]
	if set == nil then
		return
	end
	dirty[player] = nil -- marcas novas durante a espera ficam numa tabela nova
	for category in set do
		local raw = data.Ranking
		if type(raw) ~= "table" or type(raw.Week) ~= "number" then
			return
		end
		local state = RankRules.current(raw, raw.Week)
		if not write(player, category, state.Week, (state :: any)[category]) then
			markDirty(player, { category })
		end
	end
end

-- Grava o que falta do jogador. Uma gravação por jogador de cada vez: pedida
-- durante outra, roda de novo logo depois dela.
flush = function(player: Player)
	if not COUNTS_HERE then
		dirty[player] = nil
		owed[player] = nil
		return
	end
	if flushing[player] then
		flushAgain[player] = true
		return
	end
	local data = DataService.data(player)
	if data == nil then
		return
	end
	flushing[player] = true
	lastWrite[player] = os.clock()
	repeat
		flushAgain[player] = nil
		flushOnce(player, data)
	until not flushAgain[player]
	flushing[player] = nil
end

-- Fim de uma vida: pontos e dias da vida (melhor da semana) e o XP ganho.
-- Grava na hora (fim de vida é raro).
function RankService.addLife(player: Player, life: { points: number, days: number, xp: number })
	if not COUNTS_HERE then
		return
	end
	local state = RankService.state(player)
	if state == nil then
		return
	end
	markDirty(player, RankRules.applyLife(state, life))
	task.spawn(flush, player)
end

-- Um abate de `killer`: "players" (golpe final em jogador; victimKey = UserId
-- da vítima) ou "creatures" (mob; sem vítima).
function RankService.addKill(killer: Player, category: RankRules.Category, victimKey: string?)
	if not COUNTS_HERE then
		return
	end
	local state = RankService.state(killer)
	if state == nil then
		return
	end
	local now = os.time()
	local counted =
		RankRules.applyKill(state, category, victimKey, RankRules.dayIndex(now), RankConfig.SAME_VICTIM_DAILY_LIMIT)
	if counted then
		markDirty(killer, { category })
	end
end

-- DisplayName de cada id (cache; "@<id>" se o Roblox não devolver).
local function resolveNames(ids: { number })
	local missing = {}
	for _, id in ids do
		if names[id] == nil then
			table.insert(missing, id)
		end
	end
	if #missing == 0 then
		return
	end
	local ok, infos = pcall(function()
		return UserService:GetUserInfosByUserIdsAsync(missing)
	end)
	if ok and type(infos) == "table" then
		for _, info in infos do
			names[info.Id] = string.sub(info.DisplayName, 1, 40)
		end
	end
	for _, id in missing do
		if names[id] == nil then
			names[id] = string.sub("@" .. tostring(id), 1, 40)
		end
	end
end

-- Top da categoria na semana, do cache se ainda vale.
local function readTop(category: string, week: number): Top
	local key = category .. "|" .. tostring(week)
	local cached = tops[key]
	if cached and cached.ok and os.clock() - cached.at < RankConfig.CACHE_SECONDS then
		return cached
	end
	local ok, page = pcall(function()
		return store(category, week):GetSortedAsync(false, RankConfig.READ_SIZE):GetCurrentPage()
	end)
	if not ok then
		warn(`[RankService] ler {category}: {page}`)
		local failed = { ok = false, entries = if cached then cached.entries else {}, at = os.clock() }
		return failed
	end
	local entries: { Entry } = {}
	local ids = {}
	for _, item in page :: any do
		local id = tonumber(item.key)
		if id and type(item.value) == "number" and item.value > 0 then
			table.insert(entries, { UserId = id, Name = "", Value = item.value })
			table.insert(ids, id)
		end
	end
	resolveNames(ids)
	for _, entry in entries do
		entry.Name = names[entry.UserId] or ""
	end
	local top = { ok = true, entries = entries, at = os.clock() }
	tops[key] = top
	return top
end

local function answer(player: Player, index: number)
	lastRequest[player] = os.clock()
	local category = RankConfig.CATEGORIES[index]
	if category == nil then
		return
	end
	local week = RankRules.weekIndex(os.time())
	local top = readTop(category, week)
	local state = RankService.state(player)
	local myValue = if state then math.clamp((state :: any)[category], 0, 4294967295) else 0
	-- O top pode estar alguns minutos atrás (cache): quem pede se vê com o valor
	-- atual, no lugar certo (a posição nunca contradiz o valor).
	local merged, position = RankRules.withPlayer(
		top.entries,
		player.UserId,
		string.sub(player.DisplayName, 1, 40),
		myValue,
		RankConfig.READ_SIZE
	)
	local list = {}
	for i = 1, math.min(#merged, RankConfig.LIST_SIZE) do
		list[i] = merged[i]
	end
	Net.RankingData.Fire(player, {
		Category = index,
		Ok = top.ok,
		EndsAt = RankRules.weekEnd(week),
		Entries = list,
		MyValue = myValue,
		MyPosition = math.min(position, 65535),
	})
end

-- Pedido do cliente. Dentro do intervalo mínimo não é jogado fora: espera a
-- vez e responde o último pedido (troca rápida de aba não fica "Carregando…").
local function onRequest(player: Player, index: number)
	local wait = RankRules.requestDelay(lastRequest[player], os.clock(), RankConfig.REQUEST_MIN_INTERVAL)
	if wait <= 0 and pendingRequest[player] == nil then
		answer(player, index)
		return
	end
	local scheduled = pendingRequest[player] ~= nil
	pendingRequest[player] = index
	if not scheduled then
		task.delay(math.max(wait, 0), function()
			local latest = pendingRequest[player]
			pendingRequest[player] = nil
			if latest and player.Parent == Players then
				answer(player, latest)
			end
		end)
	end
end

-- Moderação: tira `userId` do placar da semana `week` (padrão: a atual) em
-- todas as categorias e zera o perfil se estiver online. Devolve um resumo.
function RankService.removeFromWeek(userId: number, week: number?): string
	local target = week or RankRules.weekIndex(os.time())
	local removed = {}
	for _, category in RankConfig.CATEGORIES do
		local ok, err = pcall(function()
			store(category, target):RemoveAsync(tostring(userId))
		end)
		table.insert(removed, if ok then category else `{category} (falhou: {err})`)
		tops[category .. "|" .. tostring(target)] = nil
	end
	local player = Players:GetPlayerByUserId(userId)
	local data = player and DataService.data(player)
	if player and data and type(data.Ranking) == "table" and data.Ranking.Week == target then
		data.Ranking = RankRules.empty(target)
		dirty[player] = nil
	end
	return `semana {target}: {table.concat(removed, ", ")}`
end

-- Só para teste no Studio: esquece o cache do top (a próxima leitura vai ao placar).
function RankService.clearCache()
	table.clear(tops)
end

function RankService.Start(_self)
	Net.RequestRanking.On(onRequest)
	-- Antes do último save do perfil (saída ou desligamento): o perfil ainda
	-- está aberto aqui; no PlayerRemoving o DataService já o fechou.
	DataService.onUnloading(function(player: Player)
		task.spawn(flush, player)
	end)
	Players.PlayerRemoving:Connect(function(player)
		dirty[player] = nil
		lastWrite[player] = nil
		lastRequest[player] = nil
		pendingRequest[player] = nil
	end)
	-- Desligamento: o onUnloading já disparou as gravações; espera elas
	-- terminarem (o servidor fica de pé até ~30 s).
	game:BindToClose(function()
		local deadline = os.clock() + 25
		while next(flushing) ~= nil and os.clock() < deadline do
			task.wait(0.2)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(5)
			local now = os.clock()
			for player in dirty do
				if now - (lastWrite[player] or 0) >= RankConfig.WRITE_MIN_INTERVAL then
					task.spawn(flush, player)
				end
			end
		end
	end)
end

return RankService
