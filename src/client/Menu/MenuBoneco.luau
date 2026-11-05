--!strict
-- Boneco do jogador no centro do menu, segurando o livro e com a mochila nas
-- costas. Fica num ViewportFrame: não depende de onde a câmera do menu está
-- passeando.
--
-- As skins são as equipadas de verdade: o CosmeticService grava
-- Cosmetic_<slot> também no Player (no menu não há personagem). A tela de
-- Cosméticos pode passar um `override` para mostrar outra skin (prévia). O
-- livro é sempre o modelo do Elizeu (BookModel: clone de Assets.Tools.book).
--
-- Num ViewportFrame não roda física: soldas e Motor6D não movem nada. Por
-- isso a pose (livro, mãos e mochila) é posta direto no CFrame das peças.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Client = script.Parent.Parent
local BonecoModel = require(Client:WaitForChild("Boneco"):WaitForChild("BonecoModel"))
local Sources = require(Client:WaitForChild("UI"):WaitForChild("Sources"))
local Cosmetics = script.Parent:WaitForChild("Cosmetics")
local BagModel = require(Cosmetics:WaitForChild("BagModel"))
local BookModel = require(Cosmetics:WaitForChild("BookModel"))

local create = vide.create

-- Pose ajustada no olho (em relação à raiz do boneco; a frente é -Z).
local BOOK_OFFSET = CFrame.new(0, 0.25, -2.75)
local HAND_X = 1.3 -- mãos nas bordas do livro
local HAND_Y = 0.2
local HAND_Z = -2.85
-- Câmera de frente e um pouco de cima.
local CAMERA_DIRECTION = Vector3.new(0, 0.8, -1.1).Unit
local CAMERA_FOV = 30
local CAMERA_MARGIN = 0.85 -- < 1 aproxima (a caixa do modelo é maior que o desenho)

-- Skins mostradas no lugar das equipadas (campo nil = a equipada).
export type Override = { body: string?, bag: string?, book: string? }

local MenuBoneco = {}

-- Leva a mão (e o contorno ou malha 3D soldada a ela) para `target`.
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
	for _, child in hand:GetDescendants() do
		if child:IsA("BasePart") then
			child.CFrame = delta * child.CFrame
		end
	end
end

local function spawnBook(boneco: BonecoModel.Boneco, bookId: string?): BasePart?
	local root = boneco.root.CFrame
	local book = BookModel.clone(bookId, root * BOOK_OFFSET)
	if book then
		book.Name = "MenuBook"
		book.Parent = boneco.model
	end
	return book
end

local function pose(boneco: BonecoModel.Boneco, bookId: string?): BasePart?
	local root = boneco.root.CFrame
	local book = spawnBook(boneco, bookId)
	moveHand(boneco.model, "LeftHand", root * CFrame.new(-HAND_X, HAND_Y, HAND_Z))
	moveHand(boneco.model, "RightHand", root * CFrame.new(HAND_X, HAND_Y, HAND_Z))
	return book
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

-- Cores da mochila `id`; id inválido (ou de outro slot) cai na mochila padrão.
local function bagLookOf(id: string): Defs.BagLook
	local cosmetic = Defs.Cosmetics[id]
	if cosmetic and cosmetic.bag then
		return cosmetic.bag
	end
	local default = Defs.Cosmetics[Defs.CosmeticSlots.bag.default].bag
	assert(default ~= nil, "[MenuBoneco] mochila padrão sem cores")
	return default
end

-- ViewportFrame transparente com o boneco. Chamar dentro de um root Vide.
-- O boneco existe só enquanto `visible()` é verdadeiro (criado e destruído).
-- Sem `override`, mostra as skins equipadas (Cosmetic_body e Cosmetic_bag do
-- Player); com ele, cada campo preenchido troca a skin daquele slot.
function MenuBoneco.build(visible: () -> boolean, override: (() -> Override)?): ViewportFrame
	local player = Players.LocalPlayer
	local equippedBody = Sources.attribute(player, StatNames.CosmeticPrefix .. "body", Defs.CosmeticSlots.body.default)
	local equippedBag = Sources.attribute(player, StatNames.CosmeticPrefix .. "bag", Defs.CosmeticSlots.bag.default)
	local equippedBook = Sources.attribute(player, StatNames.CosmeticPrefix .. "book", Defs.CosmeticSlots.book.default)
	local function chosen(): (string, string, string)
		local wanted: Override = if override then override() else {}
		return wanted.body or equippedBody(), wanted.bag or equippedBag(), wanted.book or equippedBook()
	end

	local camera = Instance.new("Camera")
	local viewport = create("ViewportFrame")({
		Name = "MenuBoneco",
		BackgroundColor3 = Color3.fromHex("#221912"), -- igual ao fundo da vitrine (elimina contorno branco de anti-aliasing)
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Ambient = Color3.fromRGB(200, 200, 200),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -2, -1),
		CurrentCamera = camera,
		camera,
	}) :: ViewportFrame

	local current: BonecoModel.Boneco? = nil
	local bag: Model? = nil
	local bagId: string? = nil
	local bookPart: BasePart? = nil
	local bookId: string? = nil
	vide.effect(function()
		local show = visible()
		local bodyId, wantedBag, wantedBook = chosen()
		local look = lookOf(bodyId)
		if show and current == nil then
			local boneco = BonecoModel.build("")
			boneco.model.Parent = viewport -- o build põe no Workspace; move já
			bookPart = pose(boneco, wantedBook)
			bookId = wantedBook
			-- Enquadra antes da mochila e dos adereços 3D: o enquadramento não muda com eles.
			frameCamera(camera, boneco.model)
			current = boneco
		elseif not show and current ~= nil then
			BonecoModel.destroy(current) -- leva a mochila e o livro junto
			current = nil
			bag = nil
			bagId = nil
			bookPart = nil
			bookId = nil
		end
		if current ~= nil then
			BonecoModel.applyLook(current, look, bodyId)
			if bagId ~= wantedBag then
				if bag then
					bag:Destroy()
				end
				local model = BagModel.build(bagLookOf(wantedBag), wantedBag)
				BagModel.attach(model, current)
				bag = model
				bagId = wantedBag
			end
			if bookId ~= wantedBook then
				if bookPart then
					bookPart:Destroy()
				end
				bookPart = spawnBook(current, wantedBook)
				bookId = wantedBook
			end
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
