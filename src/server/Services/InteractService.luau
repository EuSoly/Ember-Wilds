--!strict
-- "Chegar perto e agir" nas estruturas (G8): extrator, fornalha, poço, cama e
-- placa. Este serviço só recebe o pedido (Net.StructureAction), confere e passa
-- ao tratador do tipo da peça; quem faz cada coisa é o serviço do tipo, que se
-- registra com InteractService.register(kind, handler).
--
-- Cada pedido é conferido inteiro (taxa, jogador vivo, peça registrada,
-- distância XZ até InteractRules.RANGE, ação permitida para o tipo e para quem
-- pede) e recusado calado se algo falhar, como no baú (ChestService). Tipo sem
-- tratador registrado: nada acontece.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildRules = require(ReplicatedStorage.Shared.Build.BuildRules)
local InteractRules = require(ReplicatedStorage.Shared.Build.InteractRules)
local StructureService = require(script.Parent.StructureService)
local Net = require(script.Parent.Parent.Net)

-- Limite de taxa: até RATE_MAX pedidos por RATE_WINDOW segundos, por jogador;
-- o resto é ignorado.
local RATE_MAX = 10
local RATE_WINDOW = 1

type Entry = StructureService.Entry
type RateState = { start: number, count: number }
-- Tratador de um tipo: já recebe o pedido conferido (`arg` ainda é do
-- cliente: o tratador confere se o valor serve para a ação).
export type Handler = (player: Player, entry: Entry, action: number, arg: number) -> ()

-- Tratadores por tipo (def.structure.kind). Tabela simples: registrar no
-- Init ou no Start de outro serviço, antes ou depois deste, funciona igual.
local handlers: { [string]: Handler } = {}
local rates: { [Player]: RateState } = {}

local InteractService = {}

-- Registra quem trata as ações do tipo `kind` (um por tipo; o último vale).
function InteractService.register(kind: string, handler: Handler)
	handlers[kind] = handler
end

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

-- `data` vem do cliente: Target pode ser nil ou qualquer Instance.
local function onAction(player: Player, data: { Target: Instance?, Action: number, Arg: number })
	if player.Parent ~= Players or not allow(player) then
		return
	end
	local target = data.Target
	local root = rootOf(player)
	if root == nil or typeof(target) ~= "Instance" or not target:IsA("Model") then
		return
	end
	-- entryOf só acha peças vivas e registradas (um modelo forjado ou já
	-- removido não está lá).
	local entry = StructureService.entryOf(target)
	if entry == nil then
		return
	end
	local dx, dz = root.Position.X - entry.x, root.Position.Z - entry.z
	if not (dx * dx + dz * dz <= InteractRules.RANGE * InteractRules.RANGE) then
		return
	end
	local kind = entry.def.kind
	local isOwner = BuildRules.areAllies(entry.owner.UserId, player.UserId)
	if not InteractRules.allowed(kind, data.Action, isOwner) then
		return
	end
	local handler = handlers[kind]
	if handler == nil then
		return
	end
	handler(player, entry, data.Action, data.Arg)
end

function InteractService.Start(_self)
	Net.StructureAction.On(onAction)
	Players.PlayerRemoving:Connect(function(player)
		rates[player] = nil
	end)
end

return InteractService
