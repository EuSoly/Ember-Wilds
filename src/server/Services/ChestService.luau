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

local ChestRules = require(ReplicatedStorage.Shared.Build.ChestRules)
local StatNames = require(ReplicatedStorage.Shared.StatNames)
local InventoryService = require(script.Parent.InventoryService)
local StructureService = require(script.Parent.StructureService)
local Net = require(script.Parent.Parent.Net)

-- Limite de taxa: até RATE_MAX pedidos de baú (pôr + tirar) por RATE_WINDOW
-- segundos, por jogador; o resto é ignorado.
local RATE_MAX = 10
local RATE_WINDOW = 1

type Entry = StructureService.Entry
type RateState = { start: number, count: number }

local contents: { [Entry]: ChestRules.Contents } = {}
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
	local dx, dz = root.Position.X - entry.x, root.Position.Z - entry.z
	if not (dx * dx + dz * dz <= ChestRules.RANGE * ChestRules.RANGE) then
		return nil
	end
	return entry
end

local function contentsOf(entry: Entry): ChestRules.Contents
	local c = contents[entry]
	if c == nil then
		c = { id = nil, count = 0 }
		contents[entry] = c
	end
	return c
end

-- Copia o conteúdo para os atributos do modelo (todos veem).
local function publish(entry: Entry, c: ChestRules.Contents)
	entry.model:SetAttribute(StatNames.ChestItem, c.id)
	entry.model:SetAttribute(StatNames.ChestCount, c.count)
end

-- Pôr `Count` (1 ou 10) do slot `Slot` no baú. Sem pausa até o fim.
local function onPut(player: Player, data: { Chest: Instance?, Slot: number, Count: number })
	if data.Chest == nil then
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
	local c = contentsOf(entry)
	-- canPut já corta no teto e devolve 0 para outro tipo de item.
	local amount = ChestRules.canPut(c, id, math.min(wanted, slot.count))
	if amount <= 0 then
		return
	end
	if not InventoryService.takeAt(player, index, amount) then
		return
	end
	local put = ChestRules.put(c, id, amount)
	if put < amount then
		-- Não acontece (nada mudou entre canPut e put); se acontecer, devolve.
		InventoryService.give(player, id, amount - put)
	end
	publish(entry, c)
end

-- Tirar do baú o quanto couber no inventário. Sem pausa até o fim.
local function onTake(player: Player, chest: Instance?)
	if chest == nil then
		return
	end
	local entry = validChest(player, chest)
	if entry == nil then
		return
	end
	local c = contents[entry]
	local id = c and c.id
	if c == nil or id == nil then
		return
	end
	-- Quanto cabe é calculado sem mudar o inventário; só depois tira e dá.
	local amount = math.min(c.count, InventoryService.spaceFor(player, id))
	if amount <= 0 then
		return
	end
	local takenId, taken = ChestRules.take(c, amount)
	if takenId == nil or taken <= 0 then
		return
	end
	local rest = InventoryService.give(player, takenId, taken)
	if rest > 0 then
		-- Não acontece (spaceFor = o que give aceita); se acontecer, volta ao baú.
		ChestRules.put(c, takenId, rest)
	end
	publish(entry, c)
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
