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
-- Kit da vida (um só, KitChoice): o pedido (pontos, saldo de 1 vida da loja ou
-- kit para sempre, comprado ou liberado por vantagem) se der; senão o kit para
-- sempre ativo; senão nenhum. Pedido que não dá não desconta nada (KitRules /
-- ShopService.useKitBalance).
--
-- Revive (spawnAt / reviveSpot): nasce num ponto dado, sem kit, sem os itens
-- iniciais e sem tutorial; o ponto é perto do totem do time (se de pé) ou um
-- lugar ao acaso na floresta, longe da água, das áreas sem nascimento, das
-- construções e dos outros jogadores vivos.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local KitChoice = require(ReplicatedStorage.Shared.UIFlow.KitChoice)
local KitRules = require(ReplicatedStorage.Shared.UIFlow.KitRules)
local SpawnPoint = require(ReplicatedStorage.Shared.Survival.SpawnPoint)
local WorldConfig = require(ReplicatedStorage.Shared.WorldConfig)
local InventoryService = require(script.Parent.InventoryService)
local LifeService = require(script.Parent.LifeService)
local MapService = require(script.Parent.MapService)
local PerkService = require(script.Parent.PerkService)
local ShopService = require(script.Parent.ShopService)
local StructureService = require(script.Parent.StructureService)
local TeamService = require(script.Parent.TeamService)
local TutorialService = require(script.Parent.TutorialService)
local Net = require(script.Parent.Parent.Net)

-- Revive ao acaso na floresta: o ponto não vale a menos de STRUCTURE_GAP studs
-- de uma construção nem a menos de PLAYER_GAP studs de outro jogador vivo.
local STRUCTURE_GAP = 12
local PLAYER_GAP = 30
-- Pontos sorteados antes de desistir (e nascer no WorldConfig.SPAWN).
local PICK_TRIES = 30
-- Folga da borda da floresta (as paredes de Map/Borders ficam na borda).
local FOREST_EDGE = 20
-- Revive no totem: anel em volta dele (studs do centro; o totem tem raio 4)
-- e quantos pontos do anel testar até achar um sem construção.
local TOTEM_RING = 8
local TOTEM_RING_POINTS = 8
-- Raio do corpo para o ponto do anel não cair dentro de uma construção.
local BODY_RADIUS = 1.5
-- Studs acima do chão para soltar o personagem (cai de leve no lugar).
local DROP_HEIGHT = 2

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

-- Kit e origem desta vida (KitChoice) a partir do pedido do cliente. Os kits
-- para sempre são os comprados (KitsOwned) mais os das vantagens desta vida
-- (PerkService.unlockedKits: Premium e VIP).
local function chooseKit(player: Player, kitId: string?, source: string?): (string?, KitChoice.Source?)
	local state = ShopService.kitState(player)
	local requested: KitChoice.Source? = if source == "points"
			or source == "balance"
			or source == "permanent"
		then source
		else nil
	local owned = PerkService.unlockedKits(player)
	if state then
		for id, on in state.owned do
			if on == true then
				owned[id] = true
			end
		end
	end
	return KitChoice.resolve({ kitId = kitId, source = requested }, {
		points = kitPointsOf(player),
		balance = if state then state.balance else {},
		owned = owned,
		active = if state then state.active else nil,
	}, Defs.Kits)
end

-- Itens de quem tem o passe do livro (PerkService.forLife().book), com ou sem
-- kit. Se o kit escolhido já tem o item, não dá de novo.
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
	if not PerkService.forLife(player).book then
		return
	end
	for _, entry in SPAWN_ITEMS do
		if not kitHasItem(kitId, entry.id) then
			local rest = InventoryService.give(player, entry.id, entry.count)
			if rest > 0 then
				warn(`[SpawnService] item inicial de {player.Name}: {rest}× {entry.id} não couberam`)
			end
		end
	end
end

-- Carrega o personagem com as guardas de sempre (perfil pronto, não está
-- nascendo, não está vivo). Devolve true se nasceu e o jogador segue no jogo.
local function loadCharacter(player: Player): boolean
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
	return player.Parent == Players
end

-- Faz o jogador nascer com o kit da vida (pedido `kitId` pela origem
-- `source`, "points", "balance" ou "permanent"; ou o permanente ativo).
-- Devolve true se nasceu.
function SpawnService.spawn(player: Player, kitId: string?, source: string?): boolean
	if not loadCharacter(player) then
		return false
	end
	-- A vida começa já (se o CharacterAdded ainda não começou): a foto das
	-- vantagens (PerkService) e os espaços do VIP vêm antes do kit e do livro.
	LifeService.begin(player)
	-- Vida de tutorial: sem kit (nada é aplicado nem gasto; um kit com picareta
	-- pularia a etapa 2).
	local given: string? = nil
	if not TutorialService.pending(player) then
		local chosen, from = chooseKit(player, kitId, source)
		given = if chosen ~= nil and from ~= nil then giveKit(player, chosen, from :: KitChoice.Source) else nil
	end
	giveSpawnItems(player, given)
	TutorialService.begin(player)
	return true
end

-- Faz o jogador nascer em `position` (o chão; o personagem cai de
-- DROP_HEIGHT acima), sem kit, sem SPAWN_ITEMS e sem tutorial: o revive põe o
-- inventário de volta depois (InventoryService.restore). A vida começa já
-- (LifeService.begin), para a foto das vantagens existir. true se nasceu.
function SpawnService.spawnAt(player: Player, position: Vector3): boolean
	if not loadCharacter(player) then
		return false
	end
	LifeService.begin(player)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		local root = character:FindFirstChild("HumanoidRootPart")
		-- Do chão até o centro da raiz (a pivô do personagem).
		local rootHeight = if humanoid
				and root
				and root:IsA("BasePart")
			then humanoid.HipHeight + root.Size.Y / 2
			else 3
		character:PivotTo(CFrame.new(position + Vector3.new(0, rootHeight + DROP_HEIGHT, 0)))
	end
	return true
end

-- Outro jogador vivo a menos de PLAYER_GAP studs de (x, z)?
local function nearOtherPlayer(player: Player, x: number, z: number): boolean
	for _, other in Players:GetPlayers() do
		local character = other.Character
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if other ~= player and isAlive(other) and root and root:IsA("BasePart") then
			local dx, dz = root.Position.X - x, root.Position.Z - z
			if dx * dx + dz * dz < PLAYER_GAP * PLAYER_GAP then
				return true
			end
		end
	end
	return false
end

local random = Random.new()

local function nextNumber(): number
	return random:NextNumber()
end

-- Um ponto do anel em volta do totem sem construção (paredes da base); se
-- todos estão ocupados, o próprio totem (o personagem cai em cima dele).
local function besideTotem(totem: Vector3): Vector3
	local start = random:NextNumber() * 2 * math.pi
	for i = 0, TOTEM_RING_POINTS - 1 do
		local angle = start + i * 2 * math.pi / TOTEM_RING_POINTS
		local x = totem.X + math.cos(angle) * TOTEM_RING
		local z = totem.Z + math.sin(angle) * TOTEM_RING
		if #StructureService.near(x, z, BODY_RADIUS) == 0 and not MapService.isBlockedAt(x, z) then
			return Vector3.new(x, totem.Y, z)
		end
	end
	return totem
end

-- Onde o revive nasce: perto do totem do time, se está de pé; senão um ponto
-- ao acaso na floresta fora de Water/NoSpawn, a STRUCTURE_GAP de construções
-- e a PLAYER_GAP de outros vivos; se PICK_TRIES pontos falharem (ou não há
-- mapa desenhado), o WorldConfig.SPAWN.
function SpawnService.reviveSpot(player: Player): Vector3
	local totem = TeamService.totemPositionOf(player)
	if totem then
		return besideTotem(totem)
	end
	local spawn = WorldConfig.SPAWN
	local fallback = Vector3.new(spawn.x, spawn.y, spawn.z)
	-- Sem mapa desenhado só existe o chão de teste em volta do SPAWN.
	if not MapService.hasMap() then
		return fallback
	end
	local forest = WorldConfig.BIOMES.forest
	local zone = {
		minX = forest.minX + FOREST_EDGE,
		maxX = forest.maxX - FOREST_EDGE,
		minZ = forest.minZ + FOREST_EDGE,
		maxZ = forest.maxZ - FOREST_EDGE,
	}
	local x, z = SpawnPoint.pick(nextNumber, zone, function(px: number, pz: number): boolean
		return MapService.isBlockedAt(px, pz)
			or #StructureService.near(px, pz, STRUCTURE_GAP) > 0
			or nearOtherPlayer(player, px, pz)
	end, PICK_TRIES)
	return if x and z then Vector3.new(x, 0, z) else fallback
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
