--!strict
-- Mostra um boneco visual para cada personagem com a tag Boneco (o seu e os
-- dos outros). Um único loop, antes do render, faz cada boneco seguir o
-- HumanoidRootPart, anima (BonecoAnim) e troca a expressão (ExpressionState).
-- Tudo o que o visual precisa vem de atributos replicados no personagem
-- (Using, Equipped, HurtAt, Cosmetic_body): todos veem a mesma coisa.
-- Esses atributos são lidos a cada quadro (polling), não por sinal: veja
-- syncAttributes. O visual nunca entra na simulação: fica numa pasta local e
-- não replica.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local BonecoAnim = require(Shared:WaitForChild("BonecoAnim"))
local C = require(Shared:WaitForChild("BonecoConfig"))
local Cosmetic = require(Shared:WaitForChild("Cosmetic"))
local Defs = require(Shared:WaitForChild("Defs"))
local ExpressionState = require(Shared:WaitForChild("ExpressionState"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local BonecoModel = require(script.Parent:WaitForChild("BonecoModel"))

local ROOT_TIMEOUT = 10
local BODY_SLOT = "body"
-- Evento que a expressão de dano escuta (Defs/Expressions: event = "hurt").
local HURT_EVENT = "hurt"
local RENDER_NAME = "Boneco"
-- Pivô do golpe: centro do corpo, na altura das mãos (a mão faz um arco pela frente).
local SWING_PIVOT = CFrame.new(0, C.VISUAL_OFFSET_Y + C.HAND_Y, 0)

type Entry = {
	character: Model,
	hrp: BasePart,
	boneco: BonecoModel.Boneco,
	anim: BonecoAnim.State,
	expression: ExpressionState.State,
	hasTool: boolean,
	lastPosition: Vector3,
	eyes: Defs.EyeStyle,
	flash: string?,
	-- Últimos valores lidos dos atributos (para só reagir quando mudam).
	cosmeticId: string?,
	equippedId: string?,
	hurtAt: number?,
	connections: { RBXScriptConnection },
}

local BonecoRenderer = {}

local entries: { [Model]: Entry } = {}
-- Personagens esperando o HumanoidRootPart (para nunca montar dois visuais).
local pending: { [Model]: boolean } = {}
local started = false

local function isAlive(character: Model): boolean
	return character:IsDescendantOf(Workspace) and CollectionService:HasTag(character, StatNames.BonecoTag)
end

local function displayNameOf(character: Model): string
	local player = Players:GetPlayerFromCharacter(character)
	return if player then player.DisplayName else character.Name
end

-- Condição de uma expressão (ex. frio): lê o atributo no Player do personagem
-- (ou no próprio modelo, nos bonecos de teste) e compara com o limiar.
local function conditionHolds(character: Model, def: Defs.ExpressionDef): boolean
	local condition = def.condition
	if condition == nil then
		return false
	end
	local owner: Instance = Players:GetPlayerFromCharacter(character) or character
	local value = owner:GetAttribute(condition.attribute)
	if type(value) ~= "number" then
		return false
	end
	if condition.below ~= nil and value < condition.below then
		return true
	end
	return condition.above ~= nil and value > condition.above
end

local function remove(character: Model)
	pending[character] = nil
	local entry = entries[character]
	if entry == nil then
		return
	end
	entries[character] = nil
	for _, connection in entry.connections do
		connection:Disconnect()
	end
	BonecoModel.destroy(entry.boneco)
end

local function stringAttribute(character: Model, name: string): string?
	local value = character:GetAttribute(name)
	return if type(value) == "string" then value else nil
end

local function numberAttribute(character: Model, name: string): number?
	local value = character:GetAttribute(name)
	return if type(value) == "number" then value else nil
end

local function applyCosmetic(entry: Entry, id: string?)
	entry.cosmeticId = id
	local cosmetic = Cosmetic.resolve(Defs, BODY_SLOT, id)
	if cosmetic.body then
		BonecoModel.applyLook(entry.boneco, cosmetic.body)
	end
end

local function applyEquipped(entry: Entry, id: string?)
	entry.equippedId = id
	entry.hasTool = BonecoModel.setHeldItem(entry.boneco, id)
end

-- Só mostra a careta se o dano for recente: um HurtAt antigo chega quando o
-- personagem entra no alcance do streaming e não deve tocar a expressão.
-- O relógio do servidor só serve para essa checagem; a expressão usa os.clock.
local function checkHurt(entry: Entry, hurtAt: number?)
	entry.hurtAt = hurtAt
	if ExpressionState.isRecent(hurtAt, Workspace:GetServerTimeNow(), C.HURT_RECENT) then
		ExpressionState.trigger(entry.expression, HURT_EVENT, os.clock())
	end
end

-- Lê os atributos do personagem e reage só ao que mudou desde a última leitura.
-- Por que polling e não GetAttributeChangedSignal: com Server Authority, o
-- personagem do jogador local é previsto pelo cliente, e o sinal de atributo
-- não dispara para ele quando o valor chega do servidor (verificado no Studio:
-- o valor chega, o sinal não). Ler a cada quadro funciona para todos os
-- personagens e custa só três GetAttribute por boneco.
local function syncAttributes(entry: Entry)
	local character = entry.character
	local cosmeticId = stringAttribute(character, StatNames.CosmeticPrefix .. BODY_SLOT)
	if cosmeticId ~= entry.cosmeticId then
		applyCosmetic(entry, cosmeticId)
	end
	local equippedId = stringAttribute(character, StatNames.Equipped)
	if equippedId ~= entry.equippedId then
		applyEquipped(entry, equippedId)
	end
	local hurtAt = numberAttribute(character, StatNames.HurtAt)
	if hurtAt ~= entry.hurtAt then
		checkHurt(entry, hurtAt)
	end
end

local function build(character: Model, hrp: BasePart)
	local boneco = BonecoModel.build(displayNameOf(character))
	boneco.root.CFrame = hrp.CFrame
	local entry: Entry = {
		character = character,
		hrp = hrp,
		boneco = boneco,
		anim = BonecoAnim.newState(),
		expression = ExpressionState.new(),
		hasTool = false,
		lastPosition = hrp.Position,
		eyes = "open",
		flash = nil,
		cosmeticId = nil,
		equippedId = nil,
		hurtAt = nil,
		connections = {},
	}
	entries[character] = entry

	-- Estado inicial (a skin padrão já veio do build; o resto vem do polling).
	applyCosmetic(entry, stringAttribute(character, StatNames.CosmeticPrefix .. BODY_SLOT))
	applyEquipped(entry, stringAttribute(character, StatNames.Equipped))
	checkHurt(entry, numberAttribute(character, StatNames.HurtAt))

	local function listen(signal: RBXScriptSignal, handler: () -> ())
		table.insert(entry.connections, signal:Connect(handler))
	end
	-- Atributos são lidos por polling (syncAttributes); estes sinais de vida da
	-- instância funcionam normalmente com Server Authority.
	-- Personagem destruído ou tirado do Workspace (respawn, streaming): some o visual.
	listen(character.Destroying, function()
		remove(character)
	end)
	listen(character.AncestryChanged, function()
		if not character:IsDescendantOf(Workspace) then
			remove(character)
		end
	end)
end

local function add(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	local character = instance
	if entries[character] or pending[character] then
		return
	end
	pending[character] = true
	task.spawn(function()
		local hrp = character:WaitForChild("HumanoidRootPart", ROOT_TIMEOUT)
		-- Saiu enquanto esperava (remove limpou o pending): não monta.
		if not pending[character] then
			return
		end
		pending[character] = nil
		-- Desiste em silêncio: sem raiz não há o que seguir.
		if hrp == nil or not hrp:IsA("BasePart") or not isAlive(character) then
			return
		end
		build(character, hrp)
	end)
end

-- Transform da mão direita: deslocamento (x, y, z) mais o giro `yaw` em torno
-- do pivô do golpe (centro do corpo), escrito nas coordenadas da junta.
local function rightHandTransform(c0: CFrame, hand: BonecoAnim.HandPose): CFrame
	local swing = SWING_PIVOT * CFrame.Angles(0, hand.yaw, 0) * SWING_PIVOT:Inverse()
	return c0:Inverse() * swing * c0 * CFrame.new(hand.x, hand.y, hand.z)
end

local function animate(entry: Entry, dt: number, speed: number, now: number)
	local boneco = entry.boneco
	local character = entry.character
	local pose = BonecoAnim.step(entry.anim, dt, {
		speed = speed,
		using = character:GetAttribute(StatNames.Using) == true,
		hasTool = entry.hasTool,
	})
	boneco.bodyJoint.Transform = CFrame.new(0, pose.bodyY, 0)
	boneco.leftHandJoint.Transform = CFrame.new(pose.left.x, pose.left.y, pose.left.z)
	boneco.rightHandJoint.Transform = rightHandTransform(boneco.rightHandJoint.C0, pose.right)

	-- Cada boneco sorteia o próprio piscar (math.random), e só troca as peças
	-- quando a expressão ou o flash mudam de fato.
	local def = ExpressionState.current(entry.expression, Defs.Expressions, now, math.random, function(d)
		return conditionHolds(character, d)
	end)
	if def.eyes ~= entry.eyes then
		entry.eyes = def.eyes
		BonecoModel.setEyes(boneco, def.eyes)
	end
	local flash = ExpressionState.flashColor(entry.expression, Defs.Expressions, now)
	if flash ~= entry.flash then
		entry.flash = flash
		BonecoModel.setFlash(boneco, flash)
	end
end

local function update(dt: number)
	local camera = Workspace.CurrentCamera
	local cameraPosition = if camera then camera.CFrame.Position else nil
	local now = os.clock()

	local roots: { BasePart } = {}
	local cframes: { CFrame } = {}
	local toAnimate: { Entry } = {}
	local speeds: { number } = {}

	for _, entry in entries do
		-- Todo boneco, inclusive os longe da câmera (skin e item certos ao chegar perto).
		syncAttributes(entry)

		local hrp = entry.hrp
		if hrp.Parent == nil then
			continue -- raiz saiu (ex. streaming): o visual espera o personagem sumir
		end
		local target = hrp.CFrame
		table.insert(roots, entry.boneco.root)
		table.insert(cframes, target)

		-- Velocidade no plano, pela distância andada desde o quadro anterior.
		local delta = target.Position - entry.lastPosition
		entry.lastPosition = target.Position
		local speed = if dt > 0 then Vector2.new(delta.X, delta.Z).Magnitude / dt else 0

		-- Longe da câmera só segue a posição (economiza a animação).
		if cameraPosition == nil or (target.Position - cameraPosition).Magnitude <= C.ANIM_RANGE then
			table.insert(toAnimate, entry)
			table.insert(speeds, speed)
		end
	end

	-- Uma chamada só move todas as raízes (bem mais barato que CFrame um a um).
	if #roots > 0 then
		Workspace:BulkMoveTo(roots, cframes, Enum.BulkMoveMode.FireCFrameChanged)
	end
	for i, entry in toAnimate do
		animate(entry, dt, speeds[i], now)
	end
end

-- Liga o renderer (chamado uma vez pelo BonecoController).
function BonecoRenderer.start()
	if started then
		return
	end
	started = true

	CollectionService:GetInstanceAddedSignal(StatNames.BonecoTag):Connect(add)
	CollectionService:GetInstanceRemovedSignal(StatNames.BonecoTag):Connect(function(instance)
		if instance:IsA("Model") then
			remove(instance)
		end
	end)
	for _, character in CollectionService:GetTagged(StatNames.BonecoTag) do
		add(character)
	end

	-- Prioridade Character: depois da câmera e do input, antes do desenho do
	-- quadro, para o boneco não ficar um quadro atrás do personagem.
	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Character.Value, update)
end

return BonecoRenderer
