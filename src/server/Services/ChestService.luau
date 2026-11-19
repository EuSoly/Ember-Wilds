--!strict
-- Conteúdo dos baús (G4). Baú = peça do StructureService com def.kind "chest".
-- O conteúdo (um tipo de item só, até ChestRules.MAX) vive SÓ aqui no servidor;
-- os atributos ChestItem/ChestCount no modelo são a cópia que todos veem.
--
-- O cliente só pede (ChestPut: pôr 1 ou 10 de um slot; ChestTake: tirar o
-- quanto couber). Cada pedido é conferido inteiro (taxa, jogador vivo, baú
-- registrado, distância XZ até ChestRules.RANGE, slot, quantidade, tipo) e
-- recusado calado se algo falhar. Entre conferir e mudar não há pausa (yield):
-- o pedido roda inteiro de uma vez, então dois jogadores no mesmo baú são
-- atendidos um depois do outro e nada duplica nem some.
--
-- Baú removido (vida 0, dono morto/saiu, apagado por fora): o conteúdo some
-- junto (como no Starve), pelo StructureService.onRemoved.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GhostRules = require(ReplicatedStorage.Shared.Survival.GhostRules)
local CreativeRules = require(ReplicatedStorage.Shared.Creative.CreativeRules)
local ChestRules = require(ReplicatedStorage.Shared.Build.ChestRules)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local CreativeService = require(script.Parent.CreativeService)
local InventoryService = require(script.Parent.InventoryService)
local StructureService = require(script.Parent.StructureService)
local TutorialService = require(script.Parent.TutorialService)
local Net = require(script.Parent.Parent.Net)

-- Limite de taxa: até RATE_MAX pedidos de baú (pôr + tirar) por RATE_WINDOW
-- segundos, por jogador; o resto é ignorado.
local RATE_MAX = 10
local RATE_WINDOW = 1

type Entry = StructureService.Entry
type RateState = { start: number, count: number }

local contents: { [Entry]: ChestRules.Chest } = {}
local rates: { [Player]: RateState } = {}

local ChestService = {}

-- Conta o pedido na janela atual; false = passou do limite (ignorar).
local function allow(player: Player): boolean
	local now = os.clock()
	local state = rates[player]
	if state == nil or now - state.start >= RATE_WINDOW then
		rates[player] = { start = now, count = 1 }
		return true
	end
	if state.count >= RATE_MAX then
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

-- Confere tudo que pôr e tirar têm em comum. Devolve a peça do baú, ou nil.
-- `chest` vem do cliente: pode ser nil ou qualquer Instance.
local function validChest(player: Player, chest: Instance?): Entry?
	-- Fantasma não usa baú (guardaria a arma e escaparia da perda ao ressuscitar).
	if GhostRules.isGhostPlayer(player, Workspace:GetServerTimeNow()) then
		return nil
	end
	if player.Parent ~= Players or not allow(player) then
		return nil
	end
	local root = rootOf(player)
	if root == nil or typeof(chest) ~= "Instance" or not chest:IsA("Model") then
		return nil
	end
	-- entryOf só acha peças vivas e registradas (um modelo forjado ou já
	-- removido não está lá).
	local entry = StructureService.entryOf(chest)
	if entry == nil or entry.def.kind ~= "chest" then
		return nil
	end
	-- Tutorial: o protegido só mexe nos próprios baús.
	if entry.owner ~= player and TutorialService.isProtected(player) then
		return nil
	end
	local dx, dz = root.Position.X - entry.x, root.Position.Z - entry.z
	if not (dx * dx + dz * dz <= ChestRules.RANGE * ChestRules.RANGE) then
		return nil
	end
	return entry
end

local function contentsOf(entry: Entry): ChestRules.Chest
	local chest = contents[entry]
	if chest == nil then
		chest = ChestRules.new()
		contents[entry] = chest
	end
	return chest
end

-- Copia o conteúdo dos 3 slots para os atributos do modelo (todos veem).
local function publish(entry: Entry, chest: ChestRules.Chest)
	for i = 1, ChestRules.SLOTS do
		local c = chest[i]
		entry.model:SetAttribute(StatNames.chestItem(i), if c then c.id else nil)
		entry.model:SetAttribute(StatNames.chestCount(i), if c then c.count else 0)
	end
end

-- Pôr `Count` (1 ou 10) do slot `Slot` no baú. Sem pausa até o fim.
local function onPut(player: Player, data: { Chest: Instance?, Slot: number, Count: number })
	-- Modo criativo não guarda em baú (os itens não passam para os outros).
	if data.Chest == nil or not CreativeRules.sharesItems(CreativeService.isOn(player)) then
		return
	end
	local entry = validChest(player, data.Chest)
	if entry == nil then
		return
	end
	local index, wanted = data.Slot, data.Count
	if wanted ~= 1 and wanted ~= 10 then
		return
	end
	local inv = InventoryService.get(player)
	if inv == nil or not (index >= 1 and index <= inv.capacity and index % 1 == 0) then
		return
	end
	local slot = inv.slots[index]
	if slot == nil then
		return
	end
	local id = slot.id
	local chest = contentsOf(entry)
	-- canPutAny já corta no teto e devolve 0 se os 3 slots já têm outros tipos.
	local amount = ChestRules.canPutAny(chest, id, math.min(wanted, slot.count))
	if amount <= 0 then
		return
	end
	if not InventoryService.takeAt(player, index, amount) then
		return
	end
	local put = ChestRules.putAny(chest, id, amount)
	if put < amount then
		-- Não acontece (nada mudou entre canPutAny e putAny); se acontecer, devolve.
		InventoryService.give(player, id, amount - put)
	end
	publish(entry, chest)
end

-- Tirar do slot do baú o quanto couber no inventário. Sem pausa até o fim.
local function onTake(player: Player, data: any)
	-- Aceita tanto { Chest, Slot } quanto Instance puro (clientes antigos durante update -> slot 1).
	local chestInstance: Instance? = if typeof(data) == "Instance"
		then data
		elseif type(data) == "table" then data.Chest
		else nil
	local slotIndex: number = if type(data) == "table" and type(data.Slot) == "number" then data.Slot else 1
	if chestInstance == nil then
		return
	end
	local entry = validChest(player, chestInstance)
	if entry == nil then
		return
	end
	local chest = contents[entry]
	local c = chest and chest[slotIndex]
	local id = c and c.id
	if chest == nil or c == nil or id == nil then
		return
	end
	-- Quanto cabe é calculado sem mudar o inventário; só depois tira e dá.
	local amount = math.min(c.count, InventoryService.spaceFor(player, id))
	if amount <= 0 then
		Net.CraftNotice.Fire(player, "inventory.full")
		return
	end
	local hadMore = amount < c.count
	local takenId, taken = ChestRules.takeAt(chest, slotIndex, amount)
	if takenId == nil or taken <= 0 then
		return
	end
	local rest = InventoryService.give(player, takenId, taken)
	if rest > 0 then
		-- Não acontece (spaceFor = o que give aceita); se acontecer, volta ao baú.
		ChestRules.put(c, takenId, rest)
		Net.CraftNotice.Fire(player, "inventory.full")
	elseif hadMore then
		Net.CraftNotice.Fire(player, "inventory.full")
	end
	publish(entry, chest)
end

function ChestService.Start(_self)
	-- O conteúdo some com o baú (a "ficha" da peça nunca é reaproveitada).
	StructureService.onRemoved(function(entry: Entry)
		contents[entry] = nil
	end)
	Net.ChestPut.On(onPut)
	Net.ChestTake.On(onTake)
	Players.PlayerRemoving:Connect(function(player)
		rates[player] = nil
	end)
end

return ChestService
