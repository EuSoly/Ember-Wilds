--!strict
-- Modelos importados das ferramentas e armas em ReplicatedStorage.Assets.Tools.
-- Cada modelo tem PrimaryPart = Handle e Attachment "Grip" (Y = cabo/lâmina
-- para a frente, X = lado). As espadas e lanças vêm do Blender do Elizeu
-- (scripts/studio/import-weapons.luau). Atributos de cada modelo, ajustáveis
-- no Studio: "Tamanho" (StatNames.ToolScale; 1 = como foi importado) escala o
-- item na mão; "Pegada" (StatNames.ToolGrip; studs, 0 = Grip importado) desliza
-- onde a mão segura ao longo da arma (positivo = mais perto da ponta).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Defs = require("../Defs")
local SkinAssets = require("./SkinAssets")
local SkinManifest = require("../Defs/SkinManifest")
local StatNames = require("../StatNames")
local Types = require("../Defs/Types")

local ToolModel = {}

local function template(itemId: string): Instance?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Tools")
	local found = folder and folder:FindFirstChild(itemId)
	if found == nil or not (found:IsA("Model") or found:IsA("Tool")) then
		return nil
	end
	return found
end

-- Tamanho escolhido no modelo (1 se faltar ou for inválido).
function ToolModel.scaleOf(itemId: string): number
	local model = template(itemId)
	local value = model and model:GetAttribute(StatNames.ToolScale)
	if type(value) == "number" and value > 0 and value < math.huge then
		return value
	end
	return 1
end

-- Pegada escolhida no modelo (0 se faltar ou for inválida).
function ToolModel.gripOffsetOf(itemId: string): number
	local model = template(itemId)
	local value = model and model:GetAttribute(StatNames.ToolGrip)
	if type(value) == "number" and value == value and math.abs(value) < math.huge then
		return value
	end
	return 0
end

-- Golpe do item: o da definição; um modelo que ainda não é item (só aparece
-- na galeria do Studio) estoca se for lança, como na bancada.
function ToolModel.attackAnimOf(itemId: string): Types.AttackAnim
	local def = Defs.Items[itemId]
	if def then
		return def.attackAnim or "swing"
	end
	return if itemId:match("_spear$") then "thrust" else "swing"
end

function ToolModel.build(itemId: string, cosmeticId: string?): Model?
	local def = Defs.Items[itemId]
	if def ~= nil and def.category ~= "tool" and def.category ~= "weapon" and itemId ~= "book" then
		return nil
	end
	-- Sem definição: só no Studio, para conferir modelos que ainda não são itens
	-- (galeria DevWeapons).
	if def == nil and not RunService:IsStudio() then
		return nil
	end

	-- Livro: usa a skin 3D equipada (ou book_pergaminho como padrão) em ReplicatedStorage.Assets.Books
	if itemId == "book" then
		local skinId = if (cosmeticId ~= nil and SkinAssets.hasSkin(cosmeticId))
			then cosmeticId
			elseif SkinAssets.hasSkin("book_pergaminho") then "book_pergaminho"
			else nil

		if skinId ~= nil and SkinAssets.hasSkin(skinId) then
			local partNames = SkinManifest.PARTS_BY_SKIN[skinId]
			if partNames ~= nil then
				local model = Instance.new("Model")
				model.Name = "HeldItem"
				model:SetAttribute("ItemId", itemId)

				local handle = Instance.new("Part")
				handle.Name = "Handle"
				handle.Size = Vector3.new(2.37, 0.53, 2.68)
				handle.Transparency = 1
				handle.Anchored = false
				handle.CanCollide = false
				handle.CanQuery = false
				handle.CanTouch = false
				handle.Massless = true
				handle.Parent = model
				model.PrimaryPart = handle

				local source = template("book")
				local sourceHandle = source
					and (
						if source:IsA("Model") then source.PrimaryPart else source:FindFirstChild("Handle") :: BasePart?
					)
				local sourceGrip = sourceHandle and sourceHandle:FindFirstChild("Grip")

				local grip = Instance.new("Attachment")
				grip.Name = "Grip"
				if sourceGrip and sourceGrip:IsA("Attachment") then
					grip.CFrame = sourceGrip.CFrame
				else
					grip.CFrame = CFrame.new(-0.8, 0, 0)
				end
				grip.Parent = handle

				for _, partName in partNames do
					local clone = SkinAssets.clonePart(skinId, partName, handle.CFrame)
					if clone then
						clone.Parent = model
						if SkinAssets.isAnimated(partName) then
							-- Cristal, folha, ponta do tentáculo...: junta no pivô
							-- (o SkinAnimator mexe enquanto o livro está na mão).
							SkinAssets.attachPart(handle, clone, handle.CFrame)
						else
							local weld = Instance.new("Weld")
							weld.Name = "SkinWeld"
							weld.Part0 = handle
							weld.Part1 = clone
							weld.C0 = CFrame.identity
							weld.C1 = handle.CFrame:ToObjectSpace(clone.CFrame)
							weld.Parent = clone
						end
					end
				end

				local scale = ToolModel.scaleOf(itemId)
				if scale ~= 1 then
					model:ScaleTo(model:GetScale() * scale)
				end
				local offset = ToolModel.gripOffsetOf(itemId)
				if offset ~= 0 then
					grip.CFrame *= CFrame.new(0, offset * scale, 0)
				end
				return model
			end
		end
	end

	local source = template(itemId)
	if source == nil then
		return nil
	end

	local model: Model
	if source:IsA("Tool") then
		local newModel = Instance.new("Model")
		for _, child in source:GetChildren() do
			child:Clone().Parent = newModel
		end
		for attrName, attrVal in source:GetAttributes() do
			newModel:SetAttribute(attrName, attrVal)
		end
		local handle = newModel:FindFirstChild("Handle")
		if handle and handle:IsA("BasePart") then
			newModel.PrimaryPart = handle
		end
		model = newModel
	else
		model = source:Clone() :: Model
	end

	model.Name = "HeldItem"
	model:SetAttribute("ItemId", itemId)
	local handle = model.PrimaryPart or (model:FindFirstChild("Handle") :: BasePart?)
	if handle and handle:IsA("BasePart") then
		if model.PrimaryPart == nil then
			model.PrimaryPart = handle
		end
		if handle:FindFirstChild("Grip") == nil then
			local grip = Instance.new("Attachment")
			grip.Name = "Grip"
			grip.CFrame = CFrame.new(0, 0, 0)
			grip.Parent = handle
		end
	end

	local scale = ToolModel.scaleOf(itemId)
	if scale ~= 1 then
		-- Escala peças e attachments (o Grip acompanha).
		model:ScaleTo(model:GetScale() * scale)
	end
	-- Pegada: o Grip anda no próprio eixo Y (ao longo da arma, para a ponta),
	-- na escala do Tamanho.
	local offset = ToolModel.gripOffsetOf(itemId)
	local grip = handle and handle:FindFirstChild("Grip")
	if offset ~= 0 and grip and grip:IsA("Attachment") then
		grip.CFrame *= CFrame.new(0, offset * scale, 0)
	end
	return model
end

return ToolModel
