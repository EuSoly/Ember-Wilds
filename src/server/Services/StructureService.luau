--!strict
-- As peças de construção colocadas no mundo (G4, posição livre). Cada peça é
-- um círculo no chão (centro x, z e raio BuildRules.radiusOf) guardado num
-- índice espacial só do servidor (SpatialGrid), tem dono (o Player), vida, o
-- giro (yaw) e o comportamento do tipo (def.kind, dos dados).
--
-- Colocar: na descida do atributo Using (soltou o clique no PC, soltou o
-- joystick no celular) com uma peça placeable na mão. O ponto é
-- BuildRules.placePoint da raiz + direção do olhar (achatada), e a peça fica
-- de frente para quem constrói, mais o giro escolhido (BuildRules.facingYaw),
-- tudo do servidor. Recusa calado (nada gasto): círculo sobrepondo outra peça,
-- recurso ou jogador (encostar pode), água no ponto, acima do limite. Só
-- depois de tudo conferido tira o item do inventário (InventoryService.take,
-- tudo ou nada) e cria a peça, sem pausa (yield) no meio: o inventário não
-- muda entre conferir e gastar.
--
-- Giro: o cliente só manda o número de passos (Net.SetBuildRotation, 0 a
-- BuildRules.ROTATE_STEPS - 1), aceito só com uma peça na mão. Volta a 0 ao
-- trocar o item da mão (Equipped) e no respawn.
--
-- Bater (GatherService): a porta de um aliado do dono abre/fecha; o resto tira
-- vida (BuildRules.damageOf). Vida 0 = some. Porta não fecha com jogador
-- encostando no círculo dela. Fogo some sozinho depois de def.lifetime segundos.
-- Dono morreu (DeathService.kill) ou saiu: removeOwned some com tudo dele.
-- Toda remoção tira a peça do índice espacial e avisa quem pediu (onRemoved);
-- toda peça criada também avisa (onCreated).
-- O dano do espinho fica no SpikeService (ver lá o porquê).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local BuildRules = require(ReplicatedStorage.Shared.Build.BuildRules)
local Defs = require(ReplicatedStorage.Shared.Defs)
local ItemAccess = require(ReplicatedStorage.Shared.ItemAccess)
local SpatialGrid = require(ReplicatedStorage.Shared.World.SpatialGrid)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local StructureModel = require(ReplicatedStorage.Shared.Models.StructureModel)
local WaterSim = require(ReplicatedStorage.Shared.Simulation.WaterSim)
local CraftService = require(script.Parent.CraftService)
local InventoryService = require(script.Parent.InventoryService)
local ResourceService = require(script.Parent.ResourceService)
local Net = require(script.Parent.Parent.Net)

-- Studs: jogador a até isso da borda do círculo da porta impede fechar (raio do corpo).
local DOOR_MARGIN = BuildRules.PLAYER_RADIUS
-- Folga da busca de recursos: maior raio de colisão de um recurso (com variação).
local RESOURCE_SEARCH = 5
-- Studs por célula do índice espacial das peças (duas peças padrão de largura).
local GRID_CELL = 8
-- Limite de taxa do giro: até ROTATE_RATE_MAX pedidos por ROTATE_RATE_WINDOW
-- segundos, por jogador; o resto é ignorado (apertar R não passa disso).
local ROTATE_RATE_MAX = 20
local ROTATE_RATE_WINDOW = 1

export type Entry = {
	model: Model,
	itemId: string,
	def: Defs.StructureDef,
	owner: Player,
	x: number, -- centro do círculo da peça (studs)
	z: number,
	radius: number, -- raio do círculo (BuildRules.radiusOf; também o do GatherRules.pickTarget)
	yaw: number, -- graus em torno de Y (BuildRules.facingYaw)
	health: number,
}

type RateState = { start: number, count: number }

local StructureService = {}

-- Índice espacial das peças vivas (pela posição x, z da entrada).
local grid = SpatialGrid.new(GRID_CELL)
-- Maior raio já posto no índice: a busca cresce por ele para achar peças cujo
-- centro está longe mas o círculo encosta.
local maxRadius = BuildRules.PIECE_RADIUS
local alive: { [Entry]: boolean } = {}
local byModel: { [Model]: Entry } = {}
local owned: { [Player]: { [Entry]: boolean } } = {}
local counts: { [Player]: number } = {}
local createdListeners: { (Entry) -> () } = {}
local removedListeners: { (Entry) -> () } = {}
local folder: Folder? = nil
-- Giro escolhido (passos de BuildRules.ROTATE_STEP) por jogador; nil = 0.
local rotation: { [Player]: number } = {}
local rotateRates: { [Player]: RateState } = {}

local function getFolder(): Folder
	local current = folder
	if current == nil or current.Parent == nil then
		local created = Instance.new("Folder")
		created.Name = "Structures"
		created.Parent = Workspace
		current = created
		folder = created
	end
	return current :: Folder
end

-- Raiz de um personagem vivo (montado, com Humanoid), ou nil.
local function rootOf(character: Model?): BasePart?
	if character == nil or character.Parent == nil or character:FindFirstChildOfClass("Humanoid") == nil then
		return nil
	end
	local root = character:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

-- Algum jogador vivo com a raiz a até `margin` da borda do círculo (x, z, radius)?
local function playerTouching(x: number, z: number, radius: number, margin: number): boolean
	for _, other in Players:GetPlayers() do
		local root = rootOf(other.Character)
		if root and BuildRules.touchesCircle(root.Position.X, root.Position.Z, x, z, radius, margin) then
			return true
		end
	end
	return false
end

-- Peças vivas cujo círculo encosta (ou entra) no círculo (x, z, radius).
-- Quem chama ainda decide o que é "tocar" para si (sobrepor, margem...).
function StructureService.near(x: number, z: number, radius: number): { Entry }
	local found: { Entry } = {}
	if not (radius >= 0) then
		return found
	end
	for _, item in grid:query(x, z, radius + maxRadius) do
		local entry = item :: Entry
		if alive[entry] and BuildRules.touchesCircle(x, z, entry.x, entry.z, entry.radius, radius) then
			table.insert(found, entry)
		end
	end
	return found
end

-- A peça viva deste modelo, ou nil (já removida, ou não é peça).
function StructureService.entryOf(model: Instance): Entry?
	return byModel[model :: any]
end

-- Chamado (sem pausa) em toda peça criada, já no mundo e registrada (entryOf acha).
function StructureService.onCreated(listener: (Entry) -> ())
	table.insert(createdListeners, listener)
end

-- Chamado (sem pausa) em toda remoção de peça, antes de o modelo sumir.
function StructureService.onRemoved(listener: (Entry) -> ())
	table.insert(removedListeners, listener)
end

-- Único caminho de remoção (vida 0, fogo, dono, apagada por fora): tira do
-- índice espacial, das tabelas e da contagem do dono.
local function remove(entry: Entry)
	if not alive[entry] then
		return
	end
	alive[entry] = nil
	grid:remove(entry, entry.x, entry.z)
	byModel[entry.model] = nil
	local mine = owned[entry.owner]
	if mine and mine[entry] then
		mine[entry] = nil
		counts[entry.owner] = math.max((counts[entry.owner] or 1) - 1, 0)
	end
	for _, listener in removedListeners do
		local ok, err = pcall(listener :: any, entry)
		if not ok then
			warn(`[StructureService] onRemoved: {err}`)
		end
	end
	entry.model:Destroy()
end

-- Some com todas as peças do jogador (morte ou saída). Um revive futuro
-- simplesmente não chama isto, e as peças ficam.
function StructureService.removeOwned(player: Player)
	local mine = owned[player]
	if mine == nil then
		return
	end
	local list = {}
	for entry in mine do
		table.insert(list, entry)
	end
	for _, entry in list do
		remove(entry)
	end
	owned[player] = nil
	counts[player] = nil
end

local function toggleDoor(entry: Entry)
	local open = entry.model:GetAttribute(StatNames.DoorOpen) == true
	-- Fechar com alguém dentro (ou encostando) prenderia o jogador na porta.
	if open and playerTouching(entry.x, entry.z, entry.radius, DOOR_MARGIN) then
		return
	end
	StructureModel.setOpen(entry.model, not open)
end

-- Golpe numa peça. `item` = o que está na mão de quem bateu (nil = mão).
function StructureService.hit(entry: Entry, attacker: Player, item: Defs.ItemDef?)
	if not alive[entry] then
		return
	end
	-- Porta do aliado: abre ou fecha, sem dano. Quem não é aliado só tira vida.
	if BuildRules.isDoor(entry.def.kind) and BuildRules.areAllies(entry.owner.UserId, attacker.UserId) then
		toggleDoor(entry)
		return
	end
	entry.health = math.max(entry.health - BuildRules.damageOf(item), 0)
	entry.model:SetAttribute(StatNames.StructureHealth, entry.health)
	if entry.health <= 0 then
		remove(entry)
	end
end

-- Pode colocar uma peça de raio `radius` com o centro em (x, z)? Tudo do
-- servidor. Encostar (distância = soma dos raios) pode; sobrepor, não.
local function canPlace(player: Player, x: number, z: number, radius: number): boolean
	if not BuildRules.underLimit(counts[player] or 0) then
		return false
	end
	if WaterSim.isWet(x, z) then
		return false
	end
	-- Cada peça com o próprio raio (near já traz só as que encostam ou entram).
	for _, other in StructureService.near(x, z, radius) do
		if BuildRules.circlesOverlap(x, z, radius, other.x, other.z, other.radius) then
			return false
		end
	end
	-- A peça de colisão (círculo) do recurso.
	for _, resource in ResourceService.near(x, z, radius + RESOURCE_SEARCH) do
		if BuildRules.circlesOverlap(x, z, radius, resource.x, resource.z, resource.radius) then
			return false
		end
	end
	for _, other in Players:GetPlayers() do
		local root = rootOf(other.Character)
		if
			root
			and BuildRules.circlesOverlap(x, z, radius, root.Position.X, root.Position.Z, BuildRules.PLAYER_RADIUS)
		then
			return false
		end
	end
	return true
end

local function create(
	player: Player,
	itemId: string,
	def: Defs.StructureDef,
	x: number,
	z: number,
	radius: number,
	yaw: number
): boolean
	local ok, built = pcall(StructureModel.build, itemId, def)
	if not ok then
		warn(`[StructureService] modelo de {itemId}: {built}`)
		return false
	end
	local model = built :: Model
	-- Só o pivô gira: o desenho interno do modelo fica como está.
	model:PivotTo(CFrame.new(x, 0, z) * CFrame.Angles(0, math.rad(yaw), 0))
	model:SetAttribute(StatNames.StructureItem, itemId)
	model:SetAttribute(StatNames.Owner, player.UserId)
	model:SetAttribute(StatNames.StructureHealth, def.health)
	model:SetAttribute(StatNames.StructureHealthMax, def.health)
	model:AddTag(StatNames.StructureTag)

	local entry: Entry = {
		model = model,
		itemId = itemId,
		def = def,
		owner = player,
		x = x,
		z = z,
		radius = radius,
		yaw = yaw,
		health = def.health,
	}
	grid:insert(entry, x, z)
	maxRadius = math.max(maxRadius, radius)
	alive[entry] = true
	byModel[model] = entry
	local mine = owned[player]
	if mine == nil then
		mine = {}
		owned[player] = mine
	end
	mine[entry] = true
	counts[player] = (counts[player] or 0) + 1
	model.Parent = getFolder()
	-- Peça apagada por fora (comando, outro script, pasta destruída): sai do
	-- índice igual. remove é idempotente, então o Destroy do próprio remove
	-- volta aqui e não faz nada.
	model.Destroying:Connect(function()
		remove(entry)
	end)
	model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(Workspace) then
			remove(entry)
		end
	end)

	-- Fogo: apaga e some sozinho. Se já saiu antes (vida 0, dono morto),
	-- remove ignora (a entrada é a "ficha" desta peça; nunca é reaproveitada).
	local lifetime = def.lifetime
	if lifetime then
		task.delay(lifetime, remove, entry)
	end
	for _, listener in createdListeners do
		local called, err = pcall(listener :: any, entry)
		if not called then
			warn(`[StructureService] onCreated: {err}`)
		end
	end
	return true
end

local function place(player: Player, character: Model)
	if player.Parent ~= Players or player.Character ~= character then
		return
	end
	if CraftService.isCrafting(player) then
		return
	end
	local root = rootOf(character)
	if root == nil then
		return
	end
	-- O item vem do slot selecionado (servidor) e tem de ser o que está na mão.
	local inv = InventoryService.get(player)
	local slot = inv and inv.slots[InventoryService.selectedSlot(player)]
	if slot == nil or slot.count < 1 or character:GetAttribute(StatNames.Equipped) ~= slot.id then
		return
	end
	local itemId = slot.id
	-- Item só-para-teste fora do Studio: recusa antes de tirar da mão.
	if not ItemAccess.isAvailable(itemId, RunService:IsStudio()) then
		return
	end
	local item = Defs.Items[itemId]
	local def = if item and item.category == "placeable" then item.structure else nil
	if def == nil then
		return
	end

	local look = root.CFrame.LookVector
	local flat = Vector3.new(look.X, 0, look.Z)
	if flat.Magnitude < 1e-3 then
		return
	end
	local dir = flat.Unit
	local rx, rz = root.Position.X, root.Position.Z
	local x, z = BuildRules.placePoint(rx, rz, dir.X, dir.Z)
	local radius = BuildRules.radiusOf(def)
	if not canPlace(player, x, z, radius) then
		return
	end
	local yaw = BuildRules.facingYaw(x, z, rx, rz, rotation[player] or 0)
	if not InventoryService.take(player, itemId, 1) then
		return
	end
	if not create(player, itemId, def, x, z, radius, yaw) then
		InventoryService.give(player, itemId, 1)
	end
end

-- Pedido de giro dentro do limite de taxa?
local function allowRotate(player: Player): boolean
	local now = os.clock()
	local state = rotateRates[player]
	if state == nil or now - state.start >= ROTATE_RATE_WINDOW then
		rotateRates[player] = { start = now, count = 1 }
		return true
	end
	if state.count >= ROTATE_RATE_MAX then
		return false
	end
	state.count += 1
	return true
end

-- O cliente escolheu o giro (passos de 45°). Só vale inteiro de 0 a 7 e com
-- uma peça placeable na mão; o resto é ignorado.
local function onSetRotation(player: Player, steps: number)
	-- Pedido que chegou depois de o jogador sair: não recria o estado dele.
	if player.Parent ~= Players then
		return
	end
	if not allowRotate(player) or not BuildRules.validSteps(steps) then
		return
	end
	local character = player.Character
	local equipped = character and character:GetAttribute(StatNames.Equipped)
	local item = if type(equipped) == "string" then Defs.Items[equipped] else nil
	if item == nil or item.category ~= "placeable" or item.structure == nil then
		return
	end
	if steps == 0 then
		rotation[player] = nil
	else
		rotation[player] = steps
	end
end

-- Coloca na descida de Using (true → false) deste personagem. Personagem novo
-- (respawn) ou item novo na mão: o giro volta a 0.
local function setupCharacter(player: Player, character: Model)
	rotation[player] = nil
	character:GetAttributeChangedSignal(StatNames.Equipped):Connect(function()
		if player.Character == character then
			rotation[player] = nil
		end
	end)
	local held = character:GetAttribute(StatNames.Using) == true
	character:GetAttributeChangedSignal(StatNames.Using):Connect(function()
		if character:GetAttribute(StatNames.Using) == true then
			held = true
		elseif held then
			held = false
			place(player, character)
		end
	end)
end

local function setupPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		setupCharacter(player, character)
	end)
	if player.Character then
		setupCharacter(player, player.Character)
	end
end

function StructureService.Start(_self)
	getFolder()
	Net.SetBuildRotation.On(onSetRotation)
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	-- Sair = morte: as peças do jogador somem.
	Players.PlayerRemoving:Connect(function(player)
		rotation[player] = nil
		rotateRates[player] = nil
		StructureService.removeOwned(player)
	end)
end

return StructureService
