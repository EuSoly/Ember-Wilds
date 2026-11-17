--!strict
-- Check-in de 7 dias no servidor: um prêmio por dia de Brasília
-- (RankRules.dayIndex). O cliente só pede (Net.CheckInClaim); quem confere o
-- dia, entrega (ShopService.give) e salva é daqui. As regras são puras
-- (Shop/CheckInRules).
--
-- CheckInDay / CheckInReady vão na pasta Player.Shop: o ShopService escreve ao
-- montar a pasta; aqui só republicamos na virada do dia (meia-noite de
-- Brasília) para quem está com o jogo aberto.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local StatNames = require(Shared.StatNames)
local RankRules = require(Shared.Data.RankRules)
local CheckInRules = require(Shared.Shop.CheckInRules)
local ShopData = require(Shared.Shop.ShopData)
local Throttle = require(Shared.Shop.Throttle)
local DataService = require(script.Parent.DataService)
local ShopService = require(script.Parent.ShopService)
local Net = require(script.Parent.Parent.Net)

-- Mesmo intervalo mínimo da loja (clique duplo, rajada).
local REQUEST_COOLDOWN = 0.3
-- De quanto em quanto tempo conferimos se o dia virou.
local DAY_WATCH_SECONDS = 20

local CheckInService = {}

local throttle = Throttle.new(REQUEST_COOLDOWN)

local function saveOf(player: Player): { Day: number, LastDay: number }?
	local data = DataService.data(player)
	if data == nil then
		return nil
	end
	return (data.Shop :: ShopData.ShopData).CheckIn
end

-- Resgata o prêmio de hoje. Devolve o dia resgatado (1..7) ou nil (já
-- resgatou hoje, sem perfil ou prêmio inválido: nada muda).
function CheckInService.claim(player: Player, now: number): number?
	local save = saveOf(player)
	if save == nil then
		return nil
	end
	local before = { Day = save.Day, LastDay = save.LastDay }
	local reward = CheckInRules.claim(save, RankRules.dayIndex(now))
	if reward == nil then
		return nil
	end
	-- give valida, entrega, republica e salva (já com o check-in avançado).
	local ok = ShopService.give(player, reward, "checkin")
	if not ok then
		save.Day, save.LastDay = before.Day, before.LastDay
		return nil
	end
	return before.Day
end

local function onClaim(player: Player)
	if not Throttle.allow(throttle, player, "checkin", os.clock()) then
		Net.CheckInResult.Fire(player, { Ok = false, Day = 0 })
		return
	end
	local day = CheckInService.claim(player, os.time())
	Net.CheckInResult.Fire(player, { Ok = day ~= nil, Day = day or 0 })
end

-- Quem está com o estado publicado de outro dia (a meia-noite passou) é republicado.
local function watchDayTurn()
	while true do
		task.wait(DAY_WATCH_SECONDS)
		local today = RankRules.dayIndex(os.time())
		for _, player in Players:GetPlayers() do
			local save = saveOf(player)
			local folder = player:FindFirstChild(StatNames.ShopFolder)
			if save ~= nil and folder ~= nil then
				local ready = CheckInRules.canClaim(save, today)
				if folder:GetAttribute(StatNames.CheckInReady) ~= ready then
					ShopService.republish(player)
				end
			end
		end
	end
end

function CheckInService.Start(_self)
	Net.CheckInClaim.On(onClaim)
	Players.PlayerRemoving:Connect(function(player)
		Throttle.forget(throttle, player)
	end)
	task.spawn(watchDayTurn)
end

return CheckInService
