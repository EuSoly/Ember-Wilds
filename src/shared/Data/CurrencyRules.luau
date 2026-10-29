--!strict
-- Regras da moeda Golden Ember (puras, testadas no Lune). O CurrencyService
-- chama daqui; nenhuma outra parte mexe no saldo direto.
local DataConfig = require("./DataConfig")

export type CurrencyData = { Balance: number, HourWindowStart: number, HourEarned: number }

local CurrencyRules = {}

local function isFinite(value: number): boolean
	return value == value and value > -math.huge and value < math.huge
end

-- Quantias de moeda são sempre inteiras e não negativas: NaN, infinito,
-- fração ou negativo vindos de um bug nunca entram no saldo.
local function isValidAmount(amount: any): boolean
	return type(amount) == "number" and isFinite(amount) and amount >= 0 and amount % 1 == 0
end

-- Pontos de uma vida → moeda, já com o teto por vida.
function CurrencyRules.pointsToCurrency(points: number): number
	if type(points) ~= "number" or not isFinite(points) or points <= 0 then
		return 0
	end
	local amount = math.floor(points / DataConfig.POINTS_PER_CURRENCY)
	return math.min(amount, DataConfig.MAX_CURRENCY_PER_LIFE)
end

-- Ganho vindo do jogo: aplica o teto por hora e soma no saldo.
-- Devolve quanto foi concedido de fato (0 se inválido ou teto atingido).
function CurrencyRules.earn(data: CurrencyData, amount: number, now: number): number
	if not isValidAmount(amount) or amount == 0 then
		return 0
	end
	-- Janela fixa: começa no primeiro ganho e zera HOUR_SECONDS depois.
	if data.HourWindowStart == 0 or now - data.HourWindowStart >= DataConfig.HOUR_SECONDS then
		data.HourWindowStart = now
		data.HourEarned = 0
	end
	local granted = math.max(math.min(amount, DataConfig.MAX_CURRENCY_PER_HOUR - data.HourEarned), 0)
	data.HourEarned += granted
	data.Balance += granted
	return granted
end

-- Sem tetos (compras com Robux, comandos de dev).
function CurrencyRules.grant(data: CurrencyData, amount: number): boolean
	if not isValidAmount(amount) then
		return false
	end
	data.Balance += amount
	return true
end

-- Gasta se houver saldo; senão nada muda.
function CurrencyRules.spend(data: CurrencyData, amount: number): boolean
	if not isValidAmount(amount) or amount > data.Balance then
		return false
	end
	data.Balance -= amount
	return true
end

return CurrencyRules
