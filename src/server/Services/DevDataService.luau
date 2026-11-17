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
-- - ServerStorage.DevShopReset:Invoke(player) -> boolean: zera só a loja do
--   perfil (giros, kits para sempre, saldos de kit, compras, passes, VIP). O
--   que a vida atual já tinha (VIP, passes) vale até a próxima vida.
-- - ServerStorage.DevShopGrant:Invoke(player, { kind = "kit", id = "kit_veteran" })
--   -> "ok" ou o erro: dá qualquer recompensa da loja (kit, kitOnce com count,
--   spins, ember, cosmetic, pass, vip com count = dias, xpBoost com count =
--   segundos, reviveCredit com count), pelo mesmo caminho dos presentes/códigos.
--   Ex.: { kind = "vip", count = 30 }, { kind = "pass", id = "ember2x" }.
-- - ServerStorage.DevShopRevoke:Invoke(player, "kit", "kit_veteran") -> boolean:
--   tira um kit ou passe para sempre ("kit" ou "pass"), ou o VIP ("vip", sem
--   id). O VIP desta vida continua até a próxima morte.
-- - ServerStorage.DevBar:Invoke(player, "Hunger", 0): grava uma barra (Health,
--   Hunger, Cold, Thirst ou Heat), de 0 a 100, para testar a sobrevivência.
-- - ServerStorage.DevArmor:Invoke(player, "helmet") -> boolean: veste uma
--   armadura (category "armor"); nil tira.
-- - ServerStorage.DevGive:Invoke(player, { reidite_wall = 50, ... }) -> string:
--   põe os itens no inventário (vale item testOnly; o que não couber é avisado).
--   Atalho: DevGive:Invoke(player, "reidite") = 50 de cada build de reidite.
-- - ServerStorage.DevRankRemove:Invoke(userId, semana?) -> string: moderação do
--   ranking semanal: tira o jogador do placar da semana (padrão: a atual).
-- - ServerStorage.DevRankRefresh:Invoke(): esquece o cache do top (teste).
-- - ServerStorage.DevTutorialReset:Invoke(player) -> boolean: o perfil volta a
--   ter o tutorial pendente (e sem pop-up da roleta); vale na próxima vida.
-- - ServerStorage.DevTutorialDone:Invoke(player) -> boolean: dá o tutorial como
--   feito, sem prêmio (e encerra o desta vida).
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
local PerkService = require(script.Parent.PerkService)
local RankService = require(script.Parent.RankService)
local ShopService = require(script.Parent.ShopService)
local StatsService = require(script.Parent.StatsService)
local TutorialService = require(script.Parent.TutorialService)

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

	newCommand("DevTutorialReset", function(player: Player)
		return TutorialService.devReset(player)
	end)

	newCommand("DevTutorialDone", function(player: Player)
		return TutorialService.devDone(player)
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

	newCommand("DevShopReset", function(player: Player): boolean
		return ShopService.resetForDev(player)
	end)

	newCommand("DevShopGrant", function(player: Player, reward: { [string]: any }): string
		local ok, problem = ShopService.give(player, reward :: any, "dev")
		PerkService.refresh(player)
		return if ok then "ok" else tostring(problem)
	end)

	newCommand("DevShopRevoke", function(player: Player, kind: string, id: string?): boolean
		if kind == "vip" then
			return ShopService.revoke(player, "vip", "")
		end
		if (kind ~= "kit" and kind ~= "pass") or type(id) ~= "string" then
			return false
		end
		return ShopService.revoke(player, kind, id)
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

	newCommand("DevRankRemove", function(userId: number, week: number?): string
		if type(userId) ~= "number" then
			return "[DevRankRemove] use o UserId (número) e, se quiser, a semana"
		end
		return RankService.removeFromWeek(userId, week)
	end)

	newCommand("DevRankRefresh", function()
		RankService.clearCache()
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
