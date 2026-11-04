--!strict
-- Modelo da caixa de itens (G6). `modelId` = skin de caixa do jogador (ex.:
-- "crate_default") ou id do mob (ex.: "wolf").
-- 1. Se existe ReplicatedStorage.Assets.Crates.<modelId> (Model), clona. O
--    pivô do modelo do Studio tem de estar no chão, no centro da caixa.
-- 2. Senão, uma caixa provisória de peças: corpo de madeira com faixas numa
--    cor tirada do id do mob (cada mob a sua, sem lista de ids) ou dourada
--    (caixa de jogador).
-- Tudo ancorado e sem colisão, toque nem raycast: a caixa nasce onde alguém
-- morreu (pode haver gente em cima) e o golpe a acha pelo índice do servidor.
-- Tag, vida e posição quem grava é o CrateService. (Só roda no Roblox: cria
-- instâncias.)
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require("../Defs")
local Palette = require("../Palette")
local Theme = require("../Theme")

local CrateModel = {}

local BODY = Vector3.new(2.4, 1.6, 2.4)
local LID_HEIGHT = 0.4
local BAND_WIDTH = 0.3
-- Cores possíveis das faixas da caixa de mob (escolhida pelo id).
local MOB_BANDS = {
	Palette.tier.stone,
	Palette.tier.diamond,
	Palette.tier.amethyst,
	Palette.tier.reidite,
	Palette.tier.emerald,
	Palette.status.cold,
}

local function newPart(name: string, size: Vector3, cframe: CFrame, color: Color3, parent: Model): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.WoodPlanks
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Parent = parent
	return part
end

-- Faixas: cor fixa por id de mob (soma dos bytes do id), dourada para jogador.
local function bandColor(modelId: string): Color3
	if Defs.Mobs[modelId] == nil then
		return Theme.tier.gold
	end
	local sum = 0
	for i = 1, #modelId do
		sum += string.byte(modelId, i)
	end
	return Theme.color(MOB_BANDS[sum % #MOB_BANDS + 1])
end

local function buildPlaceholder(modelId: string): Model
	local model = Instance.new("Model")
	-- Caixa de jogador com `crate` no cosmético usa as cores dele.
	local look = Defs.Cosmetics[modelId] and Defs.Cosmetics[modelId].crate
	local wood = if look then Color3.fromHex(look.bodyColor) else Theme.tier.wood
	local band = if look then Color3.fromHex(look.bandColor) else bandColor(modelId)
	local body = newPart("Body", BODY, CFrame.new(0, BODY.Y / 2, 0), wood, model)
	newPart(
		"Lid",
		Vector3.new(BODY.X + 0.2, LID_HEIGHT, BODY.Z + 0.2),
		CFrame.new(0, BODY.Y + LID_HEIGHT / 2, 0),
		wood:Lerp(Color3.new(0, 0, 0), 0.3),
		model
	)
	-- Duas faixas cruzadas por cima e pelos lados.
	local height = BODY.Y + LID_HEIGHT + 0.05
	for i, size in { Vector3.new(BAND_WIDTH, height, BODY.Z + 0.3), Vector3.new(BODY.X + 0.3, height, BAND_WIDTH) } do
		local part = newPart("Band" .. i, size, CFrame.new(0, height / 2, 0), band, model)
		part.Material = Enum.Material.SmoothPlastic
	end
	model.PrimaryPart = body
	-- Pivô no chão, no centro (com PrimaryPart, o pivô do modelo é o dela).
	body.PivotOffset = CFrame.new(0, -BODY.Y / 2, 0)
	return model
end

local function fromTemplate(template: Model): Model
	local model = template:Clone()
	for _, descendant in model:GetDescendants() do
		if descendant:IsA("BaseScript") or descendant:IsA("ModuleScript") then
			descendant:Destroy()
		elseif descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		end
	end
	return model
end

function CrateModel.build(modelId: string): Model
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Crates")
	local template = folder and folder:FindFirstChild(modelId)
	local model = if template and template:IsA("Model") then fromTemplate(template) else buildPlaceholder(modelId)
	model.Name = "Crate"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	return model
end

return CrateModel
