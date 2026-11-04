--!strict
-- Boneco do jogador no centro do menu, segurando o livro (futuramente as
-- skins de livro trocam qual modelo é clonado aqui). Fica num ViewportFrame:
-- não depende de onde a câmera do menu está passeando.
--
-- A skin é a equipada de verdade: o CosmeticService grava Cosmetic_body também
-- no Player (no menu não há personagem). O livro é um clone do modelo do
-- Elizeu em ReplicatedStorage.Assets.Tools.book (o original não é mexido).
--
-- Num ViewportFrame não roda física: soldas e Motor6D não movem nada. Por
-- isso a pose (livro e mãos) é posta direto no CFrame das peças.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Client = script.Parent.Parent
local BonecoModel = require(Client:WaitForChild("Boneco"):WaitForChild("BonecoModel"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))

local create = vide.create

local BOOK_ASSET = "book" -- Assets.Tools.<id>
-- Pose ajustada no olho (em relação à raiz do boneco; a frente é -Z).
local BOOK_OFFSET = CFrame.new(0, 0.25, -2.75)
local BOOK_TILT = math.rad(-62) -- capa virada para a câmera
local BOOK_TWIST = math.rad(17.7) -- o modelo vem girado; isso o endireita
local HAND_X = 1.3 -- mãos nas bordas do livro
local HAND_Y = 0.2
local HAND_Z = -2.85
-- Câmera de frente e um pouco de cima.
local CAMERA_DIRECTION = Vector3.new(0, 0.8, -1.1).Unit
local CAMERA_FOV = 30
local CAMERA_MARGIN = 0.85 -- < 1 aproxima (a caixa do modelo é maior que o desenho)

local MenuBoneco = {}

local warnedMissingBook = false

-- Peça do livro (sem a Tool e sem o Attachment do grip), ou nil sem o asset.
local function cloneBook(): BasePart?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local tools = assets and assets:FindFirstChild("Tools")
	local tool = tools and tools:FindFirstChild(BOOK_ASSET)
	local handle = tool and tool:FindFirstChild("Handle")
	if handle == nil or not handle:IsA("BasePart") then
		if not warnedMissingBook then
			warnedMissingBook = true
			warn(`[MenuBoneco] sem ReplicatedStorage.Assets.Tools.{BOOK_ASSET}.Handle: boneco sem livro`)
		end
		return nil
	end
	local book = handle:Clone()
	book:ClearAllChildren()
	book.Anchored = true
	book.CanCollide = false
	book.CanQuery = false
	return book
end

-- Leva a mão (e o contorno soldado a ela) para `target`.
local function moveHand(model: Model, name: string, target: CFrame)
	local hand = model:FindFirstChild(name)
	local outline = model:FindFirstChild(name .. "Outline")
	if hand == nil or not hand:IsA("BasePart") then
		return
	end
	local delta = target * hand.CFrame:Inverse()
	hand.CFrame = target
	if outline and outline:IsA("BasePart") then
		outline.CFrame = delta * outline.CFrame
	end
end

local function pose(boneco: BonecoModel.Boneco)
	local root = boneco.root.CFrame
	local book = cloneBook()
	if book then
		book.CFrame = root * BOOK_OFFSET * CFrame.Angles(BOOK_TILT, 0, 0) * CFrame.Angles(0, BOOK_TWIST, 0)
		book.Parent = boneco.model
	end
	moveHand(boneco.model, "LeftHand", root * CFrame.new(-HAND_X, HAND_Y, HAND_Z))
	moveHand(boneco.model, "RightHand", root * CFrame.new(HAND_X, HAND_Y, HAND_Z))
end

local function frameCamera(camera: Camera, model: Model)
	local cframe, size = model:GetBoundingBox()
	local distance = CAMERA_MARGIN * (size.Magnitude / 2) / math.sin(math.rad(CAMERA_FOV) / 2)
	camera.FieldOfView = CAMERA_FOV
	camera.CFrame = CFrame.lookAt(cframe.Position + CAMERA_DIRECTION * distance, cframe.Position)
end

-- Cores da skin `id`; id inválido (ou de outro slot) cai na skin padrão.
local function lookOf(id: string): Defs.BodyLook
	local cosmetic = Defs.Cosmetics[id]
	if cosmetic and cosmetic.body then
		return cosmetic.body
	end
	local default = Defs.Cosmetics[Defs.CosmeticSlots.body.default].body
	assert(default ~= nil, "[MenuBoneco] skin padrão sem cores")
	return default
end

-- ViewportFrame transparente com o boneco. Chamar dentro de um root Vide.
-- O boneco existe só enquanto `visible()` é verdadeiro (criado e destruído).
function MenuBoneco.build(visible: () -> boolean): ViewportFrame
	local skin =
		Sources.attribute(Players.LocalPlayer, StatNames.CosmeticPrefix .. "body", Defs.CosmeticSlots.body.default)

	local camera = Instance.new("Camera")
	local viewport = create("ViewportFrame")({
		Name = "MenuBoneco",
		BackgroundTransparency = 1,
		Ambient = Color3.fromRGB(200, 200, 200),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -2, -1),
		CurrentCamera = camera,
		camera,
	}) :: ViewportFrame

	local current: BonecoModel.Boneco? = nil
	vide.effect(function()
		local show = visible()
		local look = lookOf(skin())
		if show and current == nil then
			local boneco = BonecoModel.build("")
			boneco.model.Parent = viewport -- o build põe no Workspace; move já
			pose(boneco)
			frameCamera(camera, boneco.model)
			current = boneco
		elseif not show and current ~= nil then
			BonecoModel.destroy(current)
			current = nil
		end
		if current ~= nil then
			BonecoModel.applyLook(current, look)
		end
	end)
	vide.cleanup(function()
		if current ~= nil then
			BonecoModel.destroy(current)
			current = nil
		end
	end)

	return viewport
end

return MenuBoneco
