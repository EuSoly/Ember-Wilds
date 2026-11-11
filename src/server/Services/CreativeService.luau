--!strict
-- Modo criativo (veja docs/guia/modo-criativo.md). A marca fica no perfil
-- salvo (`Creative`); quando o perfil carrega, ela vira o atributo Creative do
-- Player (só o servidor escreve), que o livro do cliente lê para mostrar todos
-- os itens e o botão Pegar. O pedido (Net.CreativeGive) confere a marca NO
-- PERFIL, o personagem vivo e o item. Quem está no criativo não soma pontos,
-- ranking nem estatísticas (ScoreService, RankService e StatsService perguntam
-- CreativeService.isOn).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local CreativeRules = require(ReplicatedStorage.Shared.Creative.CreativeRules)
local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local DataService = require(script.Parent.DataService)
local Net = require(script.Parent.Parent.Net)

local CreativeService = {}

local lastGive: { [Player]: number } = {}

-- Está no criativo? Só a marca do perfil vale (perfil não carregado = não).
function CreativeService.isOn(player: Player): boolean
	local data = DataService.data(player)
	return data ~= nil and data.Creative == true
end

local function publish(player: Player)
	player:SetAttribute(StatNames.Creative, if CreativeService.isOn(player) then true else nil)
end

-- Liga ou desliga (grava no perfil e no atributo). false se o perfil não carregou.
function CreativeService.set(player: Player, on: boolean): boolean
	local data = DataService.data(player)
	if data == nil then
		return false
	end
	data.Creative = on == true
	publish(player)
	return true
end

local function aliveRoot(player: Player): BasePart?
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or humanoid.Health <= 0 or root == nil or not root:IsA("BasePart") then
		return nil
	end
	return root
end

local function onGive(player: Player, request: { Id: string })
	if not CreativeService.isOn(player) then
		return
	end
	local now = os.clock()
	if not CreativeRules.canGive(lastGive[player], now) then
		return
	end
	lastGive[player] = now
	local def = Defs.Items[request.Id]
	if def == nil or aliveRoot(player) == nil then
		return
	end
	-- Require tardio: o InventoryService pergunta ao CreativeService se o item
	-- de teste vale (dependência nos dois sentidos).
	local InventoryService = require(script.Parent.InventoryService) :: any
	local left = InventoryService.give(player, def.id, CreativeRules.giveCount(def))
	if left > 0 then
		Net.CraftNotice.Fire(player, "creative.full")
	end
end

function CreativeService.Start(_self)
	DataService.onLoaded(function(player)
		publish(player)
	end)
	Net.CreativeGive.On(onGive)
	Players.PlayerRemoving:Connect(function(player)
		lastGive[player] = nil
	end)
	if RunService:IsStudio() then
		-- ServerStorage.DevCreative:Invoke(player, true/false) -> boolean
		local command = Instance.new("BindableFunction")
		command.Name = "DevCreative"
		command.OnInvoke = function(player: Player, on: boolean): boolean
			return CreativeService.set(player, on)
		end
		command.Parent = ServerStorage
	end
end

return CreativeService
