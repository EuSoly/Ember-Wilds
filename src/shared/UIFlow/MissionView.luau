--!strict
-- O que a tela de Missões mostra a partir do retrato do servidor (Net.MissionsData):
-- bolinhas de prêmio por aba, tempo que falta, linha de topo e textos dos
-- cartões. Puro (testado no Lune); quem desenha é Screens/MissionsScreen.
local Strings = require("../Strings")
local Types = require("../Defs/Types")

export type Tab = "match" | "daily" | "weekly" | "achievements"
export type Badges = { match: number, daily: number, weekly: number, achievements: number, total: number }

local STATE_READY = 1
local LEVELS = 3

local MissionView = {}

local TABS: { Tab } = { "match", "daily", "weekly", "achievements" }
MissionView.TABS = table.freeze(TABS)

local function ready(cards: { any }): number
	local n = 0
	for _, card in cards do
		if card.State == STATE_READY then
			n += 1
		end
	end
	return n
end

-- Prêmios esperando o RESGATAR, por aba (e no total, para o botão).
function MissionView.badges(data: any?): Badges
	local b = { match = 0, daily = 0, weekly = 0, achievements = 0, total = 0 }
	if data == nil or data.Creative then
		return b
	end
	b.match = ready(data.Chrono)
	b.daily = ready(data.Daily) + (if data.DailyFinal.State == STATE_READY then 1 else 0)
	b.weekly = ready(data.Weekly) + (if data.WeeklyFinal.State == STATE_READY then 1 else 0)
	for _, achievement in data.Achievements do
		if achievement.Ready then
			b.achievements += 1
		end
	end
	b.total = b.match + b.daily + b.weekly + b.achievements
	return b
end

-- "1d 2h", "7h 12min", "45min", "45s".
function MissionView.timeLeft(seconds: number): string
	local s = math.max(math.floor(seconds), 0)
	local d, h, m = s // 86400, (s % 86400) // 3600, (s % 3600) // 60
	if d > 0 then
		return Strings.format("time.days_hours", { d = d, h = h })
	elseif h > 0 then
		return Strings.format("time.hours_minutes", { h = h, m = m })
	elseif m > 0 then
		return Strings.format("time.minutes", { m = m })
	end
	return Strings.format("time.seconds", { s = s })
end

-- Linha de cima da aba. `now` = os.time() nas diárias (EndsAt é unix).
function MissionView.tabHeader(tab: Tab, data: any?, now: number): string
	if data ~= nil and data.Creative then
		return Strings.get("missions.creative_off")
	end
	if tab == "match" then
		if data == nil or not data.InLife then
			return Strings.get("missions.enter_game")
		end
		return `{Strings.get("missions.only_this_life")} · {Strings.format("missions.day_n", { n = data.LifeDay })}`
	elseif tab == "daily" then
		if data == nil then
			return "" -- espera o primeiro retrato
		end
		local endsAt = data.DailyFinal.EndsAt
		return Strings.format("missions.renews_in", { time = MissionView.timeLeft(endsAt - now) })
	elseif tab == "weekly" then
		return Strings.get("missions.renews_sunday")
	end
	local claimed, total = 0, 0
	if data then
		for _, achievement in data.Achievements do
			claimed += achievement.Claimed
			total += LEVELS
		end
	end
	return `{claimed} / {total}`
end

function MissionView.progressText(card: any): string
	return `{card.Progress} / {card.Target}`
end

-- Nome da diária/semanal com o alvo ("Colete 200 madeira").
function MissionView.missionName(id: string, target: number): string
	return Strings.format("mission." .. id, { n = target })
end

-- Meta do próximo nível da conquista ("Colete 10000 madeira").
function MissionView.achievementGoal(id: string, target: number): string
	return Strings.format(`achievement.{id}.goal`, { n = target })
end

local function oneReward(reward: Types.MissionReward, defs: Types.DefsTables): string
	if reward.kind == "ember" then
		return Strings.format("missions.reward.ember", { n = reward.amount or 0 })
	elseif reward.kind == "spins" then
		return Strings.format("missions.reward.spins", { n = reward.count or 1 })
	elseif reward.kind == "kitOnce" then
		return Strings.get("missions.reward.kit_once")
	elseif reward.kind == "kit" then
		local kit = if reward.id then defs.Kits[reward.id] else nil
		return Strings.format("missions.reward.kit", { name = if kit then Strings.get(kit.nameKey) else "?" })
	elseif reward.kind == "cosmetic" then
		return Strings.get("missions.reward.skin")
	end
	return reward.kind
end

-- Texto do prêmio ("+40 Golden Ember", "1 uso de kit", "2 giros especiais + ...").
-- Lista vazia = nível ainda sem prêmio ("Em breve").
function MissionView.rewardText(rewards: { Types.MissionReward }, defs: Types.DefsTables): string
	if #rewards == 0 then
		return Strings.get("missions.soon")
	end
	local parts = {}
	for _, reward in rewards do
		table.insert(parts, oneReward(reward, defs))
	end
	return table.concat(parts, " + ")
end

-- Prêmio da chrono quest: o item e os pontos ("Gema verde · 7500 pts").
function MissionView.questReward(quest: Types.QuestDef, defs: Types.DefsTables): string
	local item = defs.Items[quest.rewardItem]
	local name = if item then Strings.get(item.nameKey) else ""
	return Strings.format("missions.reward.item_score", { item = name, n = quest.score })
end

-- Fração da barra de uma chrono quest pelo relógio (anda entre um retrato e
-- outro): pronta/resgatada = cheia; falhou = onde parou; senão, tempo passado
-- do prazo (Target = prazo em s, EndsAt = fim no relógio do servidor).
function MissionView.chronoFraction(card: any, serverNow: number): number
	if card.State == 1 or card.State == 2 then
		return 1
	end
	if card.Target <= 0 then
		return 0
	end
	if card.State == 3 then
		return math.clamp(card.Progress / card.Target, 0, 1)
	end
	return math.clamp((card.Target - (card.EndsAt - serverNow)) / card.Target, 0, 1)
end

-- Um prêmio na tela: ícone (kind; id do item/kit) e um texto curto ao lado.
export type Badge = {
	kind: "ember" | "spins" | "kit" | "cosmetic" | "item" | "score" | "soon",
	id: string?,
	text: string,
}

-- Prêmios de missão/conquista como ícones ("+40" com a moeda, "×1" com o giro...).
function MissionView.rewardBadges(rewards: { Types.MissionReward }, defs: Types.DefsTables): { Badge }
	if #rewards == 0 then
		return { { kind = "soon", text = Strings.get("missions.soon") } }
	end
	local list: { Badge } = {}
	for _, reward in rewards do
		if reward.kind == "ember" then
			table.insert(list, { kind = "ember", text = `+{reward.amount or 0}` })
		elseif reward.kind == "spins" then
			table.insert(list, { kind = "spins", text = `×{reward.count or 1}` })
		elseif reward.kind == "kitOnce" then
			table.insert(list, { kind = "kit", id = reward.id, text = `×{reward.count or 1}` })
		elseif reward.kind == "kit" then
			local kit = if reward.id then defs.Kits[reward.id] else nil
			table.insert(list, { kind = "kit", id = reward.id, text = if kit then Strings.get(kit.nameKey) else "" })
		elseif reward.kind == "cosmetic" then
			table.insert(list, { kind = "cosmetic", id = reward.id, text = Strings.get("missions.reward.skin") })
		end
	end
	return list
end

-- Prêmio da chrono quest: o item (ícone do item) e os pontos.
function MissionView.questBadges(quest: Types.QuestDef): { Badge }
	return {
		{ kind = "item", id = quest.rewardItem, text = "" },
		{ kind = "score", text = Strings.format("missions.reward.points", { n = quest.score }) },
	}
end

return MissionView
