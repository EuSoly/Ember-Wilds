--!strict
-- Bancada provisória de peças para testar receitas; pivô no chão.
local Palette = require("../Palette")
local StatNames = require("../StatNames")
local Theme = require("../Theme")

local WorkbenchModel = {}

local function part(name: string, size: Vector3, cf: CFrame, color: Color3): Part
	local piece = Instance.new("Part")
	piece.Name = name
	piece.Size = size
	piece.CFrame = cf
	piece.Color = color
	piece.Material = Enum.Material.WoodPlanks
	piece.Anchored = true
	piece.TopSurface = Enum.SurfaceType.Smooth
	piece.BottomSurface = Enum.SurfaceType.Smooth
	piece.Parent = nil
	return piece
end

function WorkbenchModel.build(): Model
	local model = Instance.new("Model")
	model.Name = "Workbench"
	model.ModelStreamingMode = Enum.ModelStreamingMode.Atomic
	local wood = Theme.color(Palette.biome.forest[3])
	local top = part("Top", Vector3.new(3.2, 0.45, 2.2), CFrame.new(0, 1.35, 0), wood)
	top.Parent = model
	for x = -1, 1, 2 do
		for z = -1, 1, 2 do
			local leg = part(`Leg_{x}_{z}`, Vector3.new(0.35, 1.2, 0.35), CFrame.new(x * 1.15, 0.6, z * 0.75), wood)
			leg.Parent = model
		end
	end
	model.PrimaryPart = top
	top.PivotOffset = CFrame.new(0, -1.35, 0)
	model:AddTag(StatNames.CraftStationTag)
	model:SetAttribute(StatNames.Station, "workbench")
	return model
end

return WorkbenchModel
