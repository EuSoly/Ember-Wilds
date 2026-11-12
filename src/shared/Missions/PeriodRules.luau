--!strict
-- Diárias e semanais (puro, testado no Lune): sorteio por jogador e período,
-- progresso, melhor vida, resgate e a final. Quem lê as estatísticas e a vida
-- atual é o MissionService (passa `read` e `lifeValue`).
local MissionConfig = require("./MissionConfig")
local MissionData = require("./MissionData")
local RankConfig = require("../Data/RankConfig")
local RankRules = require("../Data/RankRules")
local Rng = require("../World/Rng")
local Types = require("../Defs/Types")

type PeriodSave = MissionData.PeriodSave
type SlotSave = MissionData.SlotSave
type MissionDef = Types.MissionDef
type Reward = Types.MissionReward
type Read = (Types.MissionTrack) -> number
type LifeValue = (life: string) -> number -- "days" | "score"

export type Period = "daily" | "weekly"

local PeriodRules = {}

local function countOf(period: Period): number
	return if period == "daily" then MissionConfig.DAILY_COUNT else MissionConfig.WEEKLY_COUNT
end

-- Ids do banco do período, em ordem fixa (o sorteio não depende da ordem do pairs).
local function poolOf(period: Period, defs: Types.DefsTables): { string }
	local ids: { string } = {}
	for id, def in defs.Missions do
		if def.period == period then
			table.insert(ids, id)
		end
	end
	table.sort(ids)
	return ids
end

-- Semente do sorteio: mesma para o mesmo jogador e período. O UserId é
-- reduzido antes de multiplicar: ids grandes (≈ 9e9) passariam de 2^53 e dias
-- seguidos cairiam na mesma semente.
function PeriodRules.seedFor(userId: number, index: number, period: Period): number
	return (userId % 2 ^ 31) * 1000003 + index * (if period == "daily" then 1 else 7919)
end

-- Garante o sorteio do período `index`. Se o guardado é de outro período (ou
-- nunca houve), sorteia COUNT missões distintas (mesma semente para o mesmo
-- jogador e período: reconectar não muda), grava a base de cada estatística e
-- o prêmio da final. Devolve true se mudou.
function PeriodRules.ensure(
	save: PeriodSave,
	period: Period,
	index: number,
	userId: number,
	read: Read,
	defs: Types.DefsTables,
	lifeValue: LifeValue?,
	lifeKey: string?
): boolean
	if save.Index == index and #save.Slots > 0 then
		return false
	end
	local rng = Rng.new(PeriodRules.seedFor(userId, index, period))
	local pool = poolOf(period, defs)
	local picks = math.min(countOf(period), #pool)
	-- Fisher–Yates parcial: as `picks` primeiras posições viram o sorteio.
	for i = 1, picks do
		local j = rng:nextInteger(i, #pool)
		pool[i], pool[j] = pool[j], pool[i]
	end
	local slots: { SlotSave } = {}
	for i = 1, picks do
		local def = defs.Missions[pool[i]]
		local life = def.track.life
		-- Missão de vida: o que a vida em andamento já tem não conta.
		local base = 0
		local key = ""
		if life == nil then
			base = read(def.track)
		elseif lifeValue ~= nil and lifeKey ~= nil then
			base = math.floor(lifeValue(life))
			key = lifeKey
		end
		table.insert(slots, { Id = def.id, Base = base, Best = 0, Claimed = false, LifeKey = key })
	end
	save.Index = index
	save.Slots = slots
	save.FinalReward = if period == "daily" then rng:nextInteger(1, #MissionConfig.DAILY_FINAL) else 0
	save.FinalClaimed = false
	return true
end

-- Valor da vida atual para a missão: tira o que a vida já tinha no sorteio
-- (mesma vida, LifeKey); outra vida conta inteira.
local function lifeProgress(slot: SlotSave, life: string, lifeValue: LifeValue, lifeKey: string?): number
	local value = math.floor(lifeValue(life))
	if lifeKey ~= nil and slot.LifeKey ~= "" and lifeKey == slot.LifeKey then
		value -= slot.Base
	end
	return value
end

-- Progresso de uma missão do sorteio, entre 0 e o alvo. `lifeKey` = a vida em
-- andamento (LifeService), para não contar o que ela tinha antes do sorteio.
function PeriodRules.progress(
	slot: SlotSave,
	def: MissionDef,
	read: Read,
	lifeValue: LifeValue,
	lifeKey: string?
): number
	local value
	local life = def.track.life
	if life then
		value = math.max(slot.Best, lifeProgress(slot, life, lifeValue, lifeKey))
	else
		value = read(def.track) - slot.Base
	end
	return math.clamp(math.floor(value), 0, def.target)
end

-- Guarda a vida atual como melhor vida do período nas missões de vida.
-- Devolve true se algum Best subiu.
function PeriodRules.observeLife(
	save: PeriodSave,
	defs: Types.DefsTables,
	lifeValue: LifeValue,
	lifeKey: string?
): boolean
	local changed = false
	for _, slot in save.Slots do
		local def = defs.Missions[slot.Id]
		local life = def and def.track.life
		if life then
			local value = lifeProgress(slot, life, lifeValue, lifeKey)
			if value > slot.Best then
				slot.Best = value
				changed = true
			end
		end
	end
	return changed
end

local function slotOf(save: PeriodSave, id: string): SlotSave?
	for _, slot in save.Slots do
		if slot.Id == id then
			return slot
		end
	end
	return nil
end

-- A missão está completa e ainda não foi resgatada?
function PeriodRules.isReady(
	slot: SlotSave,
	def: MissionDef,
	read: Read,
	lifeValue: LifeValue,
	lifeKey: string?
): boolean
	return not slot.Claimed and PeriodRules.progress(slot, def, read, lifeValue, lifeKey) >= def.target
end

-- Resgata uma missão do sorteio: só completa e não resgatada. Devolve os prêmios.
function PeriodRules.claim(
	save: PeriodSave,
	id: string,
	defs: Types.DefsTables,
	read: Read,
	lifeValue: LifeValue,
	lifeKey: string?
): { Reward }?
	local slot = slotOf(save, id)
	local def = defs.Missions[id]
	if slot == nil or def == nil or not PeriodRules.isReady(slot, def, read, lifeValue, lifeKey) then
		return nil
	end
	slot.Claimed = true
	return def.rewards
end

-- Quantas missões do sorteio já foram resgatadas.
function PeriodRules.claimedCount(save: PeriodSave): number
	local n = 0
	for _, slot in save.Slots do
		if slot.Claimed then
			n += 1
		end
	end
	return n
end

-- A final libera com todas as missões do sorteio resgatadas.
function PeriodRules.finalReady(save: PeriodSave): boolean
	return #save.Slots > 0 and not save.FinalClaimed and PeriodRules.claimedCount(save) == #save.Slots
end

-- Prêmios da final do período (diária: o sorteado; semanal: todos).
function PeriodRules.finalRewards(save: PeriodSave, period: Period): { Reward }
	if period == "weekly" then
		return MissionConfig.WEEKLY_FINAL
	end
	local reward = MissionConfig.DAILY_FINAL[save.FinalReward] or MissionConfig.DAILY_FINAL[1]
	return { reward }
end

-- Resgata a final: só uma vez e só com tudo resgatado.
function PeriodRules.claimFinal(save: PeriodSave, period: Period): { Reward }?
	if not PeriodRules.finalReady(save) then
		return nil
	end
	save.FinalClaimed = true
	return PeriodRules.finalRewards(save, period)
end

-- Último segundo (unix) do período: diária = 23:59:59 de Brasília do dia;
-- semanal = domingo 23:59:59 (o mesmo corte do ranking).
function PeriodRules.endsAt(period: Period, index: number): number
	if period == "weekly" then
		return RankRules.weekEnd(index)
	end
	return (index + 1) * RankConfig.DAY_SECONDS - RankConfig.UTC_OFFSET - 1
end

-- Índice do período no instante (unix).
function PeriodRules.indexAt(period: Period, unixTime: number): number
	return if period == "weekly" then RankRules.weekIndex(unixTime) else RankRules.dayIndex(unixTime)
end

return PeriodRules
