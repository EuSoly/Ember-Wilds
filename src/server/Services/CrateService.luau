--!strict
-- Caixas de itens (G6): todo morto vira uma caixa que qualquer jogador saqueia.
-- Cada caixa é um círculo no chão (centro x, z, raio CrateRules.RADIUS) num
-- índice espacial só do servidor (SpatialGrid), com vida, tempo de vida e o
-- conteúdo em slots (lista em ordem, sem buracos). O conteúdo vive SÓ aqui; o
-- cliente recebe a cópia por Net.CrateContents enquanto olha a caixa.
--
-- - Jogador morto (DeathService.onDeath, antes de a morte zerar tudo): os slots
--   do inventário (com os da mochila), a mochila vestida e a armadura vestida
--   viram a caixa, no lugar da morte. Skin = CrateRules.skinFor(skin de caixa
--   de quem matou, a do morto). Sem item nenhum: sem caixa. Só copia: quem zera
--   o inventário, a mochila e a armadura é o DeathService, logo depois.
-- - Mob morto (MobService.onDeath): caixa com o loot dos dados, modelo = id do mob.
-- - Olhar (CrateWatch): o cliente diz qual caixa está olhando; o servidor
--   confere a distância (com folga) e manda o conteúdo agora e a cada mudança.
-- - Pegar (CrateTake): confere taxa, jogador vivo, caixa viva, distância XZ até
--   OPEN_RANGE e o slot, que ainda tem de guardar o item que o cliente mostra
--   (ItemId; os slots sobem quando um esvazia, e um índice velho cairia noutro
--   item): diferente → não entrega e reenvia o conteúdo a quem pediu. Dá o
--   que couber (InventoryService.give devolve a sobra) e deixa o resto. Entre conferir e mudar não há pausa (yield): dois
--   jogadores no mesmo slot são atendidos um depois do outro, e o segundo leva
--   o que sobrou (ou nada). Vazia → some.
-- - Golpe (GatherService): tira vida (BuildRules.damageOf, como as peças); vida
--   0 → some com os itens. Também some sozinha no fim do tempo de vida.
-- Toda remoção passa por `remove` (idempotente): sai do índice e das tabelas
-- antes de o modelo sumir, então pedido nenhum acha uma caixa que já se foi.
-- Studio: ServerStorage.DevCrate:Invoke(player) cria uma caixa com alguns
-- itens na frente do jogador.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local BuildRules = require(ReplicatedStorage.Shared.Build.BuildRules)
local CrateModel = require(ReplicatedStorage.Shared.Models.CrateModel)
local CrateRules = require(ReplicatedStorage.Shared.Crate.CrateRules)
local Defs = require(ReplicatedStorage.Shared.Defs)
local SpatialGrid = require(ReplicatedStorage.Shared.World.SpatialGrid)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local CosmeticService = require(script.Parent.CosmeticService)
local DeathService = require(script.Parent.DeathService)
local InventoryService = require(script.Parent.InventoryService)
local MobService = require(script.Parent.MobService)
local Net = require(script.Parent.Parent.Net)

-- Studs por célula do índice espacial.
local GRID_CELL = 8
-- Maior quantidade de um slot no contrato (Slot.Count: u16).
local MAX_COUNT = 65535
-- Folga do "olhar" além do OPEN_RANGE: a posição que o cliente vê pode estar
-- um pouco atrás da do servidor. Pegar usa o OPEN_RANGE exato.
local WATCH_SLACK = 4
-- Limites de taxa por jogador, por janela de RATE_WINDOW segundos; o resto é
-- ignorado. Olhar é mais folgado (troca ao andar entre caixas).
local TAKE_RATE_MAX = 10
local WATCH_RATE_MAX = 20
local RATE_WINDOW = 1
local CRATE_SLOT = "crate" -- slot de cosmético da skin de caixa

export type Item = { id: string, count: number }

export type Entry = {
	model: Model,
	x: number, -- centro do círculo (studs)
	z: number,
	radius: number,
	health: number,
	slots: { Item }, -- em ordem, sem buracos (nunca vazia enquanto viva)
}

type RateState = { start: number, count: number }

local CrateService = {}

local grid = SpatialGrid.new(GRID_CELL)
local alive: { [Entry]: boolean } = {}
local byModel: { [Model]: Entry } = {}
-- Quem está olhando cada caixa, e a caixa que cada jogador olha.
local watchers: { [Entry]: { [Player]: boolean } } = {}
local watching: { [Player]: Entry } = {}
local takeRates: { [Player]: RateState } = {}
local watchRates: { [Player]: RateState } = {}
local folder: Folder? = nil

local function getFolder(): Folder
	local current = folder
	if current == nil or current.Parent == nil then
		local created = Instance.new("Folder")
		created.Name = "Crates"
		created.Parent = Workspace
		current = created
		folder = created
	end
	return current :: Folder
end

-- Conta o pedido na janela atual; false = passou do limite (ignorar).
local function allow(rates: { [Player]: RateState }, player: Player, max: number): boolean
	local now = os.clock()
	local state = rates[player]
	if state == nil or now - state.start >= RATE_WINDOW then
		rates[player] = { start = now, count = 1 }
		return true
	end
	if state.count >= max then
		return false
	end
	state.count += 1
	return true
end

-- Raiz do personagem vivo do jogador, ou nil (fora do jogo, no menu, morto).
local function rootOf(player: Player): BasePart?
	local character = player.Character
	if character == nil or character.Parent == nil then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if humanoid == nil or humanoid.Health <= 0 or root == nil or not root:IsA("BasePart") then
		return nil
	end
	return root
end

local function toNet(entry: Entry): { Net.Slot }
	local list: { Net.Slot } = {}
	for _, item in entry.slots do
		table.insert(list, { Id = item.id, Count = item.count })
	end
	return list
end

-- Manda o conteúdo para quem olha a caixa (só quem ainda está no jogo).
local function publish(entry: Entry)
	local set = watchers[entry]
	if set == nil then
		return
	end
	local list: { Player } = {}
	for player in set do
		if player.Parent == Players then
			table.insert(list, player)
		end
	end
	if #list > 0 then
		Net.CrateContents.FireList(list, { Crate = entry.model, Slots = toNet(entry) })
	end
end

-- O jogador deixa de olhar a caixa que olhava (se olhava).
local function unwatch(player: Player)
	local entry = watching[player]
	if entry == nil then
		return
	end
	watching[player] = nil
	local set = watchers[entry]
	if set then
		set[player] = nil
		if next(set) == nil then
			watchers[entry] = nil
		end
	end
end

-- Único caminho de remoção (vazia, vida 0, tempo, apagada por fora): tira do
-- índice e das tabelas e só então destrói o modelo. Idempotente.
local function remove(entry: Entry)
	if not alive[entry] then
		return
	end
	alive[entry] = nil
	grid:remove(entry, entry.x, entry.z)
	byModel[entry.model] = nil
	local set = watchers[entry]
	if set then
		for player in set do
			if watching[player] == entry then
				watching[player] = nil
			end
		end
		watchers[entry] = nil
	end
	table.clear(entry.slots)
	entry.model:Destroy()
end

-- Copia só os itens válidos (id nos Defs, quantidade inteira positiva),
-- quebrando em slots de até MAX_COUNT (o limite do contrato).
local function sanitize(slots: { Item }): { Item }
	local clean: { Item } = {}
	for _, item in slots do
		local count = item.count
		if type(item.id) ~= "string" or Defs.Items[item.id] == nil then
			continue
		end
		if type(count) ~= "number" or not (count >= 1 and count < math.huge) or count % 1 ~= 0 then
			continue
		end
		while count > 0 do
			local part = math.min(count, MAX_COUNT)
			table.insert(clean, { id = item.id, count = part })
			count -= part
		end
	end
	return clean
end

-- Cria uma caixa com o centro em (x, z), no chão (Y = 0, como as peças de
-- construção). Devolve o modelo, ou nil se não há item válido ou o modelo falhou.
function CrateService.spawn(
	x: number,
	z: number,
	slots: { { id: string, count: number } },
	modelId: string,
	lifetime: number
): Model?
	if not (x == x and z == z and math.abs(x) < math.huge and math.abs(z) < math.huge) then
		return nil
	end
	local items = sanitize(slots)
	if #items == 0 then
		return nil
	end
	local ok, built = pcall(CrateModel.build, modelId)
	if not ok then
		warn(`[CrateService] modelo {modelId}: {built}`)
		return nil
	end
	local model = built :: Model
	model:PivotTo(CFrame.new(x, 0, z))
	model:SetAttribute(StatNames.StructureHealth, CrateRules.HEALTH)
	model:SetAttribute(StatNames.StructureHealthMax, CrateRules.HEALTH)
	model:AddTag(StatNames.CrateTag)

	local entry: Entry = {
		model = model,
		x = x,
		z = z,
		radius = CrateRules.RADIUS,
		health = CrateRules.HEALTH,
		slots = items,
	}
	grid:insert(entry, x, z)
	alive[entry] = true
	byModel[model] = entry
	model.Parent = getFolder()
	-- Apagada por fora (comando, outro script, pasta destruída): sai igual.
	-- O Destroy do próprio remove volta aqui e não faz nada.
	model.Destroying:Connect(function()
		remove(entry)
	end)
	model.AncestryChanged:Connect(function()
		if not model:IsDescendantOf(Workspace) then
			remove(entry)
		end
	end)
	-- A entrada é a "ficha" desta caixa (nunca reaproveitada): se já saiu, ignora.
	task.delay(lifetime, remove, entry)
	return model
end

-- Caixas vivas cujo círculo encosta (ou entra) no círculo (x, z, radius).
function CrateService.near(x: number, z: number, radius: number): { Entry }
	local found: { Entry } = {}
	if not (radius >= 0) then
		return found
	end
	for _, item in grid:query(x, z, radius + CrateRules.RADIUS) do
		local entry = item :: Entry
		if alive[entry] and BuildRules.touchesCircle(x, z, entry.x, entry.z, entry.radius, radius) then
			table.insert(found, entry)
		end
	end
	return found
end

-- Golpe numa caixa. `item` = o que está na mão de quem bateu (nil = mão).
-- Vida 0: some com tudo dentro.
function CrateService.hit(entry: Entry, _attacker: Player, item: Defs.ItemDef?)
	if not alive[entry] then
		return
	end
	entry.health = math.max(entry.health - BuildRules.damageOf(item), 0)
	entry.model:SetAttribute(StatNames.StructureHealth, entry.health)
	if entry.health <= 0 then
		remove(entry)
	end
end

-- A caixa viva deste modelo a até `range` (XZ) da raiz do jogador vivo, ou nil.
-- `crate` vem do cliente: pode ser nil ou qualquer Instance.
local function crateInReach(player: Player, crate: Instance?, range: number): Entry?
	if typeof(crate) ~= "Instance" or not crate:IsA("Model") then
		return nil
	end
	-- byModel só tem caixas vivas (um modelo forjado ou já removido não está lá).
	local entry = byModel[crate :: any]
	local root = rootOf(player)
	if entry == nil or root == nil then
		return nil
	end
	local dx, dz = root.Position.X - entry.x, root.Position.Z - entry.z
	if not (dx * dx + dz * dz <= range * range) then
		return nil
	end
	return entry
end

local function onWatch(player: Player, crate: Instance?)
	if player.Parent ~= Players or not allow(watchRates, player, WATCH_RATE_MAX) then
		return
	end
	local entry = crateInReach(player, crate, CrateRules.OPEN_RANGE + WATCH_SLACK)
	if entry ~= nil and watching[player] == entry then
		-- Mesma caixa de novo: só reenvia o conteúdo.
		Net.CrateContents.Fire(player, { Crate = entry.model, Slots = toNet(entry) })
		return
	end
	unwatch(player)
	if entry == nil then
		return
	end
	watching[player] = entry
	local set = watchers[entry]
	if set == nil then
		set = {}
		watchers[entry] = set
	end
	set[player] = true
	Net.CrateContents.Fire(player, { Crate = entry.model, Slots = toNet(entry) })
end

-- Pegar um slot: leva o que couber, o resto fica. Sem pausa até o fim.
local function onTake(player: Player, data: { Crate: Instance?, Slot: number, ItemId: string })
	if player.Parent ~= Players or not allow(takeRates, player, TAKE_RATE_MAX) then
		return
	end
	local entry = crateInReach(player, data.Crate, CrateRules.OPEN_RANGE)
	if entry == nil then
		return
	end
	local index = data.Slot
	local slot = entry.slots[index]
	if slot == nil or slot.id ~= data.ItemId then
		-- O cliente viu uma lista velha: manda a atual para o painel acertar.
		Net.CrateContents.Fire(player, { Crate = entry.model, Slots = toNet(entry) })
		return
	end
	local given = slot.count - InventoryService.give(player, slot.id, slot.count)
	if given <= 0 then
		return
	end
	slot.count -= given
	if slot.count <= 0 then
		table.remove(entry.slots, index)
	end
	if #entry.slots == 0 then
		remove(entry)
	else
		publish(entry)
	end
end

-- Itens do morto, em ordem: slots do inventário (com os da mochila), a
-- mochila vestida e a armadura vestida. Só lê; a morte zera depois.
local function belongingsOf(player: Player): { Item }
	local items: { Item } = {}
	local inv = InventoryService.get(player)
	if inv then
		for index = 1, inv.capacity do
			local slot = inv.slots[index]
			if slot then
				table.insert(items, { id = slot.id, count = slot.count })
			end
		end
	end
	local bag = player:GetAttribute(StatNames.Bag)
	if type(bag) == "string" then
		table.insert(items, { id = bag, count = 1 })
	end
	local armor = player:GetAttribute(StatNames.Armor)
	if type(armor) == "string" then
		table.insert(items, { id = armor, count = 1 })
	end
	return items
end

-- Ouvinte do DeathService: sem pausa (a morte espera os ouvintes).
local function onPlayerDeath(player: Player, character: Model, killer: Player?)
	local items = belongingsOf(player)
	if #items == 0 then
		return
	end
	-- Sem raiz (caiu do mapa: o Roblox a apagou), usa o pivô do personagem.
	local root = character:FindFirstChild("HumanoidRootPart")
	local position = if root and root:IsA("BasePart") then root.Position else character:GetPivot().Position
	local killerSkin = if killer and killer.Parent == Players then CosmeticService.equipped(killer, CRATE_SLOT) else nil
	local skin = CrateRules.skinFor(killerSkin, CosmeticService.equipped(player, CRATE_SLOT))
	CrateService.spawn(position.X, position.Z, items, skin, CrateRules.PLAYER_LIFETIME)
end

local function onMobDeath(mob: MobService.Mob, _killer: Player?)
	local loot = mob.def.loot
	if loot == nil or #loot == 0 then
		return
	end
	CrateService.spawn(mob.x, mob.z, loot, mob.id, CrateRules.MOB_LIFETIME)
end

-- Studio: ServerStorage.DevCrate:Invoke(player) → caixa com alguns itens a
-- DEV_DISTANCE studs à frente do jogador (skin de caixa dele).
local DEV_DISTANCE = 6
local DEV_ITEMS: { Item } = {
	{ id = "wood", count = 30 },
	{ id = "stone", count = 12 },
	{ id = "raw_meat", count = 3 },
	{ id = "wolf_fur", count = 1 },
	{ id = "stone_pickaxe", count = 1 },
}

local function setupDev()
	local devCrate = Instance.new("BindableFunction")
	devCrate.Name = "DevCrate"
	devCrate.OnInvoke = function(player: Player): Model?
		local root = rootOf(player)
		if root == nil then
			return nil
		end
		local look = root.CFrame.LookVector
		local flat = Vector3.new(look.X, 0, look.Z)
		local dir = if flat.Magnitude > 1e-3 then flat.Unit else Vector3.new(0, 0, -1)
		local point = root.Position + dir * DEV_DISTANCE
		local skin = CosmeticService.equipped(player, CRATE_SLOT)
		return CrateService.spawn(point.X, point.Z, DEV_ITEMS, skin, CrateRules.PLAYER_LIFETIME)
	end
	devCrate.Parent = ServerStorage
end

function CrateService.Start(_self)
	getFolder()
	DeathService.onDeath(onPlayerDeath)
	MobService.onDeath(onMobDeath)
	Net.CrateWatch.On(onWatch)
	Net.CrateTake.On(onTake)
	Players.PlayerRemoving:Connect(function(player)
		unwatch(player)
		takeRates[player] = nil
		watchRates[player] = nil
	end)
	if RunService:IsStudio() then
		setupDev()
	end
end

return CrateService
