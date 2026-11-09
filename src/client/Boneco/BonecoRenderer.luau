--!strict
-- Mostra um boneco visual para cada personagem com a tag Boneco (o seu e os
-- dos outros). Um único loop, antes do render, faz cada boneco seguir o
-- HumanoidRootPart, anima (BonecoAnim) e troca a expressão (ExpressionState).
-- Tudo o que o visual precisa vem de atributos replicados no personagem
-- (Using, Equipped, HurtAt, EatUntil, Cosmetic_body): todos veem a mesma coisa.
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
local EatRules = require(Shared:WaitForChild("Survival"):WaitForChild("EatRules"))
local ExpressionState = require(Shared:WaitForChild("ExpressionState"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local SurvivalConfig = require(Shared:WaitForChild("SurvivalConfig"))
local ToolModel = require(Shared:WaitForChild("Models"):WaitForChild("ToolModel"))
local Validate = require(Shared:WaitForChild("Defs"):WaitForChild("Validate"))
local BagFx = require(script.Parent:WaitForChild("BagFx"))
local BonecoModel = require(script.Parent:WaitForChild("BonecoModel"))
local SkinAnimator = require(script.Parent:WaitForChild("SkinAnimator"))
local BagModel = require(script.Parent.Parent:WaitForChild("Menu"):WaitForChild("Cosmetics"):WaitForChild("BagModel"))
local CraftState = require(script.Parent.Parent:WaitForChild("CraftState"))

local ROOT_TIMEOUT = 10
local BODY_SLOT = "body"
local BAG_SLOT = "bag"
local BOOK_SLOT = "book"
-- Evento que a expressão de dano escuta (um dos Validate.KNOWN_EVENTS).
local HURT_EVENT = Validate.HURT_EVENT
local EAT_EVENT = Validate.EAT_EVENT
local CRUMBS_PER_BITE = 7
-- Progresso (0 a 1) de cada mordida, quando caem os farelos.
local BITES = BonecoAnim.eatBites()
-- Pasta dos bonecos de teste (DevBonecoService): o nome deles é o do modelo.
local DEV_CROWD_FOLDER = "DevCrowd"
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
	thrust: boolean, -- o item na mão golpeia com estocada (attackAnim "thrust")
	food: boolean, -- o item na mão é comida (o botão come, não golpeia)
	crumbColor: string?,
	eatUntil: number?,
	eatProgress: number?, -- progresso da mordida no quadro anterior (farelos)
	lastPosition: Vector3,
	eyes: Defs.EyeStyle,
	flash: string?,
	-- Últimos valores lidos dos atributos (para só reagir quando mudam).
	cosmeticId: string?,
	bagCosmeticId: string?,
	bagModel: Model?,
	bagFx: BagFx.Fx?, -- partículas da mochila (só as dos pacotes do lançamento)
	-- Peças animadas da skin e do livro na mão (SkinAnimator); nil = recoletar
	-- (trocou a skin ou o item na mão).
	skinJoints: { SkinAnimator.Joint }?,
	bookCosmeticId: string?,
	equippedId: string?,
	hurtAt: number?,
	-- Sem raiz no personagem: o visual fica escondido até ela voltar.
	hidden: boolean,
	-- false enquanto o nome mostrado ainda não é o DisplayName do jogador.
	nameResolved: boolean,
	connections: { RBXScriptConnection },
}

local BonecoRenderer = {}

local entries: { [Model]: Entry } = {}
-- Personagens esperando o HumanoidRootPart. Cada chamada de add guarda uma
-- ficha própria: se o personagem sair e voltar durante a espera, só a chamada
-- mais nova monta o visual (nunca dois visuais para o mesmo personagem).
local pending: { [Model]: {} } = {}
local started = false

local function isAlive(character: Model): boolean
	return character:IsDescendantOf(Workspace) and CollectionService:HasTag(character, StatNames.BonecoTag)
end

local function isDevCrowd(character: Model): boolean
	local parent = character.Parent
	return parent ~= nil and parent.Name == DEV_CROWD_FOLDER
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
	if value == nil then
		-- Estado do personagem (ex. Sleeping) fica no próprio modelo, não no Player.
		value = character:GetAttribute(condition.attribute)
	end
	return ExpressionState.conditionMet(condition, value)
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
	entry.skinJoints = nil
	local cosmetic = Cosmetic.resolve(Defs, BODY_SLOT, id)
	if cosmetic.body then
		BonecoModel.applyLook(entry.boneco, cosmetic.body, cosmetic.id)
	end
end

local function applyBag(entry: Entry, id: string?)
	entry.bagCosmeticId = id
	if entry.bagModel then
		entry.bagModel:Destroy()
		entry.bagModel = nil
	end
	entry.bagFx = nil
	local cosmetic = Cosmetic.resolve(Defs, BAG_SLOT, id)
	if cosmetic.bag then
		local bag = BagModel.build(cosmetic.bag, cosmetic.id)
		BagModel.attach(bag, entry.boneco)
		entry.bagModel = bag
		entry.bagFx = BagFx.attach(bag, cosmetic.id)
	end
end

local function applyEquipped(entry: Entry, id: string?, bookCosmeticId: string?)
	entry.equippedId = id
	entry.bookCosmeticId = bookCosmeticId
	entry.skinJoints = nil
	local bookResolved = Cosmetic.resolve(Defs, BOOK_SLOT, bookCosmeticId)
	entry.hasTool = BonecoModel.setHeldItem(entry.boneco, id, bookResolved.id)
	entry.thrust = id ~= nil and ToolModel.attackAnimOf(id) == "thrust"
	local def = if id then Defs.Items[id] else nil
	local food = def and def.food
	entry.food = food ~= nil
	entry.crumbColor = if food then food.crumbColor else nil
end

-- Mordida nova (EatUntil no futuro): olhos "^ ^". Sem mordida (terminou ou foi
-- cancelada): limpa a expressão na hora.
local function checkEat(entry: Entry, eatUntil: number?)
	entry.eatUntil = eatUntil
	if EatRules.isEating(eatUntil, Workspace:GetServerTimeNow()) then
		ExpressionState.trigger(entry.expression, EAT_EVENT, os.clock())
	else
		ExpressionState.clear(entry.expression, EAT_EVENT)
	end
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
	-- O Player pode ainda não estar ligado ao personagem quando o visual nasce:
	-- até achar, o nome é o do modelo; depois vira o DisplayName.
	if not entry.nameResolved then
		local player = Players:GetPlayerFromCharacter(character)
		if player then
			entry.boneco.nameLabel.Text = player.DisplayName
			entry.nameResolved = true
		end
	end
	local cosmeticId = stringAttribute(character, StatNames.CosmeticPrefix .. BODY_SLOT)
	if cosmeticId ~= entry.cosmeticId then
		applyCosmetic(entry, cosmeticId)
	end
	local bagCosmeticId = stringAttribute(character, StatNames.CosmeticPrefix .. BAG_SLOT)
	if bagCosmeticId ~= entry.bagCosmeticId then
		applyBag(entry, bagCosmeticId)
	end
	local equippedId = stringAttribute(character, StatNames.Equipped)
	local bookCosmeticId = stringAttribute(character, StatNames.CosmeticPrefix .. BOOK_SLOT)
	if equippedId ~= entry.equippedId or bookCosmeticId ~= entry.bookCosmeticId then
		applyEquipped(entry, equippedId, bookCosmeticId)
	end
	local hurtAt = numberAttribute(character, StatNames.HurtAt)
	if hurtAt ~= entry.hurtAt then
		checkHurt(entry, hurtAt)
	end
	local eatUntil = numberAttribute(character, StatNames.EatUntil)
	if eatUntil ~= entry.eatUntil then
		checkEat(entry, eatUntil)
	end
end

local function build(character: Model, hrp: BasePart)
	local player = Players:GetPlayerFromCharacter(character)
	local boneco = BonecoModel.build(if player then player.DisplayName else character.Name)
	boneco.root.CFrame = hrp.CFrame
	local entry: Entry = {
		character = character,
		hrp = hrp,
		boneco = boneco,
		anim = BonecoAnim.newState(),
		expression = ExpressionState.new(),
		hasTool = false,
		thrust = false,
		food = false,
		crumbColor = nil,
		eatUntil = nil,
		eatProgress = nil,
		lastPosition = hrp.Position,
		eyes = "open",
		flash = nil,
		cosmeticId = nil,
		bagCosmeticId = nil,
		bagModel = nil,
		bagFx = nil,
		skinJoints = nil,
		bookCosmeticId = nil,
		equippedId = nil,
		hurtAt = nil,
		hidden = false,
		-- Bonecos de teste não têm Player: o nome do modelo já é o certo.
		nameResolved = player ~= nil or isDevCrowd(character),
		connections = {},
	}
	entries[character] = entry

	-- Estado inicial (a skin padrão já veio do build; o resto vem do polling).
	applyCosmetic(entry, stringAttribute(character, StatNames.CosmeticPrefix .. BODY_SLOT))
	applyBag(entry, stringAttribute(character, StatNames.CosmeticPrefix .. BAG_SLOT))
	applyEquipped(
		entry,
		stringAttribute(character, StatNames.Equipped),
		stringAttribute(character, StatNames.CosmeticPrefix .. BOOK_SLOT)
	)
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
	local token = {}
	pending[character] = token
	task.spawn(function()
		local hrp = character:WaitForChild("HumanoidRootPart", ROOT_TIMEOUT)
		-- Saiu enquanto esperava (remove limpou o pending) ou outra chamada mais
		-- nova assumiu: esta não monta.
		if pending[character] ~= token then
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

-- Farelos quando a mordida passa do fundo de uma mordida neste quadro.
local function dropCrumbs(entry: Entry, progress: number?)
	local before = entry.eatProgress
	entry.eatProgress = progress
	if progress == nil or before == nil or progress < before then
		return
	end
	for _, bite in BITES do
		if before < bite and progress >= bite then
			BonecoModel.emitCrumbs(entry.boneco, entry.crumbColor, CRUMBS_PER_BITE)
		end
	end
end

local function animate(entry: Entry, dt: number, speed: number, now: number, serverNow: number)
	local boneco = entry.boneco
	local character = entry.character
	local eat = EatRules.progress(entry.eatUntil, serverNow, SurvivalConfig.EAT_DURATION)
	dropCrumbs(entry, eat)
	local pose = BonecoAnim.step(entry.anim, dt, {
		speed = speed,
		-- Craftando, o próprio braço não bate (só o dono sabe do craft). Com
		-- comida na mão o botão come: nada de soco.
		using = character:GetAttribute(StatNames.Using) == true
			and not entry.food
			and not (character == Players.LocalPlayer.Character and CraftState.isCrafting()),
		hasTool = entry.hasTool,
		thrust = entry.thrust,
		eat = eat,
	})
	boneco.bodyJoint.Transform = CFrame.new(0, pose.bodyY, 0)
	boneco.leftHandJoint.Transform = CFrame.new(pose.left.x, pose.left.y, pose.left.z)
	boneco.rightHandJoint.Transform = rightHandTransform(boneco.rightHandJoint.C0, pose.right)

	-- Skins com peças animadas (asas, tentáculos, raízes, cristais do livro) e
	-- partículas da mochila: seguem o mesmo passo e a mesma velocidade.
	local joints: { SkinAnimator.Joint } = entry.skinJoints or SkinAnimator.collect(boneco.model)
	entry.skinJoints = joints
	if #joints > 0 then
		SkinAnimator.step(joints, now, entry.anim.phase, entry.anim.speedFraction)
	end
	if entry.bagFx then
		BagFx.update(entry.bagFx, entry.anim.speedFraction)
	end

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

-- A raiz guardada ainda é do personagem? Se não (o Humanoid trocou a peça, ou o
-- streaming a tirou), procura de novo. false = o personagem está sem raiz agora.
local function refreshRoot(entry: Entry): boolean
	if entry.hrp.Parent == entry.character then
		return true
	end
	local found = entry.character:FindFirstChild("HumanoidRootPart")
	if found and found:IsA("BasePart") then
		entry.hrp = found
		-- Recomeça a medir a velocidade daqui (sem pulo de velocidade falsa).
		entry.lastPosition = found.Position
		return true
	end
	return false
end

local function update(dt: number)
	local camera = Workspace.CurrentCamera
	local cameraPosition = if camera then camera.CFrame.Position else nil
	local now = os.clock()
	local serverNow = Workspace:GetServerTimeNow()

	local roots: { BasePart } = {}
	local cframes: { CFrame } = {}
	local toAnimate: { Entry } = {}
	local speeds: { number } = {}

	for _, entry in entries do
		-- Todo boneco, inclusive os longe da câmera (skin e item certos ao chegar perto).
		syncAttributes(entry)

		-- Sem raiz, o visual some (melhor que ficar congelado no último lugar)
		-- e volta quando ela reaparecer.
		local hasRoot = refreshRoot(entry)
		if hasRoot == entry.hidden then
			entry.hidden = not hasRoot
			BonecoModel.setVisible(entry.boneco, hasRoot)
			if hasRoot then
				entry.lastPosition = entry.hrp.Position
			end
		end
		if not hasRoot then
			continue
		end

		local target = entry.hrp.CFrame
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
		animate(entry, dt, speeds[i], now, serverNow)
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

	-- Studio: mudou o Tamanho ou a Pegada de um modelo de Assets.Tools (ajuste ao
	-- vivo, na vista do Client ou do Server): refaz esse item na mão de quem o segura.
	if RunService:IsStudio() then
		task.spawn(function()
			local assets = ReplicatedStorage:WaitForChild("Assets", 10)
			local tools = assets and assets:WaitForChild("Tools", 10)
			if tools == nil then
				return
			end
			for _, template in tools:GetChildren() do
				local function refresh()
					for _, entry in entries do
						if entry.equippedId == template.Name then
							applyEquipped(entry, entry.equippedId, entry.bookCosmeticId)
						end
					end
				end
				template:GetAttributeChangedSignal(StatNames.ToolScale):Connect(refresh)
				template:GetAttributeChangedSignal(StatNames.ToolGrip):Connect(refresh)
			end
		end)
	end

	-- Prioridade Character: depois da câmera e do input, antes do desenho do
	-- quadro, para o boneco não ficar um quadro atrás do personagem.
	RunService:BindToRenderStep(RENDER_NAME, Enum.RenderPriority.Character.Value, update)
end

return BonecoRenderer
