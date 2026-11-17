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

-- Pontos de uma vida → moeda: floor(pontos / 1000 × multiplicador), sem teto.
-- Multiplicador inválido ou menor que 1 conta como 1.
function CurrencyRules.pointsToCurrency(points: number, multiplier: number): number
	if type(points) ~= "number" or not isFinite(points) or points <= 0 then
		return 0
	end
	local factor = multiplier
	if type(factor) ~= "number" or not isFinite(factor) or factor < 1 then
		factor = 1
	end
	return math.floor(points / DataConfig.POINTS_PER_CURRENCY * factor)
end

-- Ganho vindo do jogo: soma tudo no saldo, sem teto.
-- Devolve quanto foi concedido (0 se inválido). HourWindowStart/HourEarned
-- ficam no tipo e no perfil sem uso (sem migração).
function CurrencyRules.earn(data: CurrencyData, amount: number, _now: number): number
	if not isValidAmount(amount) or amount == 0 then
		return 0
	end
	data.Balance += amount
	return amount
end

-- Compras com Robux, comandos de dev.
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
