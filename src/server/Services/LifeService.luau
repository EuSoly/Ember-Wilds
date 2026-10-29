--!strict
-- Vida e fim de vida (só a contabilidade). Uma vida começa quando o personagem
-- nasce; o fim de vida converte os pontos (Score) em Golden Ember, atualiza as
-- estatísticas, zera os pontos e salva o perfil.
--
-- - Uma vez por vida (LifeRules): morreu e saiu, ou PlayerRemoving e
--   desligamento juntos, contam uma vez só. A próxima vida começa no próximo
--   CharacterAdded.
-- - NÃO limpa inventário/status nem faz renascer: isso é da morte de verdade
--   (fases G, que chamam endLife ao morrer).
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

local lives: { [Player]: LifeRules.Life } = {}

-- Pontos da vida atual: número finito e não negativo, senão 0.
local function readScore(player: Player): number
	local score = player:GetAttribute(StatNames.Score)
	if type(score) ~= "number" or score ~= score or score < 0 or score == math.huge then
		return 0
	end
	return score
end

-- Fim de vida (as fases G chamam ao morrer). Já terminada = não faz nada.
function LifeService.endLife(player: Player)
	local seconds = LifeRules.finish(lives[player], os.clock())
	if seconds == nil then
		return
	end
	local score = readScore(player)
	CurrencyService.earnFromGameplay(player, CurrencyRules.pointsToCurrency(score), "life_end")
	if score > 0 then
		StatsService.add(player, "score_total", score)
	end
	StatsService.record(player, "score_best", score)
	StatsService.record(player, "days_best", LifeRules.daysSurvived(seconds))
	StatsService.add(player, "deaths", 1)
	player:SetAttribute(StatNames.Score, 0)
	DataService.save(player)
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
end

return LifeService
