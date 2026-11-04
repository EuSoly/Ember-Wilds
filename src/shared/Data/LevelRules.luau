--!strict
-- Nível e XP do jogador (puras, testadas no Lune). XP = pontos de cada vida,
-- somados no fim da vida (LifeService) na estatística xp_total; o nível não é
-- salvo, sai do XP por aqui (mudar a curva não estraga perfis).
--
-- Curva: subir do nível n para n+1 pede XP_STEP × n. Total para chegar ao
-- nível n = XP_STEP × n × (n − 1) / 2 (nível 2 = 1.000; 8 = 28.000; 10 = 45.000).
--
-- O ganho tem teto por hora (MAX_XP_PER_HOUR), com a janela salva no perfil em
-- data.Xp (sair e voltar não zera). O passe de batalha vai somar o mesmo XP
-- ganho numa trilha própria (escutando xp_total no StatsService).
local DataConfig = require("./DataConfig")

export type XpData = { Seeded: boolean, HourWindowStart: number, HourEarned: number }
export type Progress = { level: number, into: number, need: number }

local LevelRules = {}

local function isFinite(value: any): boolean
	return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

-- XP total para chegar ao nível `level` (nível 1 = 0).
function LevelRules.xpToReach(level: number): number
	return DataConfig.XP_STEP * level * (level - 1) / 2
end

-- Nível do XP total, quanto já tem dentro dele (`into`) e o tamanho do nível
-- inteiro (`need`). XP inválido conta como 0.
function LevelRules.progress(xp: number): Progress
	local total = if isFinite(xp) and xp > 0 then xp else 0
	-- Maior n com XP_STEP × n(n−1)/2 ≤ total (raiz da equação, depois ajuste
	-- de arredondamento para os dois lados).
	local level = math.max(1, math.floor((1 + math.sqrt(1 + 8 * total / DataConfig.XP_STEP)) / 2))
	while LevelRules.xpToReach(level + 1) <= total do
		level += 1
	end
	while level > 1 and LevelRules.xpToReach(level) > total do
		level -= 1
	end
	return { level = level, into = total - LevelRules.xpToReach(level), need = DataConfig.XP_STEP * level }
end

-- XP de uma vida: pontos arredondados para baixo, dentro do teto por hora.
-- Muta `data` (janela da hora) e devolve o XP concedido de fato.
function LevelRules.earn(data: XpData, points: number, now: number): number
	if not isFinite(points) or points < 1 then
		return 0
	end
	local amount = math.floor(points)
	-- Janela fixa: começa no primeiro ganho e zera HOUR_SECONDS depois.
	if data.HourWindowStart == 0 or now - data.HourWindowStart >= DataConfig.HOUR_SECONDS then
		data.HourWindowStart = now
		data.HourEarned = 0
	end
	local granted = math.max(math.min(amount, DataConfig.MAX_XP_PER_HOUR - data.HourEarned), 0)
	data.HourEarned += granted
	return granted
end

-- XP inicial de quem já jogou: uma vez por perfil, xp_total recebe o total de
-- pontos de todas as vidas (score_total), ficando com o maior. Devolve true se
-- semeou agora. Não passa pelo teto por hora.
function LevelRules.seed(data: XpData, stats: { [string]: any }): boolean
	if data.Seeded then
		return false
	end
	local current = if isFinite(stats.xp_total) then stats.xp_total else 0
	local score = if isFinite(stats.score_total) then stats.score_total else 0
	stats.xp_total = math.max(current, math.floor(score))
	data.Seeded = true
	return true
end

return LevelRules
