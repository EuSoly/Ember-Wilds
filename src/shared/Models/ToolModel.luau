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

local function template(itemId: string): Model?
	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Tools")
	local found = folder and folder:FindFirstChild(itemId)
	if found == nil or not found:IsA("Model") then
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
	if def ~= nil and def.category ~= "tool" and def.category ~= "weapon" then
		return nil
	end
	-- Sem definição: só no Studio, para conferir modelos que ainda não são itens
	-- (galeria DevWeapons).
	if def == nil and not RunService:IsStudio() then
		return nil
	end
	local source = template(itemId)
	if source == nil then
		return nil
	end

	local model = source:Clone()
	model.Name = "HeldItem"
	model:SetAttribute("ItemId", itemId)
	local handle = model.PrimaryPart
	if itemId == "book" and handle ~= nil and cosmeticId ~= nil and SkinAssets.hasSkin(cosmeticId) then
		local partNames = SkinManifest.PARTS_BY_SKIN[cosmeticId]
		if partNames ~= nil then
			local added = 0
			for _, partName in partNames do
				local clone = SkinAssets.clonePart(cosmeticId, partName, handle.CFrame)
				if clone then
					clone.Parent = model
					local weld = Instance.new("WeldConstraint")
					weld.Part0 = handle
					weld.Part1 = clone
					weld.Parent = clone
					added += 1
				end
			end
			if added > 0 then
				handle.Transparency = 1
			end
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
