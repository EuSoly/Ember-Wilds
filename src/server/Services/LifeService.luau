--!strict
-- Vida e fim de vida (só a contabilidade). Uma vida começa quando o personagem
-- nasce; o fim de vida converte os pontos (Score) em Golden Ember, atualiza as
-- estatísticas, zera os pontos e salva o perfil.
--
-- - Uma vez por vida (LifeRules): morreu e saiu, ou PlayerRemoving e
--   desligamento juntos, contam uma vez só. A próxima vida começa no próximo
--   CharacterAdded.
-- - NÃO limpa inventário/status nem faz renascer: isso é da morte
--   (DeathService.kill, que chama endLife e usa o resumo devolvido).
-- - Sair do jogo e o servidor fechando contam como fim de vida (onUnloading).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local StatNames = require(ReplicatedStorage.Shared.StatNames)
local CurrencyRules = require(ReplicatedStorage.Shared.Data.CurrencyRules)
local LifeRules = require(ReplicatedStorage.Shared.Data.LifeRules)
local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local StatsService = require(script.Parent.StatsService)

local LifeService = {}

-- Resumo de uma vida terminada (tela de morte): pontos, dias vividos
-- (LifeRules.daysSurvived) e Golden Ember concedida de fato (depois dos tetos).
export type LifeSummary = { points: number, days: number, currency: number }

local lives: { [Player]: LifeRules.Life } = {}

-- Pontos da vida atual: número finito e não negativo, senão 0.
local function readScore(player: Player): number
	local score = player:GetAttribute(StatNames.Score)
	if type(score) ~= "number" or score ~= score or score < 0 or score == math.huge then
		return 0
	end
	return score
end

-- Fim de vida (DeathService.kill e a saída do jogo). Devolve o resumo, ou nil
-- se não havia vida ativa (já terminada) ou perfil carregado.
function LifeService.endLife(player: Player): LifeSummary?
	-- Sem perfil (carregando, falhou ou já fechou) não há onde contabilizar:
	-- a vida continua ativa e os pontos ficam, para não sumirem sem virar moeda.
	if DataService.data(player) == nil then
		if lives[player] ~= nil and lives[player].active then
			warn(`[LifeService] fim de vida de {player.Name} sem perfil carregado: ignorado`)
		end
		return nil
	end
	local seconds = LifeRules.finish(lives[player], os.clock())
	if seconds == nil then
		return nil
	end
	local score = readScore(player)
	local days = LifeRules.daysSurvived(seconds)
	local granted = CurrencyService.earnFromGameplay(player, CurrencyRules.pointsToCurrency(score), "life_end")
	if score > 0 then
		StatsService.add(player, "score_total", score)
	end
	StatsService.record(player, "score_best", score)
	StatsService.record(player, "days_best", days)
	StatsService.add(player, "deaths", 1)
	player:SetAttribute(StatNames.Score, 0)
	DataService.save(player)
	return { points = score, days = days, currency = granted }
end

local function startLifeIfNone(player: Player)
	local life = lives[player]
	if life == nil or not life.active then
		lives[player] = LifeRules.start(os.clock())
	end
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function()
		startLifeIfNone(player)
	end)
	if player.Character then
		startLifeIfNone(player)
	end
end

function LifeService.Start(_self)
	-- Antes do último save: os pontos da vida viram moeda e estatísticas.
	DataService.onUnloading(function(player)
		LifeService.endLife(player)
		lives[player] = nil
	end)

	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	-- Também limpa aqui: sem perfil (falhou, reset de dev) o onUnloading não vem.
	-- task.defer: roda depois do onUnloading desta mesma saída.
	Players.PlayerRemoving:Connect(function(player)
		task.defer(function()
			lives[player] = nil
		end)
	end)
end

return LifeService
