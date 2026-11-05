--!strict
-- Item 3D de qualquer skin num ViewportFrame de câmera fixa, para os
-- quadradinhos dos Cosméticos e da loja:
--   corpo   → o boneco com as cores da skin, de frente
--   mochila → BagModel nas cores da skin
--   caixa   → CrateModel.build(id)
--   livro   → clone de Assets.Tools.book (o modelo do Elizeu, sem pintar)
-- O fundo é transparente: a moldura (de quem chama) pinta a cor da raridade.
--
-- O carrossel da loja põe até ~50 quadradinhos na tela de uma vez: o modelo
-- de cada id é montado UMA vez num cache (fora da cena) e cada quadradinho
-- recebe um Clone() dele, que morre junto com o ViewportFrame.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Defs = require(Shared:WaitForChild("Defs"))
local SkinAssets = require(Shared:WaitForChild("Models"):WaitForChild("SkinAssets"))
local SkinManifest = require(Shared:WaitForChild("Defs"):WaitForChild("SkinManifest"))
local UIMath = require(Shared:WaitForChild("UIMath"))
local CrateModel = require(Shared:WaitForChild("Models"):WaitForChild("CrateModel"))
local Client = script.Parent.Parent.Parent
local BonecoModel = require(Client:WaitForChild("Boneco"):WaitForChild("BonecoModel"))
local BagModel = require(script.Parent:WaitForChild("BagModel"))
local BookModel = require(script.Parent:WaitForChild("BookModel"))

local FOV = 30
local MARGIN = 0.08 -- folga em volta do item (0.08 = 8%)
-- De onde a câmera olha (do centro do item para a câmera), por slot.
local DIRECTIONS: { [string]: Vector3 } = {
	body = Vector3.new(0, 0.8, -1.1).Unit, -- de frente e de cima (vê os olhos)
	bag = Vector3.new(0.45, 0.6, 1).Unit, -- pelo lado de fora (aba e alças)
	crate = Vector3.new(0.6, 0.7, -1).Unit, -- quina da frente, um pouco de cima
	book = Vector3.new(0, 0.8, -1.1).Unit, -- igual ao livro na mão do boneco
}
local DEFAULT_DIRECTION = Vector3.new(0, 0.7, -1).Unit

local ItemViewport = {}

local cache: { [string]: Model } = {}

local function bodyModel(look: Defs.BodyLook, cosmeticId: string): Model
	local boneco = BonecoModel.build("")
	BonecoModel.applyLook(boneco, look, cosmeticId)
	local tag = boneco.root:FindFirstChild("NameTag")
	if tag then
		tag:Destroy()
	end
	boneco.model.Name = "Boneco"
	boneco.model.Parent = nil -- o build põe no Workspace
	return boneco.model
end

local function bookModel(cosmeticId: string): Model?
	local book = BookModel.clone(cosmeticId)
	if book == nil then
		return nil
	end
	local model = Instance.new("Model")
	book.Parent = model
	model.PrimaryPart = book
	return model
end

-- Monta o modelo de `cosmeticId` (sem cache). nil = id desconhecido ou o
-- asset do livro ainda não chegou.
local function buildModel(cosmeticId: string): Model?
	local cosmetic = Defs.Cosmetics[cosmeticId]
	if cosmetic == nil then
		return nil
	end
	if cosmetic.body then
		return bodyModel(cosmetic.body, cosmeticId)
	elseif cosmetic.bag then
		return BagModel.build(cosmetic.bag, cosmeticId)
	elseif cosmetic.crate then
		return CrateModel.build(cosmeticId)
	elseif cosmetic.slot == "book" then
		return bookModel(cosmeticId)
	end
	return nil
end

-- Cópia nova do modelo de `cosmeticId` (o molde fica no cache), ou nil.
function ItemViewport.clone(cosmeticId: string): Model?
	local cached: Model? = cache[cosmeticId]
	if cached then
		return cached:Clone()
	end
	local built = buildModel(cosmeticId)
	if not built then
		return nil -- não guarda: o livro pode chegar depois
	end
	if SkinManifest.PARTS_BY_SKIN[cosmeticId] == nil or SkinAssets.hasSkin(cosmeticId) then
		cache[cosmeticId] = built
	end
	return built:Clone()
end

-- Câmera olhando o centro de `model` a partir de `direction`, perto o bastante
-- para o item encher o quadro (quadrado) sem cortar.
function ItemViewport.frame(camera: Camera, model: Model, direction: Vector3)
	local box, size = model:GetBoundingBox()
	local center = box.Position
	local look = CFrame.lookAt(center + direction, center)
	local points: { { number } } = {}
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				-- Canto da caixa em relação ao centro, no espaço do mundo.
				local offset = box:VectorToWorldSpace(Vector3.new(sx * size.X, sy * size.Y, sz * size.Z) / 2)
				-- Base da câmera: frente = LookVector (para longe da câmera).
				table.insert(points, {
					offset:Dot(look.RightVector),
					offset:Dot(look.UpVector),
					offset:Dot(look.LookVector),
				})
			end
		end
	end
	local distance = UIMath.fitDistance(points, FOV, 1, MARGIN)
	camera.FieldOfView = FOV
	camera.CFrame = CFrame.lookAt(center + direction * distance, center)
end

-- Direção da câmera para as skins do slot de `cosmeticId`.
function ItemViewport.direction(cosmeticId: string): Vector3
	local cosmetic = Defs.Cosmetics[cosmeticId]
	return cosmetic and DIRECTIONS[cosmetic.slot] or DEFAULT_DIRECTION
end

-- ViewportFrame transparente que ocupa o pai inteiro, com o item de
-- `cosmeticId` enquadrado de frente. Id desconhecido = quadro vazio.
function ItemViewport.build(cosmeticId: string): ViewportFrame
	local camera = Instance.new("Camera")
	camera.Name = "ItemCamera"
	local viewport = Instance.new("ViewportFrame")
	viewport.Name = "Item3D"
	viewport.Size = UDim2.fromScale(1, 1)
	viewport.BackgroundTransparency = 1
	viewport.BorderSizePixel = 0
	viewport.Ambient = Color3.fromRGB(200, 200, 200)
	viewport.LightColor = Color3.new(1, 1, 1)
	viewport.LightDirection = Vector3.new(-1, -2, -1)
	viewport.CurrentCamera = camera
	camera.Parent = viewport

	local model = ItemViewport.clone(cosmeticId)
	if model then
		model.Parent = viewport
		ItemViewport.frame(camera, model, ItemViewport.direction(cosmeticId))
	end
	return viewport
end

return ItemViewport
