--!strict
-- Retrato de um mob (livro de receitas, "Onde conseguir"): o modelo de
-- ReplicatedStorage.Assets.Mobs/<id> num ViewportFrame, visto de cima e de
-- frente (frente = -Z, como os ícones), enquadrado pela caixa do modelo.
-- Sem modelo, mostra as iniciais do nome.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local vide = require(ReplicatedStorage:WaitForChild("Packages"):WaitForChild("Vide"))
local Defs = require(Shared:WaitForChild("Defs"))
local Strings = require(Shared:WaitForChild("Strings"))
local Theme = require(Shared:WaitForChild("Theme"))
local UIMath = require(Shared:WaitForChild("UIMath"))

local create = vide.create

local FOV = 30
local MARGIN = 0.08
local VIEW = Vector3.new(0.35, 0.75, -1).Unit -- de onde a câmera olha (acima e à frente)

local function template(mobId: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local mobs = assets and assets:FindFirstChild("Mobs")
	local found = mobs and mobs:FindFirstChild(mobId)
	return if found and found:IsA("Model") then found else nil
end

-- Cantos da caixa do modelo na base da câmera, relativos ao centro
-- ({ direita, cima, frente }), para o UIMath.fitDistance.
local function fit(model: Model, cameraCFrame: CFrame, center: Vector3): number
	local box, size = model:GetBoundingBox()
	local points = {}
	for _, sx in { -1, 1 } do
		for _, sy in { -1, 1 } do
			for _, sz in { -1, 1 } do
				local corner = box * Vector3.new(size.X / 2 * sx, size.Y / 2 * sy, size.Z / 2 * sz)
				local offset = cameraCFrame:VectorToObjectSpace(corner - center)
				table.insert(points, { offset.X, offset.Y, -offset.Z })
			end
		end
	end
	return UIMath.fitDistance(points, FOV, 1, MARGIN)
end

local function MobPortrait(props: { mob: string }): GuiObject
	local source = template(props.mob)
	if source == nil then
		local mob = Defs.Mobs[props.mob]
		return create("TextLabel")({
			BackgroundTransparency = 1,
			FontFace = Theme.font.number,
			TextColor3 = Theme.rustic.charcoal,
			TextScaled = true,
			Text = UIMath.initials(if mob then Strings.get(mob.nameKey) else props.mob),
		}) :: TextLabel
	end
	local camera = create("Camera")({ FieldOfView = FOV }) :: Camera
	local model = source:Clone()
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = true
		end
	end
	local center = model:GetBoundingBox().Position
	-- Câmera olhando o centro; a distância vem do enquadramento na mesma direção.
	local look = CFrame.lookAt(center + VIEW, center)
	local distance = fit(model, look, center)
	camera.CFrame = CFrame.lookAt(center + VIEW * distance, center)
	local viewport = create("ViewportFrame")({
		BackgroundTransparency = 1,
		BackgroundColor3 = Color3.new(0, 0, 0), -- evita o contorno branco
		Ambient = Color3.fromRGB(190, 190, 190),
		LightColor = Color3.fromRGB(255, 255, 255),
		LightDirection = Vector3.new(-0.3, -1, -0.5),
		CurrentCamera = camera,
	}) :: ViewportFrame
	camera.Parent = viewport
	model.Parent = viewport
	vide.cleanup(function()
		model:Destroy()
	end)
	return viewport
end

return MobPortrait
