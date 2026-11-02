--!strict
-- Modelos importados das ferramentas e armas em ReplicatedStorage.Assets.Tools.
-- Cada modelo tem PrimaryPart = Handle e Attachment "Grip" (Y = cabo/lâmina
-- para a frente, X = lado). As espadas e lanças vêm do Blender do Elizeu
-- (scripts/studio/import-weapons.luau). Atributos de cada modelo, ajustáveis
-- no Studio: "Tamanho" (StatNames.ToolScale; 1 = como foi importado) escala o
-- item na mão; "Pegada" (StatNames.ToolGrip; studs, 0 = Grip importado) desliza
-- onde a mão segura ao longo da arma (positivo = mais perto da ponta).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require("../Defs")
local StatNames = require("../StatNames")

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

function ToolModel.build(itemId: string, _cosmeticId: string?): Model?
	local def = Defs.Items[itemId]
	if def == nil or (def.category ~= "tool" and def.category ~= "weapon") then
		return nil
	end
	local source = template(itemId)
	if source == nil then
		return nil
	end

	local model = source:Clone()
	model.Name = "HeldItem"
	model:SetAttribute("ItemId", itemId)
	local scale = ToolModel.scaleOf(itemId)
	if scale ~= 1 then
		-- Escala peças e attachments (o Grip acompanha).
		model:ScaleTo(model:GetScale() * scale)
	end
	-- Pegada: o Grip anda no próprio eixo Y (ao longo da arma, para a ponta),
	-- na escala do Tamanho.
	local offset = ToolModel.gripOffsetOf(itemId)
	local handle = model.PrimaryPart
	local grip = handle and handle:FindFirstChild("Grip")
	if offset ~= 0 and grip and grip:IsA("Attachment") then
		grip.CFrame *= CFrame.new(0, offset * scale, 0)
	end
	return model
end

return ToolModel
