--!strict
-- Cadeado nas caixas de morte com o revive pendente (atributo CrateLocked no
-- modelo, ligado pelo CrateService). O atributo é de um modelo comum (não do
-- personagem), então o sinal de mudança vale. Sem a arte (LOCK_BOX), o cadeado
-- é desenhado por código: corpo de brasa e argola.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local MonetizationImages = require(Shared:WaitForChild("MonetizationImages"))
local StatNames = require(Shared:WaitForChild("StatNames"))
local Theme = require(Shared:WaitForChild("Theme"))

local R = Theme.rustic
local SIZE = UDim2.fromOffset(40, 46)
local OFFSET = Vector3.new(0, 3, 0)

local CrateLock = {}

local locks: { [Model]: BillboardGui } = {}

local function buildGui(): BillboardGui
	local gui = Instance.new("BillboardGui")
	gui.Name = "CrateLock"
	gui.Size = SIZE
	gui.StudsOffset = OFFSET
	gui.AlwaysOnTop = true
	gui.LightInfluence = 0
	gui.MaxDistance = 80
	if MonetizationImages.has(MonetizationImages.LOCK_BOX) then
		local image = Instance.new("ImageLabel")
		image.Name = "Art"
		image.Size = UDim2.fromScale(1, 1)
		image.BackgroundTransparency = 1
		image.Image = MonetizationImages.LOCK_BOX
		image.ScaleType = Enum.ScaleType.Fit
		image.Parent = gui
		return gui
	end
	-- Argola: moldura com só o contorno, atrás do corpo.
	local shackle = Instance.new("Frame")
	shackle.Name = "Shackle"
	shackle.AnchorPoint = Vector2.new(0.5, 0)
	shackle.Position = UDim2.fromScale(0.5, 0)
	shackle.Size = UDim2.fromScale(0.6, 0.62)
	shackle.BackgroundTransparency = 1
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.5, 0)
	corner.Parent = shackle
	local stroke = Instance.new("UIStroke")
	stroke.Color = R.cream
	stroke.Thickness = 5
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = shackle
	shackle.Parent = gui
	local body = Instance.new("Frame")
	body.Name = "Body"
	body.AnchorPoint = Vector2.new(0.5, 1)
	body.Position = UDim2.fromScale(0.5, 1)
	body.Size = UDim2.fromScale(1, 0.55)
	body.BackgroundColor3 = R.ember
	body.BorderSizePixel = 0
	local bodyCorner = Instance.new("UICorner")
	bodyCorner.CornerRadius = UDim.new(0, 6)
	bodyCorner.Parent = body
	local bodyStroke = Instance.new("UIStroke")
	bodyStroke.Color = R.outline
	bodyStroke.Thickness = 2
	bodyStroke.Parent = body
	body.Parent = gui
	return gui
end

-- Parte onde o cadeado se prende (a do pivô, ou a primeira que houver).
local function anchorPart(model: Model): BasePart?
	return model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart", true)
end

local function refresh(model: Model)
	local locked = model:GetAttribute(StatNames.CrateLocked) == true and model:IsDescendantOf(workspace)
	local existing: BillboardGui? = locks[model]
	if not locked then
		if existing then
			existing:Destroy()
			locks[model] = nil
		end
		return
	end
	local part = anchorPart(model)
	if existing == nil and part then
		local gui = buildGui()
		gui.Adornee = part
		gui.Parent = part
		locks[model] = gui
	end
end

local function watch(instance: Instance)
	if not instance:IsA("Model") then
		return
	end
	instance:GetAttributeChangedSignal(StatNames.CrateLocked):Connect(function()
		refresh(instance)
	end)
	instance.AncestryChanged:Connect(function()
		refresh(instance)
	end)
	refresh(instance)
end

-- Liga o cadeado (chamado uma vez pelo WorldFxController). As caixas chegam
-- aos poucos (streaming): liga cada uma quando aparece.
function CrateLock.start()
	CollectionService:GetInstanceAddedSignal(StatNames.CrateTag):Connect(watch)
	for _, instance in CollectionService:GetTagged(StatNames.CrateTag) do
		watch(instance)
	end
end

return CrateLock
