--!strict
-- Estatísticas permanentes do jogador (perfil salvo). Função única para somar
-- (add: counter/keyed) e registrar (record: max); as regras ficam em
-- Shared/Data/StatsRules. Não salva a cada mudança: o autosave, o fim de vida
-- e a saída gravam (limites do DataStore).
--
-- Também mede o tempo de jogo (playtime_seconds): soma o tempo desde a última
-- soma a cada save (autosave incluso, para não perder numa queda) e ao sair.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require(ReplicatedStorage.Shared.Defs)
local StatsRules = require(ReplicatedStorage.Shared.Data.StatsRules)
local DataService = require(script.Parent.DataService)

local PLAYTIME_STAT = "playtime_seconds"

type ChangedListener = (player: Player, statId: string, key: string?, value: number) -> ()

local StatsService = {}

local changedListeners: { ChangedListener } = {}
-- Instante (os.clock) da última soma de tempo de jogo, por jogador.
local lastPlaytimeAt: { [Player]: number } = {}

local function notifyChanged(player: Player, statId: string, key: string?, value: number)
	for _, listener in changedListeners do
		task.spawn(listener, player, statId, key, value)
	end
end

local function findDef(statId: string): Defs.StatDef?
	local def = Defs.Stats[statId]
	if def == nil then
		warn(`[StatsService] estatística "{statId}" não existe em Defs/Stats`)
	end
	return def
end

-- Soma em counter/keyed. Estatística desconhecida ou valor inválido: warn e ignora.
function StatsService.add(player: Player, statId: string, amount: number, key: string?)
	local def = findDef(statId)
	local data = DataService.data(player)
	if def == nil or data == nil then
		return
	end
	-- Chave de item precisa existir em Defs.Items (mob ainda não tem Defs: só o formato).
	if def.keyKind == "item" and key ~= nil and Defs.Items[key] == nil then
		warn(`[StatsService] item "{key}" não existe em Defs/Items (estatística "{statId}")`)
		return
	end
	local value = StatsRules.add(data.Stats, def, amount, key)
	if value == nil then
		warn(`[StatsService] soma inválida em "{statId}" (amount={amount}, key={key})`)
		return
	end
	notifyChanged(player, statId, key, value)
end

-- Registra em "max" (guarda o maior). Só avisa se o valor mudou de fato.
function StatsService.record(player: Player, statId: string, value: number)
	local def = findDef(statId)
	local data = DataService.data(player)
	if def == nil or data == nil then
		return
	end
	local stored, changed = StatsRules.record(data.Stats, def, value)
	if stored == nil then
		warn(`[StatsService] registro inválido em "{statId}" (value={value})`)
		return
	end
	if changed then
		notifyChanged(player, statId, nil, stored)
	end
end

-- Valor atual (0 sem perfil ou sem valor).
function StatsService.get(player: Player, statId: string, key: string?): number
	local def = Defs.Stats[statId]
	local data = DataService.data(player)
	if def == nil or data == nil then
		return 0
	end
	return StatsRules.get(data.Stats, def, key)
end

-- Aviso de mudança (player, statId, key?, novoValor): é aqui que conquistas e
-- maestria vão se ligar.
function StatsService.onChanged(listener: ChangedListener)
	table.insert(changedListeners, listener)
end

-- Soma o tempo desde a última soma e atualiza a marca.
local function flushPlaytime(player: Player)
	local last = lastPlaytimeAt[player]
	if last == nil then
		return
	end
	local now = os.clock()
	lastPlaytimeAt[player] = now
	local elapsed = now - last
	if elapsed > 0 then
		StatsService.add(player, PLAYTIME_STAT, elapsed)
	end
end

function StatsService.Start(_self)
	DataService.onLoaded(function(player)
		lastPlaytimeAt[player] = os.clock()
	end)
	DataService.onBeforeSave(function(player)
		flushPlaytime(player)
	end)
	DataService.onUnloading(function(player)
		flushPlaytime(player)
		lastPlaytimeAt[player] = nil
	end)
	-- Também limpa aqui: sem perfil (reset de dev) o onUnloading não vem.
	-- task.defer: roda depois do onUnloading desta mesma saída.
	Players.PlayerRemoving:Connect(function(player)
		task.defer(function()
			lastPlaytimeAt[player] = nil
		end)
	end)
end

return StatsService
