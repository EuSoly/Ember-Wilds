--!strict
-- Formato das missões no perfil (campo Missions) e a leitura segura dele.
-- Diárias e semanais guardam o sorteio do período e, por missão, o valor da
-- estatística no sorteio (Base: progresso = atual − Base) e a melhor vida do
-- período (Best, para as missões de vida). Conquistas guardam o último nível
-- resgatado (0–3). A Partida (chrono quests) não salva: vale só na vida.
local StatsRules = require("../Data/StatsRules")
local MissionConfig = require("./MissionConfig")
local Types = require("../Defs/Types")

-- LifeKey: a vida em andamento no sorteio (só missões de vida). O que essa vida
-- já tinha (Base) não conta; outra vida conta inteira.
export type SlotSave = { Id: string, Base: number, Best: number, Claimed: boolean, LifeKey: string }
export type PeriodSave = {
	Index: number, -- dia (RankRules.dayIndex) ou semana (weekIndex) do sorteio; 0 = nunca
	Slots: { SlotSave },
	FinalReward: number, -- índice em MissionConfig.DAILY_FINAL (semanal: 0 = todos)
	FinalClaimed: boolean,
}
export type MissionsSave = {
	Daily: PeriodSave,
	Weekly: PeriodSave,
	Achievements: { [string]: number },
}

local MissionData = {}

local function emptyPeriod(): PeriodSave
	return { Index = 0, Slots = {}, FinalReward = 0, FinalClaimed = false }
end

-- Tabela nova a cada chamada (vai no ProfileTemplate).
function MissionData.empty(): MissionsSave
	return { Daily = emptyPeriod(), Weekly = emptyPeriod(), Achievements = {} }
end

local function count(value: any): number
	if type(value) ~= "number" or value ~= value or value < 0 or value == math.huge then
		return 0
	end
	return math.floor(value)
end

local function cleanPeriod(raw: any, defs: Types.DefsTables, finalCount: number, period: string): PeriodSave
	if type(raw) ~= "table" then
		return emptyPeriod()
	end
	local result = emptyPeriod()
	result.Index = count(raw.Index)
	if type(raw.Slots) == "table" then
		local seen: { [string]: boolean } = {}
		for _, slot in raw.Slots do
			local def = if type(slot) == "table" and type(slot.Id) == "string" then defs.Missions[slot.Id] else nil
			-- Só missões deste período, uma vez cada (fica a primeira).
			if def ~= nil and def.period == period and not seen[slot.Id] then
				seen[slot.Id] = true
				table.insert(result.Slots, {
					Id = slot.Id,
					Base = count(slot.Base),
					Best = count(slot.Best),
					Claimed = slot.Claimed == true,
					LifeKey = if type(slot.LifeKey) == "string" then slot.LifeKey else "",
				})
			end
		end
	end
	local final = count(raw.FinalReward)
	result.FinalReward = if final >= 1 and final <= finalCount then final elseif finalCount > 0 then 1 else 0
	result.FinalClaimed = raw.FinalClaimed == true
	return result
end

-- O Missions guardado, consertado: tipos errados viram vazio, missões e
-- conquistas que saíram de Defs somem, números quebrados viram 0, nível de
-- conquista fica entre 0 e 3.
function MissionData.sanitize(raw: any, defs: Types.DefsTables): MissionsSave
	local save = MissionData.empty()
	if type(raw) ~= "table" then
		return save
	end
	save.Daily = cleanPeriod(raw.Daily, defs, #MissionConfig.DAILY_FINAL, "daily")
	save.Weekly = cleanPeriod(raw.Weekly, defs, 0, "weekly")
	if type(raw.Achievements) == "table" then
		for id, level in raw.Achievements do
			if type(id) == "string" and defs.Achievements[id] ~= nil then
				local tier = math.min(count(level), #defs.Achievements[id].tiers)
				if tier > 0 then
					save.Achievements[id] = tier
				end
			end
		end
	end
	return save
end

-- Leitor de estatística para as regras: track com key = valor da chave; sem
-- key = total (soma das chaves numa keyed). Estatística desconhecida = 0.
function MissionData.statReader(stats: { [string]: any }, defs: Types.DefsTables): (Types.MissionTrack) -> number
	return function(track: Types.MissionTrack): number
		local def = if track.stat then defs.Stats[track.stat] else nil
		if def == nil then
			return 0
		end
		if track.key ~= nil then
			return StatsRules.get(stats, def, track.key)
		end
		return StatsRules.total(stats, def)
	end
end

return MissionData
