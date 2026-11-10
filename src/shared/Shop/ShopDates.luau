--!strict
-- Datas dos pacotes da loja (puro, roda no Lune e no Roblox). Quem edita os
-- pacotes escreve "AAAA-MM-DD HH:MM" no horário de Brasília; aqui vira o
-- instante unix (UTC). Sem DateTime/os.time: a conta é feita na mão para dar
-- o mesmo resultado em qualquer fuso do computador que rodar.
local ShopDates = {}

-- Brasília: UTC−3 fixo (o Brasil não tem horário de verão desde 2019).
ShopDates.UTC_OFFSET_HOURS = -3

local function isLeap(year: number): boolean
	return (year % 4 == 0 and year % 100 ~= 0) or year % 400 == 0
end

local MONTH_DAYS = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

local function daysInMonth(year: number, month: number): number
	if month == 2 and isLeap(year) then
		return 29
	end
	return MONTH_DAYS[month]
end

-- Dias de 1970-01-01 até o começo da data (anos ≥ 1970).
local function daysSinceEpoch(year: number, month: number, day: number): number
	local days = 0
	for y = 1970, year - 1 do
		days += if isLeap(y) then 366 else 365
	end
	for m = 1, month - 1 do
		days += daysInMonth(year, m)
	end
	return days + day - 1
end

-- "2026-11-09 18:00" (Brasília) → unix (UTC). nil se o texto estiver fora do
-- formato ou a data não existir (mês 13, 30 de fevereiro, 24:00…).
function ShopDates.parse(text: string): number?
	local y, mo, d, h, mi = string.match(text, "^(%d%d%d%d)%-(%d%d)%-(%d%d) (%d%d):(%d%d)$")
	if y == nil then
		return nil
	end
	local year, month, day = tonumber(y) :: number, tonumber(mo) :: number, tonumber(d) :: number
	local hour, minute = tonumber(h) :: number, tonumber(mi) :: number
	if year < 1970 or month < 1 or month > 12 or day < 1 or day > daysInMonth(year, month) then
		return nil
	end
	if hour > 23 or minute > 59 then
		return nil
	end
	local local_ = daysSinceEpoch(year, month, day) * 86400 + hour * 3600 + minute * 60
	return local_ - ShopDates.UTC_OFFSET_HOURS * 3600
end

-- Aberto em `now`? Começo incluso, fim excluso; sem data = sem limite daquele lado.
function ShopDates.isOpen(startsAt: number?, endsAt: number?, now: number): boolean
	if startsAt ~= nil and now < startsAt then
		return false
	end
	if endsAt ~= nil and now >= endsAt then
		return false
	end
	return true
end

return ShopDates
