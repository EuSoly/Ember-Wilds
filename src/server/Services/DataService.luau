--!strict
-- Perfil salvo de cada jogador (ProfileStore): moeda, estatísticas, cosméticos
-- e configurações. Só existe no servidor; o cliente recebe o que precisa por
-- atributos do Player, publicados pelos serviços que usam o perfil.
--
-- - Abre a sessão do perfil ao entrar (com session lock: dois servidores nunca
--   mexem no mesmo perfil) e fecha ao sair; o ProfileStore faz o autosave.
-- - Avisa quando o perfil carregou (onLoaded), antes de cada save
--   (onBeforeSave) e uma vez antes do último save (onUnloading: saída ou
--   desligamento do servidor). Os serviços pequenos (moeda, estatísticas,
--   vida, configurações, cosméticos) se ligam nesses avisos.
-- - No Studio usa o store "Dev_PlayerData", para testes nunca sujarem o jogo
--   real. Sem acesso às APIs, o ProfileStore cai no modo Mock (nada é salvo).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local Strings = require(ReplicatedStorage.Shared.Strings)
local DataConfig = require(ReplicatedStorage.Shared.Data.DataConfig)
local Migrations = require(ReplicatedStorage.Shared.Data.Migrations)
local ProfileTemplate = require(ReplicatedStorage.Shared.Data.ProfileTemplate)
local ProfileStore = require(ServerScriptService:WaitForChild("ServerPackages"):WaitForChild("ProfileStore"))

type Data = { [string]: any }
type Profile = ProfileStore.Profile<Data>
type LoadedListener = (player: Player, data: Data) -> ()
type PlayerListener = (player: Player) -> ()

local DataService = {}

local store: ProfileStore.ProfileStore<Data>
local profiles: { [Player]: Profile } = {}
-- Jogadores cujo onUnloading já foi avisado (o último save pode vir da saída,
-- do desligamento ou de outro servidor tomando a sessão: só conta uma vez).
local unloadNotified: { [Player]: boolean } = {}
-- Sessões que nós mesmos encerramos (saída, reset de dev): não é "sessão tomada".
local endedByUs: { [Player]: boolean } = {}
-- Limite de saves pedidos (DataService.save): instante (os.clock) do último e
-- a thread do save agendado, por jogador.
local lastSaveAt: { [Player]: number } = {}
local pendingSave: { [Player]: thread } = {}
local warnedMock = false

local loadedListeners: { LoadedListener } = {}
local unloadingListeners: { PlayerListener } = {}
local beforeSaveListeners: { LoadedListener } = {}

-- Chama cada ouvinte numa thread própria, protegido: um serviço com erro não
-- derruba os outros. task.spawn roda na hora, então mudanças feitas por
-- ouvintes que não esperam (sem yield) entram no save que vem logo depois.
local function callAll(listeners: { any }, label: string, ...: any)
	for _, listener in listeners do
		task.spawn(function(...: any)
			local ok, err = pcall(listener, ...)
			if not ok then
				warn(`[DataService] erro num ouvinte de {label}: {err}`)
			end
		end, ...)
	end
end

local function notifyUnloading(player: Player)
	if unloadNotified[player] then
		return
	end
	unloadNotified[player] = true
	callAll(unloadingListeners, "onUnloading", player)
end

local function warnIfMock()
	if warnedMock or ProfileStore.DataStoreState == "Access" then
		return
	end
	warnedMock = true
	warn(
		"[DataService] sem acesso às APIs do Studio: usando perfil falso (nada é salvo). Ligue em Game Settings → Security."
	)
end

local function kickIfPresent(player: Player, key: string)
	if player.Parent == Players then
		player:Kick(Strings.get(key))
	end
end

-- Abre a sessão do perfil (roda numa thread própria: pode demorar).
local function loadProfile(player: Player)
	local key = DataConfig.KEY_PREFIX .. player.UserId
	-- Cancel: se o jogador sair enquanto carrega, o ProfileStore desiste.
	-- (O tipo exportado pelo pacote só declara Steal, por isso o cast.)
	local params: any = {
		Cancel = function(): boolean
			return player.Parent ~= Players
		end,
	}
	local profile = store:StartSessionAsync(key, params)
	warnIfMock()

	if profile == nil then
		kickIfPresent(player, "data.loadFailed")
		return
	end

	-- Tudo entre abrir a sessão e guardar o perfil roda protegido: um erro aqui
	-- não pode deixar uma sessão aberta "pendurada" (sem dono e sem EndSession).
	-- Devolve nil se deu tudo certo, ou a chave de Strings do kick.
	local ok, result = pcall(function(): string?
		-- Migração falhou: os dados não foram mexidos. "corrupt" precisa do
		-- suporte; o resto (versão mais nova, passo faltando ou com erro) pede
		-- para entrar de novo (num servidor atualizado).
		local migrated, reason = Migrations.run(profile.Data, Migrations.STEPS, DataConfig.SCHEMA_VERSION)
		if not migrated then
			if reason == "corrupt" then
				warn(
					`[DataService] perfil de {player.UserId} com SchemaVersion inválido ({profile.Data.SchemaVersion}): precisa do suporte`
				)
				return "data.corrupt"
			end
			warn(`[DataService] perfil de {player.UserId} não migrou: {reason}`)
			return "data.newerVersion"
		end

		profile:AddUserId(player.UserId) -- GDPR
		profile:Reconcile() -- campos novos do template (ex. configuração nova)

		-- Saiu durante o carregamento: fecha sem avisar ninguém.
		if player.Parent ~= Players then
			return ""
		end

		-- OnSave e OnLastSave disparam logo antes de gravar: o que os ouvintes
		-- mudarem sem esperar (sem yield) entra neste save.
		profile.OnSave:Connect(function()
			if profiles[player] == profile then
				callAll(beforeSaveListeners, "onBeforeSave", player, profile.Data)
			end
		end)
		profile.OnLastSave:Connect(function()
			notifyUnloading(player)
		end)
		profile.OnSessionEnd:Connect(function()
			if profiles[player] == profile then
				profiles[player] = nil
			end
			-- Outro servidor tomou a sessão: este não pode continuar mexendo no perfil.
			if not endedByUs[player] and not ProfileStore.IsClosing then
				kickIfPresent(player, "data.sessionTaken")
			end
		end)

		profiles[player] = profile
		return nil
	end)

	if not ok then
		warn(`[DataService] erro ao preparar o perfil de {player.UserId}: {result}`)
		result = "data.loadFailed"
	end
	if result ~= nil then
		-- Fechamos nós mesmos: não é "sessão tomada".
		endedByUs[player] = true
		profiles[player] = nil
		profile:EndSession()
		if result ~= "" and player.Parent == Players then
			-- O PlayerRemoving do kick limpa a marca endedByUs.
			player:Kick(Strings.get(result))
		else
			-- Já saiu (o PlayerRemoving já rodou): os sinais do EndSession são
			-- síncronos, então as marcas podem ser limpas aqui sem vazar.
			endedByUs[player] = nil
			unloadNotified[player] = nil
		end
		return
	end

	-- Antes dos ouvintes: a tela de carregamento e o pedido de nascer
	-- (SpawnService) esperam por esta marca.
	player:SetAttribute(StatNames.DataReady, true)
	callAll(loadedListeners, "onLoaded", player, profile.Data)
end

-- Dados do perfil, se está carregado e ativo (nil enquanto carrega ou depois de fechar).
function DataService.data(player: Player): Data?
	local profile = profiles[player]
	if profile == nil or not profile:IsActive() then
		return nil
	end
	return profile.Data
end

function DataService.onLoaded(listener: LoadedListener)
	table.insert(loadedListeners, listener)
end

-- Chamado UMA vez por jogador, antes do último save (saída ou desligamento).
function DataService.onUnloading(listener: PlayerListener)
	table.insert(unloadingListeners, listener)
end

-- Chamado a cada save (autosave incluso), antes de gravar.
function DataService.onBeforeSave(listener: LoadedListener)
	table.insert(beforeSaveListeners, listener)
end

-- Grava agora, se o perfil ainda está aberto. Durante o fechamento não faz
-- nada: o último save do ProfileStore já vai gravar tudo.
local function saveNow(player: Player)
	local profile = profiles[player]
	if profile == nil or unloadNotified[player] or not profile:IsActive() then
		return
	end
	lastSaveAt[player] = os.clock()
	profile:Save()
end

-- Pede um save (fim de vida, troca de cosmético). No máximo um a cada
-- MIN_SAVE_INTERVAL segundos por jogador: um pedido no meio da espera vira UM
-- save agendado para o fim dela (nunca mais de um pendente), para trocar de
-- skin várias vezes seguidas não estourar os limites do DataStore.
function DataService.save(player: Player)
	if profiles[player] == nil or pendingSave[player] then
		return
	end
	local last = lastSaveAt[player]
	local wait = if last then DataConfig.MIN_SAVE_INTERVAL - (os.clock() - last) else 0
	if wait <= 0 then
		saveNow(player)
		return
	end
	pendingSave[player] = task.delay(wait, function()
		pendingSave[player] = nil
		saveNow(player)
	end)
end

-- Cancela o save agendado e esquece o último instante (saída/reset).
local function clearSaveState(player: Player)
	local pending = pendingSave[player]
	if pending then
		task.cancel(pending)
	end
	pendingSave[player] = nil
	lastSaveAt[player] = nil
end

-- false quando o ProfileStore caiu no modo Mock (sem acesso às APIs).
function DataService.isUsingRealStore(): boolean
	return ProfileStore.DataStoreState == "Access"
end

-- SÓ Studio: apaga o perfil de dev do jogador (volta ao template) e o expulsa.
-- Não avisa onUnloading: o perfil apagado não deve ganhar uma morte nova.
function DataService.resetForDev(player: Player): boolean
	if not RunService:IsStudio() then
		return false
	end
	local profile = profiles[player]
	if profile == nil or not profile:IsActive() then
		return false
	end
	unloadNotified[player] = true
	endedByUs[player] = true
	clearSaveState(player)
	-- Mesma tabela que o ProfileStore guarda: troca o conteúdo, não a referência.
	local data = profile.Data :: Data
	table.clear(data)
	for key, value in ProfileTemplate.build(Defs) do
		data[key] = value
	end
	profiles[player] = nil
	profile:EndSession()
	player:Kick(Strings.get("data.devReset"))
	return true
end

function DataService.Init(_self)
	local storeName = if RunService:IsStudio()
		then DataConfig.DEV_STORE_PREFIX .. DataConfig.STORE_NAME
		else DataConfig.STORE_NAME
	store = ProfileStore.New(storeName, ProfileTemplate.build(Defs))
end

function DataService.Start(_self)
	Players.PlayerAdded:Connect(function(player)
		task.spawn(loadProfile, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(loadProfile, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		-- Sair do jogo conta como fim de vida: os ouvintes mexem no perfil antes
		-- do último save, que o EndSession dispara.
		notifyUnloading(player)
		endedByUs[player] = true
		-- O último save do EndSession grava tudo: o agendado não é mais preciso.
		clearSaveState(player)
		local profile = profiles[player]
		profiles[player] = nil
		if profile ~= nil then
			profile:EndSession()
		end
		-- Limpa as marcas depois que os sinais síncronos do EndSession rodaram.
		task.defer(function()
			unloadNotified[player] = nil
			endedByUs[player] = nil
		end)
	end)
end

return DataService
