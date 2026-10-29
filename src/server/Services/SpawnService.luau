--!strict
-- Nascer a pedido (Players.CharacterAutoLoads = false): o personagem só nasce
-- quando o cliente pede (Net.RequestSpawn, botões Jogar / Jogar de novo),
-- opcionalmente com um kit inicial pago com os pontos da última vida (KitPoints).
-- As fases G podem chamar o mesmo caminho para nascer (SpawnService.spawn).
--
-- O pedido vem do cliente, então é ignorado em silêncio se:
-- - o perfil ainda não carregou (DataReady);
-- - o jogador já está nascendo (marca por jogador: dois pedidos rápidos não
--   passam juntos, porque LoadCharacterAsync espera);
-- - o jogador já tem personagem vivo (Humanoid com vida > 0).
-- Kit inexistente ou caro demais = nasce sem kit e sem descontar nada (KitRules).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local KitRules = require(ReplicatedStorage.Shared.UIFlow.KitRules)
local InventoryService = require(script.Parent.InventoryService)
local Net = require(script.Parent.Parent.Net)

local SpawnService = {}

local spawning: { [Player]: boolean } = {}

local function isAlive(player: Player): boolean
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	return humanoid ~= nil and humanoid.Health > 0
end

-- Pontos para kit: número finito e não negativo, senão 0.
local function kitPointsOf(player: Player): number
	local points = player:GetAttribute(StatNames.KitPoints)
	if type(points) ~= "number" or points ~= points or points < 0 or points == math.huge then
		return 0
	end
	return points
end

-- Cobra e dá o kit. Chamado depois de nascer: o inventário já foi zerado na
-- morte (DeathService) e os itens entram por cima dele. A mochila é vestida
-- primeiro, para os itens poderem usar os slots dela.
local function giveKit(player: Player, kitId: string)
	local kit = Defs.Kits[kitId]
	local bought, left = KitRules.buy(kit, kitPointsOf(player))
	if not bought or kit == nil then
		return
	end
	player:SetAttribute(StatNames.KitPoints, left)
	for _, entry in kit.items do
		local def = Defs.Items[entry.id]
		if def and def.category == "bag" then
			InventoryService.equipBag(player, entry.id)
		end
	end
	for _, entry in kit.items do
		local def = Defs.Items[entry.id]
		if def and def.category ~= "bag" then
			-- A validação garante que o kit cabe num inventário novo; sobra aqui
			-- quer dizer que algo mudou (ex. o inventário não estava vazio).
			local rest = InventoryService.give(player, entry.id, entry.count)
			if rest > 0 then
				warn(`[SpawnService] kit "{kit.id}" de {player.Name}: {rest}× {entry.id} não couberam`)
			end
		end
	end
end

-- Faz o jogador nascer (com o kit, se der). Devolve true se nasceu.
function SpawnService.spawn(player: Player, kitId: string?): boolean
	if player.Parent ~= Players or player:GetAttribute(StatNames.DataReady) ~= true then
		return false
	end
	if spawning[player] or isAlive(player) then
		return false
	end
	spawning[player] = true
	local ok, err = pcall(function()
		player:LoadCharacterAsync()
	end)
	spawning[player] = nil
	if not ok then
		warn(`[SpawnService] falha ao nascer {player.Name}: {err}`)
		return false
	end
	if player.Parent ~= Players then
		return false
	end
	if kitId ~= nil then
		giveKit(player, kitId)
	end
	return true
end

function SpawnService.Start(_self)
	Net.RequestSpawn.On(function(player: Player, request: { KitId: string? })
		SpawnService.spawn(player, request.KitId)
	end)

	-- Na primeira entrada no servidor não há pontos para kit (só em memória).
	local function onPlayer(player: Player)
		if player:GetAttribute(StatNames.KitPoints) == nil then
			player:SetAttribute(StatNames.KitPoints, 0)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, player in Players:GetPlayers() do
		onPlayer(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		spawning[player] = nil
	end)
end

return SpawnService
