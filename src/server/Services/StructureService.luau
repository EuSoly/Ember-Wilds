--!strict
-- As peças de construção colocadas no mundo (G4). Cada peça ocupa células de
-- BuildRules.CELL studs numa grade só do servidor (chave BuildRules.key), tem
-- dono (o Player), vida e o comportamento do tipo (def.kind, dos dados).
--
-- Colocar: na descida do atributo Using (soltou o clique no PC, soltou o
-- joystick no celular) com uma peça placeable na mão. A célula é a da frente
-- (BuildRules.targetCell da raiz + direção do olhar, tudo do servidor). Recusa
-- calado (nada gasto): célula ocupada, acima do limite, água no centro de uma
-- célula, recurso ou jogador encostando. Só depois de tudo conferido tira o
-- item do inventário (InventoryService.take, tudo ou nada) e cria a peça, sem
-- pausa (yield) no meio: o inventário não muda entre conferir e gastar.
--
-- Bater (GatherService): a porta de um aliado do dono abre/fecha; o resto tira
-- vida (BuildRules.damageOf). Vida 0 = some. Porta não fecha com jogador
-- encostando na célula. Fogo some sozinho depois de def.lifetime segundos.
-- Dono morreu (DeathService.kill) ou saiu: removeOwned some com tudo dele.
-- Toda remoção libera as células e avisa quem pediu (onRemoved).
-- O dano do espinho fica no SpikeService (ver lá o porquê).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local BuildRules = require(ReplicatedStorage.Shared.Build.BuildRules)
local Defs = require(ReplicatedStorage.Shared.Defs)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local StructureModel = require(ReplicatedStorage.Shared.Models.StructureModel)
local WaterSim = require(ReplicatedStorage.Shared.Simulation.WaterSim)
local CraftService = require(script.Parent.CraftService)
local InventoryService = require(script.Parent.InventoryService)
local ResourceService = require(script.Parent.ResourceService)

-- Studs: jogador cuja raiz está a até isso do quadrado da peça impede construir.
local PLAYER_MARGIN = 1.5
-- Studs: jogador a até isso da célula da porta impede fechar (o corpo tem 3
-- de largura: 1,5 do centro à borda).
local DOOR_MARGIN = 1.5
-- Folga da busca de recursos: maior raio de colisão de um recurso (com variação).
local RESOURCE_SEARCH = 5

export type Entry = {
	model: Model,
	itemId: string,
	def: Defs.StructureDef,
	owner: Player,
	cx: number, -- célula do canto (a de menor x e z)
	cz: number,
	x: number, -- centro da peça (studs)
	z: number,
	radius: number, -- meia largura da peça (para GatherRules.pickTarget)
	health: number,
}

local StructureService = {}

-- Célula (BuildRules.key) → peça que a ocupa.
local cells: { [string]: Entry } = {}
local alive: { [Entry]: boolean } = {}
local byModel: { [Model]: Entry } = {}
local owned: { [Player]: { [Entry]: boolean } } = {}
local counts: { [Player]: number } = {}
local removedListeners: { (Entry) -> () } = {}
local folder: Folder? = nil

local function sizeOf(def: Defs.StructureDef): number
	return def.size or 1
end

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

-- Algum jogador vivo com a raiz a até `margin` do quadrado (size células a partir de cx, cz)?
local function playerTouching(cx: number, cz: number, size: number, margin: number): boolean
	for _, other in Players:GetPlayers() do
		local root = rootOf(other.Character)
		if root and BuildRules.touches(root.Position.X, root.Position.Z, cx, cz, size, margin) then
			return true
		end
	end
	return false
end

-- Peças cujas células tocam o quadrado em volta do círculo (x, z, radius).
-- Pode trazer alguma um pouco fora do raio: quem chama confere a distância.
function StructureService.near(x: number, z: number, radius: number): { Entry }
	local found: { Entry } = {}
	if not (radius >= 0) then
		return found
	end
	local seen: { [Entry]: boolean } = {}
	local minX, minZ = BuildRules.cellOf(x - radius, z - radius)
	local maxX, maxZ = BuildRules.cellOf(x + radius, z + radius)
	for cx = minX, maxX do
		for cz = minZ, maxZ do
			local entry = cells[BuildRules.key(cx, cz)]
			if entry and not seen[entry] then
				seen[entry] = true
				table.insert(found, entry)
			end
		end
	end
	return found
end

-- A peça viva deste modelo, ou nil (já removida, ou não é peça).
function StructureService.entryOf(model: Instance): Entry?
	return byModel[model :: any]
end

-- Chamado (sem pausa) em toda remoção de peça, antes de o modelo sumir.
function StructureService.onRemoved(listener: (Entry) -> ())
	table.insert(removedListeners, listener)
end

local function remove(entry: Entry)
	if not alive[entry] then
		return
	end
	alive[entry] = nil
	for _, key in BuildRules.cellsOf(entry.cx, entry.cz, sizeOf(entry.def)) do
		if cells[key] == entry then
			cells[key] = nil
		end
	end
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
	if open and playerTouching(entry.cx, entry.cz, sizeOf(entry.def), DOOR_MARGIN) then
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
	if entry.def.kind == "door" and BuildRules.areAllies(entry.owner.UserId, attacker.UserId) then
		toggleDoor(entry)
		return
	end
	entry.health = math.max(entry.health - BuildRules.damageOf(item), 0)
	entry.model:SetAttribute(StatNames.StructureHealth, entry.health)
	if entry.health <= 0 then
		remove(entry)
	end
end

-- Pode colocar uma peça size×size com o canto em (cx, cz)? Tudo do servidor.
local function canPlace(player: Player, cx: number, cz: number, size: number): boolean
	for _, key in BuildRules.cellsOf(cx, cz, size) do
		if cells[key] then
			return false
		end
	end
	if not BuildRules.underLimit(counts[player] or 0) then
		return false
	end
	for dx = 0, size - 1 do
		for dz = 0, size - 1 do
			local x, z = BuildRules.cellCenter(cx + dx, cz + dz)
			if WaterSim.isWet(x, z) then
				return false
			end
		end
	end
	local half = size * BuildRules.CELL / 2
	local x, z = (cx * BuildRules.CELL) + half, (cz * BuildRules.CELL) + half
	-- A peça de colisão (círculo) do recurso encosta no quadrado (aproximado
	-- pelo quadrado crescido do raio: recusa um pouco a mais nos cantos).
	for _, resource in ResourceService.near(x, z, half * math.sqrt(2) + RESOURCE_SEARCH) do
		if BuildRules.touches(resource.x, resource.z, cx, cz, size, resource.radius) then
			return false
		end
	end
	if playerTouching(cx, cz, size, PLAYER_MARGIN) then
		return false
	end
	return true
end

local function create(player: Player, itemId: string, def: Defs.StructureDef, cx: number, cz: number): boolean
	local size = sizeOf(def)
	local half = size * BuildRules.CELL / 2
	local x, z = (cx * BuildRules.CELL) + half, (cz * BuildRules.CELL) + half
	local ok, built = pcall(StructureModel.build, itemId, def)
	if not ok then
		warn(`[StructureService] modelo de {itemId}: {built}`)
		return false
	end
	local model = built :: Model
	model:PivotTo(CFrame.new(x, 0, z))
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
		cx = cx,
		cz = cz,
		x = x,
		z = z,
		radius = half,
		health = def.health,
	}
	for _, key in BuildRules.cellsOf(cx, cz, size) do
		cells[key] = entry
	end
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

	-- Fogo: apaga e some sozinho. Se já saiu antes (vida 0, dono morto),
	-- remove ignora (a entrada é a "ficha" desta peça; nunca é reaproveitada).
	local lifetime = def.lifetime
	if lifetime then
		task.delay(lifetime, remove, entry)
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
	local cx, cz = BuildRules.targetCell(root.Position.X, root.Position.Z, dir.X, dir.Z)
	if not canPlace(player, cx, cz, sizeOf(def)) then
		return
	end
	if not InventoryService.take(player, itemId, 1) then
		return
	end
	if not create(player, itemId, def, cx, cz) then
		InventoryService.give(player, itemId, 1)
	end
end

-- Coloca na descida de Using (true → false) deste personagem.
local function setupCharacter(player: Player, character: Model)
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
	Players.PlayerAdded:Connect(setupPlayer)
	for _, player in Players:GetPlayers() do
		setupPlayer(player)
	end
	-- Sair = morte: as peças do jogador somem.
	Players.PlayerRemoving:Connect(StructureService.removeOwned)
end

return StructureService
