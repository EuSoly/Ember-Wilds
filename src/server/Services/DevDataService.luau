--!strict
-- SÓ PARA DESENVOLVIMENTO (roda apenas no Studio).
-- Comandos para testar os dados salvos (barra de comandos do Studio, lado servidor):
-- - ServerStorage.DevScore:Invoke(player, 12345): pontos da vida atual.
-- - ServerStorage.DevEndLife:Invoke(player): mata o jogador pela morte de
--   verdade (DeathService.kill, causa "death.cause.dev"): pontos → Golden Ember,
--   inventário zerado, personagem removido e tela de morte. Renascer = Jogar de novo.
-- - ServerStorage.DevCurrency:Invoke(player, 100) -> number: dá (positivo) ou
--   tira (negativo) Golden Ember, sem tetos; devolve o saldo.
-- - ServerStorage.DevStat:Invoke(player, "mobs_killed", 10, "cow"): soma numa estatística.
-- - ServerStorage.DevGrantCosmetic:Invoke(player, "body_lobo") -> boolean: dá a posse.
-- - ServerStorage.DevProfile:Invoke(player) -> string: o perfil atual em JSON.
-- - ServerStorage.DevResetProfile:Invoke(player) -> boolean: apaga o perfil de
--   dev (store Dev_) e expulsa o jogador.
-- - ServerStorage.DevBar:Invoke(player, "Hunger", 0): grava uma barra (Health,
--   Hunger, Cold, Thirst ou Heat), de 0 a 100, para testar a sobrevivência.
-- - ServerStorage.DevArmor:Invoke(player, "helmet") -> boolean: veste uma
--   armadura (category "armor"); nil tira.
-- - ServerStorage.DevGive:Invoke(player, { reidite_wall = 50, ... }) -> string:
--   põe os itens no inventário (vale item testOnly; o que não couber é avisado).
--   Atalho: DevGive:Invoke(player, "reidite") = 50 de cada build de reidite.
local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local ArmorService = require(script.Parent.ArmorService)
local CosmeticService = require(script.Parent.CosmeticService)
local CurrencyService = require(script.Parent.CurrencyService)
local DataService = require(script.Parent.DataService)
local DeathService = require(script.Parent.DeathService)
local InventoryService = require(script.Parent.InventoryService)
local StatsService = require(script.Parent.StatsService)

-- Pacotes prontos do DevGive (nome -> itens).
local GIVE_PRESETS: { [string]: { [string]: number } } = {
	reidite = {
		reidite_wall = 50,
		reidite_door = 50,
		reidite_spike = 50,
		reidite_spike_door = 50,
		reidite_extractor = 50,
	},
}

local DevDataService = {}

local function newCommand(name: string, onInvoke: (...any) -> ...any)
	local command = Instance.new("BindableFunction")
	command.Name = name
	command.OnInvoke = onInvoke
	command.Parent = ServerStorage
end

function DevDataService.Start(_self)
	if not RunService:IsStudio() then
		return
	end

	newCommand("DevScore", function(player: Player, points: number)
		player:SetAttribute(StatNames.Score, points)
	end)

	newCommand("DevEndLife", function(player: Player)
		DeathService.kill(player, "death.cause.dev")
	end)

	newCommand("DevCurrency", function(player: Player, amount: number): number
		if amount > 0 then
			CurrencyService.grant(player, amount, "dev")
		elseif amount < 0 then
			CurrencyService.spend(player, -amount, "dev")
		end
		return CurrencyService.balance(player)
	end)

	newCommand("DevStat", function(player: Player, statId: string, amount: number, key: string?)
		StatsService.add(player, statId, amount, key)
	end)

	newCommand("DevGrantCosmetic", function(player: Player, cosmeticId: string): boolean
		return CosmeticService.grantOwnership(player, cosmeticId)
	end)

	newCommand("DevProfile", function(player: Player): string
		return HttpService:JSONEncode(DataService.data(player))
	end)

	newCommand("DevResetProfile", function(player: Player): boolean
		return DataService.resetForDev(player)
	end)

	local bars = { StatNames.Health, StatNames.Hunger, StatNames.Cold, StatNames.Thirst, StatNames.Heat }
	newCommand("DevBar", function(player: Player, name: string, value: number)
		if not table.find(bars, name) or type(value) ~= "number" or value ~= value then
			warn(`[DevBar] use Health, Hunger, Cold, Thirst ou Heat com um número`)
			return
		end
		local max = if name == StatNames.Health then StatNames.HealthMax else StatNames.StatusMax
		player:SetAttribute(name, math.clamp(value, 0, max))
	end)

	newCommand("DevArmor", function(player: Player, itemId: string?): boolean
		return ArmorService.wear(player, itemId)
	end)

	newCommand("DevGive", function(player: Player, what: any): string
		local items = if type(what) == "string" then GIVE_PRESETS[what] else what
		if type(items) ~= "table" then
			return `[DevGive] use uma tabela {"{"} id = quantidade {"}"} ou um pacote pronto`
		end
		local report = {}
		for id, count in items do
			if Defs.Items[id] == nil or type(count) ~= "number" or count < 1 then
				table.insert(report, `{id}: não existe`)
				continue
			end
			local left = InventoryService.give(player, id, math.floor(count))
			table.insert(report, if left > 0 then `{id}: sobraram {left}` else `{id}: {count}`)
		end
		table.sort(report)
		return table.concat(report, ", ")
	end)
end

return DevDataService
