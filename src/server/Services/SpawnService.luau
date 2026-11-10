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
-- Kit da vida (um só, KitChoice): o pedido (pontos ou saldo de 1 vida da loja)
-- se der; senão o kit para sempre ativo; senão nenhum. Pedido que não dá não
-- desconta nada (KitRules / ShopService.useKitBalance).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local KitChoice = require(ReplicatedStorage.Shared.UIFlow.KitChoice)
local KitRules = require(ReplicatedStorage.Shared.UIFlow.KitRules)
local InventoryService = require(script.Parent.InventoryService)
local ShopService = require(script.Parent.ShopService)
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

-- Dá os itens do kit. Chamado depois de nascer: o inventário já foi zerado na
-- morte (DeathService) e os itens entram por cima dele. A mochila é vestida
-- primeiro, para os itens poderem usar os slots dela.
local function deliverKit(player: Player, kit: Defs.KitDef)
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

-- Cobra pela origem e dá o kit. Devolve o id entregue (nil = nenhum).
local function giveKit(player: Player, kitId: string, source: KitChoice.Source): string?
	local kit = Defs.Kits[kitId]
	if kit == nil then
		return nil
	end
	if source == "points" then
		local bought, left = KitRules.buy(kit, kitPointsOf(player))
		if not bought then
			return nil
		end
		player:SetAttribute(StatNames.KitPoints, left)
	elseif source == "balance" then
		-- O saldo pode ter mudado durante o LoadCharacterAsync: confere de novo.
		if not ShopService.useKitBalance(player, kitId) then
			return nil
		end
	end
	deliverKit(player, kit)
	return kitId
end

-- Kit e origem desta vida (KitChoice) a partir do pedido do cliente.
local function chooseKit(player: Player, kitId: string?, source: string?): (string?, KitChoice.Source?)
	local state = ShopService.kitState(player)
	local requested: KitChoice.Source? = if source == "points" or source == "balance" then source else nil
	return KitChoice.resolve({ kitId = kitId, source = requested }, {
		points = kitPointsOf(player),
		balance = if state then state.balance else {},
		owned = if state then state.owned else {},
		active = if state then state.active else nil,
	}, Defs.Kits)
end

-- Itens que todo jogador recebe ao nascer, com ou sem kit (provisório, para
-- testar as skins de livro). Se o kit escolhido já tem o item, não dá de novo.
local SPAWN_ITEMS: { { id: string, count: number } } = {
	{ id = "book", count = 1 },
}

local function kitHasItem(kitId: string?, itemId: string): boolean
	local kit = if kitId then Defs.Kits[kitId] else nil
	if kit == nil then
		return false
	end
	for _, entry in kit.items do
		if entry.id == itemId then
			return true
		end
	end
	return false
end

local function giveSpawnItems(player: Player, kitId: string?)
	for _, entry in SPAWN_ITEMS do
		if not kitHasItem(kitId, entry.id) then
			local rest = InventoryService.give(player, entry.id, entry.count)
			if rest > 0 then
				warn(`[SpawnService] item inicial de {player.Name}: {rest}× {entry.id} não couberam`)
			end
		end
	end
end

-- Faz o jogador nascer com o kit da vida (pedido `kitId` pela origem
-- `source`, "points" ou "balance"; ou o permanente ativo). Devolve true se nasceu.
function SpawnService.spawn(player: Player, kitId: string?, source: string?): boolean
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
	local chosen, from = chooseKit(player, kitId, source)
	local given = if chosen ~= nil and from ~= nil then giveKit(player, chosen, from :: KitChoice.Source) else nil
	giveSpawnItems(player, given)
	return true
end

function SpawnService.Start(_self)
	Net.RequestSpawn.On(function(player: Player, request: { KitId: string?, Source: string? })
		SpawnService.spawn(player, request.KitId, request.Source)
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
