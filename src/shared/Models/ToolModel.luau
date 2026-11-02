--!strict
-- Modelos importados das ferramentas e armas em ReplicatedStorage.Assets.Tools.
-- Cada modelo tem PrimaryPart = Handle e Attachment "Grip" (Y = cabo/lâmina
-- para a frente, X = lado). Espadas e lanças têm modelos provisórios simples
-- até os modelos do Elizeu (scripts/studio/make-weapon-placeholders.luau).
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Defs = require("../Defs")

local ToolModel = {}

function ToolModel.build(itemId: string, _cosmeticId: string?): Model?
	local def = Defs.Items[itemId]
	if def == nil or (def.category ~= "tool" and def.category ~= "weapon") then
		return nil
	end

	local assets = ReplicatedStorage:FindFirstChild("Assets")
	local folder = assets and assets:FindFirstChild("Tools")
	local template = folder and folder:FindFirstChild(itemId)
	if template == nil or not template:IsA("Model") then
		return nil
	end

	local model = template:Clone()
	model.Name = "HeldItem"
	model:SetAttribute("ItemId", itemId)
	return model
end

return ToolModel
