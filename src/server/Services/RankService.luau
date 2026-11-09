--!strict
-- Ranking semanal (UI 6): guarda no perfil o valor da semana de cada jogador
-- (campo Ranking, regras em Shared/Data/RankRules), copia para o placar global
-- (um DataStore ordenado por categoria, escopo = semana) e responde ao
-- cliente com o top da categoria (Net.RequestRanking → Net.RankingData).
--
-- Fontes: LifeService (fim de vida: pontos, dias, XP), DeathService (golpe
-- final em jogador) e MobService (mob morto).
-- Gravação: as categorias que mudaram ficam "sujas" e vão ao placar a cada
-- RankConfig.WRITE_MIN_INTERVAL, na hora no fim da vida e ao sair. Uma
-- gravação que falha continua suja (tenta de novo no próximo ciclo).
-- Servidor VIP (PrivateServerOwnerId ~= 0) não grava no placar.
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
local lastWrite: { [Player]: number } = {}
local lastRequest: { [Player]: number } = {}
-- Top lido por "categoria|semana".
local tops: { [string]: Top } = {}
local names: { [number]: string } = {}

local function canWrite(): boolean
	return game.PrivateServerOwnerId == 0
end

local function store(category: string, week: number): OrderedDataStore
	return DataStoreService:GetOrderedDataStore(RankRules.storeName(category, IN_STUDIO), RankRules.weekScope(week))
end

-- Estado da semana atual do jogador (já trocado no perfil se a semana virou),
-- ou nil sem perfil carregado.
function RankService.state(player: Player): RankRules.WeekState?
	local data = DataService.data(player)
	if data == nil then
		return nil
	end
	local week = RankRules.weekIndex(os.time())
	local state = RankRules.current(data.Ranking, week)
	data.Ranking = state
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

-- Grava no placar as categorias sujas do jogador, com os valores da semana
-- em que foram contadas (o perfil ainda guarda a semana dela, mesmo que a
-- semana tenha virado depois).
local function flush(player: Player)
	local set = dirty[player]
	local data = DataService.data(player)
	if set == nil or data == nil then
		return
	end
	if not canWrite() then
		dirty[player] = nil
		return
	end
	local raw = data.Ranking
	if type(raw) ~= "table" or type(raw.Week) ~= "number" then
		dirty[player] = nil
		return
	end
	local state = RankRules.current(raw, raw.Week)
	lastWrite[player] = os.clock()
	for category in set do
		local value = (state :: any)[category] :: number
		local ok, err = pcall(function()
			store(category, state.Week):SetAsync(tostring(player.UserId), value)
		end)
		if ok then
			set[category] = nil
		else
			warn(`[RankService] gravar {category} de {player.Name}: {err}`)
		end
	end
	if next(set) == nil then
		dirty[player] = nil
	end
end

-- Fim de uma vida: pontos e dias da vida (melhor da semana) e o XP ganho.
-- Grava na hora (fim de vida é raro).
function RankService.addLife(player: Player, life: { points: number, days: number, xp: number })
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

local function onRequest(player: Player, index: number)
	local now = os.clock()
	if lastRequest[player] and now - lastRequest[player] < RankConfig.REQUEST_MIN_INTERVAL then
		return
	end
	lastRequest[player] = now
	local category = RankConfig.CATEGORIES[index]
	if category == nil then
		return
	end
	-- O que acabou de mudar já vai para o placar antes de ler.
	if dirty[player] and dirty[player][category] then
		flush(player)
	end
	local week = RankRules.weekIndex(os.time())
	local top = readTop(category, week)
	local state = RankService.state(player)
	local list = {}
	for i = 1, math.min(#top.entries, RankConfig.LIST_SIZE) do
		list[i] = top.entries[i]
	end
	Net.RankingData.Fire(player, {
		Category = index,
		Ok = top.ok,
		EndsAt = RankRules.weekEnd(week),
		Entries = list,
		MyValue = if state then math.clamp((state :: any)[category], 0, 4294967295) else 0,
		MyPosition = math.min(RankRules.position(top.entries, player.UserId), 65535),
	})
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
	end)
	game:BindToClose(function()
		for player in dirty do
			flush(player)
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
