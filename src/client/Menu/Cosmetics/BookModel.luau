--!strict
-- O livro (única skin: book_default) é SEMPRE o modelo do Elizeu em
-- ReplicatedStorage.Assets.Tools.book: aqui só se clona a peça (o original
-- não é mexido, nunca é pintado nem trocado). Usado pelo boneco do menu e
-- pelo quadradinho 3D da skin.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BOOK_ASSET = "book" -- Assets.Tools.<id>
local TILT = math.rad(-62) -- capa virada para uma câmera de frente e de cima
local TWIST = math.rad(17.7) -- o modelo vem girado; isso o endireita

local BookModel = {}

-- Giro que deixa a capa de frente (a frente é -Z), para quem posiciona o livro.
BookModel.ROTATION = CFrame.Angles(TILT, 0, 0) * CFrame.Angles(0, TWIST, 0)

local warnedMissing = false

-- Peça do livro (sem a Tool e sem o Attachment do grip), ancorada e sem
-- colisão; nil enquanto o asset não existe (avisa uma vez).
function BookModel.clone(): BasePart?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local tools = assets and assets:FindFirstChild("Tools")
	local tool = tools and tools:FindFirstChild(BOOK_ASSET)
	local handle = tool and tool:FindFirstChild("Handle")
	if handle == nil or not handle:IsA("BasePart") then
		if not warnedMissing then
			warnedMissing = true
			warn(`[BookModel] sem ReplicatedStorage.Assets.Tools.{BOOK_ASSET}.Handle: sem livro`)
		end
		return nil
	end
	local book = handle:Clone()
	book:ClearAllChildren()
	book.Anchored = true
	book.CanCollide = false
	book.CanQuery = false
	book.CanTouch = false
	return book
end

return BookModel
