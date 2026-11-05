--!strict
-- Prévia 3D da caixa de itens com a skin `skinId()` (CrateModel.build), na
-- mesma câmera dos quadradinhos. Troca a caixa quando a skin muda. Fundo
-- transparente; quem chama dá tamanho e posição. Chamar dentro de um root Vide.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local CrateModel = require(Shared:WaitForChild("Models"):WaitForChild("CrateModel"))
local ItemViewport = require(script.Parent:WaitForChild("ItemViewport"))

local create = vide.create

local CratePreview = {}

function CratePreview.build(skinId: () -> string): ViewportFrame
	local camera = Instance.new("Camera")
	camera.Name = "CrateCamera"
	local viewport = create("ViewportFrame")({
		Name = "CratePreview",
		BackgroundColor3 = Color3.fromHex("#221912"), -- igual ao fundo da vitrine (elimina contorno branco de anti-aliasing)
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Ambient = Color3.fromRGB(200, 200, 200),
		LightColor = Color3.new(1, 1, 1),
		LightDirection = Vector3.new(-1, -2, -1),
		CurrentCamera = camera,
		camera,
	}) :: ViewportFrame

	vide.effect(function()
		local id = skinId()
		local model = CrateModel.build(id)
		model.Parent = viewport
		ItemViewport.frame(camera, model, ItemViewport.direction(id))
		vide.cleanup(function()
			model:Destroy()
		end)
	end)

	return viewport
end

return CratePreview
