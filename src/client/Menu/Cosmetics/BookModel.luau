--!strict
-- Modelo do livro para o boneco do menu e para o quadradinho 3D da skin:
--   book_default → ReplicatedStorage.Assets.Tools.book.Handle (modelo do Elizeu)
--   book_<nome>  → malha 3D exportada em ReplicatedStorage.Assets.Books (SkinAssets)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local SkinAssets = require(Shared:WaitForChild("Models"):WaitForChild("SkinAssets"))
local SkinManifest = require(Shared:WaitForChild("Defs"):WaitForChild("SkinManifest"))

local BOOK_ASSET = "book" -- Assets.Tools.<id>
local TILT = math.rad(-62) -- capa virada para uma câmera de frente e de cima
local TWIST = math.rad(17.7) -- o modelo padrão vem girado; isso o endireita

local BookModel = {}

-- Giro que deixa a capa de frente (a frente é -Z), para quem posiciona o livro.
BookModel.ROTATION = CFrame.Angles(TILT, 0, 0) * CFrame.Angles(0, TWIST, 0)
local SKIN_ROTATION = CFrame.Angles(TILT, 0, 0)

local warnedMissing = false

-- Peça do livro (ancorada e sem colisão), já posicionada em `baseCFrame` (se
-- passado) com a inclinação da capa para a câmera. Para skins com partes neon,
-- as partes extras vão como filhas soldadas na peça principal.
function BookModel.clone(cosmeticId: string?, baseCFrame: CFrame?): BasePart?
	local resolved = if cosmeticId == nil or cosmeticId == "book_default" then "book_pergaminho" else cosmeticId
	if resolved ~= nil and SkinAssets.hasSkin(resolved) then
		local partNames = SkinManifest.PARTS_BY_SKIN[resolved]
		if partNames ~= nil then
			local pivot = (baseCFrame or CFrame.identity) * SKIN_ROTATION
			local main: BasePart? = nil
			for _, partName in partNames do
				local clone = SkinAssets.clonePart(resolved, partName, pivot)
				if clone then
					clone.Anchored = true
					if main == nil then
						main = clone
					else
						clone.Parent = main
						local weld = Instance.new("WeldConstraint")
						weld.Part0 = main
						weld.Part1 = clone
						weld.Parent = clone
					end
				end
			end
			if main ~= nil then
				return main
			end
		end
	end

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
	book.CFrame = (baseCFrame or CFrame.identity) * BookModel.ROTATION
	return book
end

return BookModel
