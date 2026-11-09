--!strict
-- Ranking semanal (UI 6): guarda no perfil o valor da semana de cada jogador
-- (campo Ranking, regras em Shared/Data/RankRules) e marca as categorias que
-- mudaram, para irem ao placar global (DataStore ordenado por categoria e
-- semana). As fontes chamam daqui: LifeService (fim de vida: pontos, dias,
-- XP), DeathService (golpe final em jogador) e MobService (mob morto).
-- Spec: docs/superpowers/specs/2026-11-09-ranking-semanal-design.md.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RankConfig = require(ReplicatedStorage.Shared.Data.RankConfig)
local RankRules = require(ReplicatedStorage.Shared.Data.RankRules)
local DataService = require(script.Parent.DataService)

local RankService = {}

-- Categorias que mudaram desde a última gravação no placar, por jogador.
local dirty: { [Player]: { [string]: boolean } } = {}

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

-- Categorias pendentes de gravação (a gravação limpa com clearDirty).
function RankService.dirtyOf(player: Player): { [string]: boolean }?
	return dirty[player]
end

function RankService.clearDirty(player: Player)
	dirty[player] = nil
end

-- Fim de uma vida: pontos e dias da vida (melhor da semana) e o XP ganho.
function RankService.addLife(player: Player, life: { points: number, days: number, xp: number })
	local state = RankService.state(player)
	if state == nil then
		return
	end
	markDirty(player, RankRules.applyLife(state, life))
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

function RankService.forget(player: Player)
	dirty[player] = nil
end

return RankService
