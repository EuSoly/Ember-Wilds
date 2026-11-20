--!strict
-- Códigos de resgate (spec 2026-11-18-codigos-design). O jogador digita no
-- menu (Menu/CodePanel); aqui: confere o código (Shop/Codes via CodeRules),
-- uma vez por jogador (perfil Shop.Codes), só fora da partida (no menu), no
-- máximo uma tentativa a cada REQUEST_COOLDOWN s (ninguém testa no chute), e
-- entrega os prêmios pelo ShopService. O arquivo de códigos é validado no boot.
-- Também o prêmio do grupo do Roblox (Shop/GroupReward): o cliente pede depois
-- de entrar; aqui conferimos a entrada (IsInGroupAsync) e entregamos uma vez.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage.Shared
local Defs = require(Shared.Defs)
local CodeRules = require(Shared.Shop.CodeRules)
local Codes = require(Shared.Shop.Codes)
local GroupReward = require(Shared.Shop.GroupReward)
local ShopData = require(Shared.Shop.ShopData)
local Throttle = require(Shared.Shop.Throttle)
local DataService = require(script.Parent.DataService)
local LifeService = require(script.Parent.LifeService)
local ShopService = require(script.Parent.ShopService)
local Net = require(script.Parent.Parent.Net)

local REQUEST_COOLDOWN = 2

local CodeService = {}

local throttle = Throttle.new(REQUEST_COOLDOWN)

local function reply(player: Player, ok: boolean, reason: string?, code: string?)
	Net.CodeResult.Fire(player, { Ok = ok, Reason = reason, Code = code })
end

local function onRequest(player: Player, request: { Code: string })
	if not Throttle.allow(throttle, player, "code", os.clock()) then
		reply(player, false, "wait")
		return
	end
	-- Só no menu: o botão não existe na partida; um cliente modificado também não passa.
	if LifeService.lifeKey(player) ~= nil then
		reply(player, false, "inGame")
		return
	end
	local data = DataService.data(player)
	local d = if data then data.Shop :: ShopData.ShopData else nil
	if d == nil then
		reply(player, false, "error")
		return
	end
	local def = CodeRules.find(Codes, request.Code)
	local refusal = CodeRules.check(def, d.Codes, os.time())
	if refusal ~= nil or def == nil then
		reply(player, false, refusal or "unknown")
		return
	end
	-- Marca antes de entregar: um erro na entrega não deixa resgatar de novo.
	ShopData.useCode(d, def.code)
	local ok, problem = ShopService.giveAll(player, def.rewards, `code:{def.code}`)
	if not ok then
		warn(`[CodeService] código {def.code} para {player.Name} falhou: {problem}`)
		reply(player, false, "error")
		return
	end
	reply(player, true, nil, def.code)
end

local function replyGroup(player: Player, ok: boolean, reason: string?)
	Net.GroupRewardResult.Fire(player, { Ok = ok, Reason = reason })
end

local function onGroupRequest(player: Player)
	if not Throttle.allow(throttle, player, "group", os.clock()) then
		replyGroup(player, false, "wait")
		return
	end
	local groupId = GroupReward.GROUP_ID
	if groupId <= 0 then
		replyGroup(player, false, "error")
		return
	end
	if LifeService.lifeKey(player) ~= nil then
		replyGroup(player, false, "inGame")
		return
	end
	local data = DataService.data(player)
	local d = if data then data.Shop :: ShopData.ShopData else nil
	if d == nil then
		replyGroup(player, false, "error")
		return
	end
	if GroupReward.claimed(d.Codes, groupId) then
		replyGroup(player, false, "claimed")
		return
	end
	local called, member = pcall(function()
		return player:IsInGroupAsync(groupId)
	end)
	if not called then
		warn(`[CodeService] IsInGroupAsync para {player.Name} falhou: {member}`)
		replyGroup(player, false, "error")
		return
	end
	if member ~= true then
		replyGroup(player, false, "notMember")
		return
	end
	-- Confere de novo depois da espera: dois pedidos juntos não levam 2×.
	if GroupReward.claimed(d.Codes, groupId) or player.Parent == nil then
		replyGroup(player, false, "claimed")
		return
	end
	-- Marca antes de entregar, como os códigos.
	ShopData.useCode(d, GroupReward.mark(groupId))
	local ok, problem = ShopService.giveAll(player, GroupReward.rewards, `group:{groupId}`)
	if not ok then
		warn(`[CodeService] prêmio do grupo para {player.Name} falhou: {problem}`)
		replyGroup(player, false, "error")
		return
	end
	replyGroup(player, true)
end

function CodeService.Init(_self)
	local errors = CodeRules.validate(Codes, Defs)
	if #errors > 0 then
		error("[Shop/Codes] códigos com erros:\n" .. table.concat(errors, "\n"))
	end
	local groupErrors = CodeRules.validate({ { code = "GRUPO", rewards = GroupReward.rewards } }, Defs)
	if #groupErrors > 0 then
		error("[Shop/GroupReward] prêmio com erros:\n" .. table.concat(groupErrors, "\n"))
	end
end

function CodeService.Start(_self)
	Net.RequestCode.On(onRequest)
	Net.RequestGroupReward.On(onGroupRequest)
	Players.PlayerRemoving:Connect(function(player)
		Throttle.forget(throttle, player)
	end)
end

return CodeService
