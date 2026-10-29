--!strict
-- Golden Ember (moeda salva no perfil). Função única para TODA mudança de saldo:
-- ninguém mexe em data.Currency direto. As regras (tetos, validação) ficam em
-- Shared/Data/CurrencyRules; aqui só aplica no perfil e publica o saldo no
-- atributo Currency do Player (a HUD/loja da F5 lê dali).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local StatNames = require(ReplicatedStorage.Shared.StatNames)
local CurrencyRules = require(ReplicatedStorage.Shared.Data.CurrencyRules)
local DataService = require(script.Parent.DataService)

local IS_STUDIO = RunService:IsStudio()

local CurrencyService = {}

local function currencyOf(player: Player): CurrencyRules.CurrencyData?
	local data = DataService.data(player)
	return if data then data.Currency else nil
end

local function publish(player: Player, currency: CurrencyRules.CurrencyData)
	player:SetAttribute(StatNames.Currency, currency.Balance)
end

-- `reason` só vai para o log do Studio (não é salvo): ajuda a achar de onde
-- veio cada mudança enquanto a gente testa.
local function log(player: Player, change: string, reason: string, balance: number)
	if IS_STUDIO then
		print(`[CurrencyService] {player.Name}: {change} ({reason}) → saldo {balance}`)
	end
end

-- Saldo atual (0 sem perfil carregado).
function CurrencyService.balance(player: Player): number
	local currency = currencyOf(player)
	return if currency then currency.Balance else 0
end

-- Ganho vindo do jogo (fim de vida, prêmios de gameplay): com teto por hora.
-- Devolve quanto foi concedido de fato.
function CurrencyService.earnFromGameplay(player: Player, amount: number, reason: string): number
	local currency = currencyOf(player)
	if currency == nil then
		return 0
	end
	local granted = CurrencyRules.earn(currency, amount, os.time())
	publish(player, currency)
	log(player, `+{granted} de {amount}`, reason, currency.Balance)
	return granted
end

-- Sem tetos: compras com Robux e comandos de dev.
function CurrencyService.grant(player: Player, amount: number, reason: string): boolean
	local currency = currencyOf(player)
	if currency == nil or not CurrencyRules.grant(currency, amount) then
		return false
	end
	publish(player, currency)
	log(player, `+{amount}`, reason, currency.Balance)
	return true
end

-- Gasta se houver saldo (false e nada muda se não houver).
function CurrencyService.spend(player: Player, amount: number, reason: string): boolean
	local currency = currencyOf(player)
	if currency == nil or not CurrencyRules.spend(currency, amount) then
		return false
	end
	publish(player, currency)
	log(player, `-{amount}`, reason, currency.Balance)
	return true
end

function CurrencyService.Start(_self)
	DataService.onLoaded(function(player, data)
		publish(player, data.Currency)
	end)
end

return CurrencyService
