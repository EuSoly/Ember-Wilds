--!strict
-- Peça de cabeça vestida no boneco: clone de ReplicatedStorage.Assets.Armor/<id>
-- (modelos do Blender, assets/armor/roblox/IMPORTAR-ROBLOX.md). O WorldPivot de
-- cada modelo já fica no centro do corpo e virado para a frente do boneco (−Z),
-- então basta pôr o pivô no Body e soldar. A peça mescla com a skin: nada é
-- escondido nem escalado (skin gorda cobre um pouco, magra mostra tudo).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BonecoModel = require(script.Parent:WaitForChild("BonecoModel"))

local ArmorModel = {}

local warned: { [string]: boolean } = {}

local function folder(): Instance?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	return assets and assets:FindFirstChild("Armor")
end

-- Clone do modelo da peça; nil (com um aviso por id) se não existir no place.
function ArmorModel.build(itemId: string): Model?
	local armor = folder()
	local source = armor and armor:FindFirstChild(itemId)
	if source == nil or not source:IsA("Model") then
		if not warned[itemId] then
			warned[itemId] = true
			warn(`[ArmorModel] sem modelo em ReplicatedStorage.Assets.Armor.{itemId}`)
		end
		return nil
	end
	local model = source:Clone()
	model.Name = "Armor"
	return model
end

-- Encaixa no corpo do boneco: pivô no Body e solda em cada peça.
function ArmorModel.attach(model: Model, boneco: BonecoModel.Boneco)
	local body = boneco.bodyJoint.Part1
	if body == nil then
		model:Destroy()
		return
	end
	model:PivotTo(body.CFrame)
	for _, part in model:GetDescendants() do
		if part:IsA("BasePart") then
			part.Anchored = false
			part.CanCollide = false
			part.CanQuery = false
			part.CanTouch = false
			part.Massless = true
			local weld = Instance.new("WeldConstraint")
			weld.Part0 = body
			weld.Part1 = part
			weld.Parent = part
		end
	end
	model.Parent = boneco.model
end

return ArmorModel
