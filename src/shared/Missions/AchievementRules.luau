--!strict
-- Conquistas (puro, testado no Lune): progresso pelas estatísticas do perfil
-- (e pela vida atual nas de "uma vida só"), próximo nível resgatável e o
-- resgate, um nível por vez.
local MissionConfig = require("./MissionConfig")
local MissionData = require("./MissionData")
local Types = require("../Defs/Types")

type AchievementDef = Types.AchievementDef
type Reward = Types.MissionReward
type Read = (Types.MissionTrack) -> number
type LifeValue = (life: string) -> number -- "days" | "score"

local AchievementRules = {}

-- Valor da conquista: a estatística; nas de "uma vida só" (days_best,
-- score_best) também a vida atual, que ainda não entrou na estatística.
function AchievementRules.progress(def: AchievementDef, read: Read, lifeValue: LifeValue): number
	local value = read(def.track)
	local life = if def.track.stat then MissionConfig.LIFE_OF_STAT[def.track.stat] else nil
	if life then
		value = math.max(value, lifeValue(life))
	end
	return math.max(math.floor(value), 0)
end

-- O nível seguinte ao resgatado não tem prêmio ainda ("em breve")?
function AchievementRules.isSoon(def: AchievementDef, claimedTier: number): boolean
	local tier = def.tiers[claimedTier + 1]
	return tier ~= nil and #tier.rewards == 0
end

-- Nível que dá para resgatar agora (o seguinte ao resgatado, se o progresso
-- chegou nele e ele tem prêmio), ou nil.
function AchievementRules.claimable(def: AchievementDef, claimedTier: number, progress: number): number?
	local next = claimedTier + 1
	local tier = def.tiers[next]
	if tier == nil or #tier.rewards == 0 or progress < tier.target then
		return nil
	end
	return next
end

-- Resgata um nível: sobe 1 no perfil e devolve os prêmios dele.
function AchievementRules.claim(save: MissionData.MissionsSave, def: AchievementDef, progress: number): { Reward }?
	local claimed = save.Achievements[def.id] or 0
	local next = AchievementRules.claimable(def, claimed, progress)
	if next == nil then
		return nil
	end
	save.Achievements[def.id] = next
	return def.tiers[next].rewards
end

return AchievementRules
