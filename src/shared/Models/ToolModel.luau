--!strict
-- Modelo provisório de uma ferramenta na mão (low-poly, só peças):
-- cabo marrom (cilindro) + cabeça na cor do tier, atravessada na ponta.
-- Por enquanto só itens com category == "tool"; outros devolvem nil.
-- Quando os modelos de verdade chegarem, só este arquivo muda.
--
-- O modelo tem PrimaryPart = Handle e um Attachment "Grip" no cabo: quem segura
-- alinha o Grip com o RightGripAttachment da mão (veja EquipService).
-- Eixos do Grip: Y = ao longo do cabo (para a frente da mão), X = lado da
-- cabeça (fica deitada, visível da câmera de cima).
-- (Só roda no Roblox: cria instâncias.)
local Defs = require("../Defs")
local Palette = require("../Palette")
local Theme = require("../Theme")

local ToolModel = {}

-- Medidas em studs, para um avatar de ~5 studs.
local HANDLE_LENGTH = 2.4
local HANDLE_THICKNESS = 0.25
local HEAD_LENGTH = 1.5
local HEAD_THICKNESS = 0.32
-- Onde a mão segura: perto do fim do cabo (oposto à cabeça).
local GRIP_OFFSET = -HANDLE_LENGTH * 0.3

local HANDLE_COLOR = Palette.biome.forest[3]

local function newPart(name: string, size: Vector3, color: Color3): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Anchored = false
	-- Enfeite: não colide, não é atingido por raycast nem dispara Touched.
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.Massless = true
	part.CastShadow = false
	return part
end

-- Monta o modelo do item, ou nil se o item não tem modelo na mão.
function ToolModel.build(itemId: string): Model?
	local def = Defs.Items[itemId]
	if def == nil or def.category ~= "tool" then
		return nil
	end
	local tier = def.tier and Defs.Tiers[def.tier]
	local headColor = Theme.color(if tier then tier.color else Palette.neutralFrame)

	local model = Instance.new("Model")
	model.Name = "HeldItem"
	model:SetAttribute("ItemId", itemId)

	-- O cilindro do Roblox tem o eixo em X: o cabo fica ao longo do X do Handle.
	local handle =
		newPart("Handle", Vector3.new(HANDLE_LENGTH, HANDLE_THICKNESS, HANDLE_THICKNESS), Theme.color(HANDLE_COLOR))
	handle.Shape = Enum.PartType.Cylinder
	handle.CFrame = CFrame.identity
	handle.Parent = model

	-- Grip: Y do attachment = +X do cabo; X do attachment = +Y do cabo (lado da cabeça).
	local grip = Instance.new("Attachment")
	grip.Name = "Grip"
	grip.CFrame = CFrame.fromMatrix(Vector3.new(GRIP_OFFSET, 0, 0), Vector3.yAxis, Vector3.xAxis)
	grip.Parent = handle

	-- Cabeça atravessada na ponta do cabo.
	local head = newPart("Head", Vector3.new(HEAD_THICKNESS, HEAD_LENGTH, HEAD_THICKNESS), headColor)
	head.CFrame = CFrame.new(HANDLE_LENGTH / 2 - HEAD_THICKNESS / 2, 0, 0)
	head.Parent = model

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = head
	weld.Parent = handle

	model.PrimaryPart = handle
	return model
end

return ToolModel
