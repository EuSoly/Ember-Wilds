--!strict
-- Captura as juntas uma vez. A cada quadro compõe pais antes dos filhos e
-- acrescenta todas as peças ao mesmo lote do renderer, sem PivotTo por junta.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local A = require(Shared:WaitForChild("Mobs"):WaitForChild("MobAnim"))
local C = require(Shared:WaitForChild("Mobs"):WaitForChild("MobAnimConfig"))

type Part = {
	part: MeshPart,
	rest: CFrame,
	size: Vector3,
	sizeScale: number, -- escala aplicada no Size da peça
	color: Color3,
	transparency: number,
}
type Group = {
	model: Model,
	parent: number,
	rest: CFrame,
	parts: { Part },
	frame: CFrame,
	scale: number,
}
export type Visual = { model: Model, groups: { Group }, scale: number, lastFlash: number, hidden: boolean }
local V = {}
local FLASH = Color3.new(C.FLASH_COLOR[1], C.FLASH_COLOR[2], C.FLASH_COLOR[3])

local function scaled(frame: CFrame, scale: number): CFrame
	return CFrame.new(frame.Position * scale) * frame.Rotation
end

function V.create(template: Model, config: C.Mob, folder: Folder): Visual
	local model = template:Clone()
	-- Importados já têm escala canônica diferente de 1. A config é um fator
	-- sobre o tamanho aprovado no place, não a escala canônica absoluta.
	model:ScaleTo(model:GetScale() * config.scale)
	local groups: { Group } = {}
	local function collect(group: Model, parent: number, parentPivot: CFrame)
		local pivot = group:GetPivot()
		local entry: Group = {
			model = group,
			parent = parent,
			rest = parentPivot:ToObjectSpace(pivot),
			parts = {},
			frame = CFrame.identity,
			scale = 1,
		}
		table.insert(groups, entry)
		local index = #groups
		for _, child in group:GetChildren() do
			if child:IsA("MeshPart") then
				child.Anchored = true
				child.CanCollide, child.CanTouch, child.CanQuery = false, false, false
				child.Massless = true
				table.insert(entry.parts, {
					part = child,
					rest = pivot:ToObjectSpace(child.CFrame),
					size = child.Size,
					sizeScale = 1,
					color = child.Color,
					transparency = child.Transparency,
				})
			elseif child:IsA("Model") then
				collect(child, index, pivot)
			end
		end
	end
	collect(model:FindFirstChild("Body") :: Model, 0, model:GetPivot())
	model.Parent = folder
	return { model = model, groups = groups, scale = config.scale, lastFlash = -1, hidden = false }
end

function V.append(visual: Visual, root: CFrame, pose: A.Pose, parts: { BasePart }, frames: { CFrame })
	local hidden = pose.groups.Body.scale <= 0
	for _, g in visual.groups do
		local parent = visual.groups[g.parent]
		local parentFrame = if parent then parent.frame else root
		local parentScale = if parent then parent.scale else 1
		local p = pose.groups[g.model.Name]
		g.frame = parentFrame
			* scaled(g.rest, parentScale)
			* CFrame.new(Vector3.new(p.x, p.y, p.z) * visual.scale * parentScale)
			* CFrame.Angles(0, p.yaw, 0)
		g.scale = parentScale * p.scale
		-- Metadado da junta: não move peças. Útil também para inspecionar no Studio.
		g.model.WorldPivot = g.frame
		for _, piece in g.parts do
			local part = piece.part
			-- Trocar Size é caro: a respiração só reescreve quando a escala
			-- anda SIZE_STEP. Roblox limita o Size mínimo; em zero, esconde.
			if math.abs(g.scale - piece.sizeScale) >= C.SIZE_STEP or (g.scale == 1 and piece.sizeScale ~= 1) then
				piece.sizeScale = g.scale
				part.Size = piece.size * math.max(g.scale, 0.001)
			end
			if hidden ~= visual.hidden then
				part.Transparency = if hidden then 1 else piece.transparency
			end
			if pose.flash ~= visual.lastFlash then
				part.Color = piece.color:Lerp(FLASH, pose.flash)
			end
			table.insert(parts, part)
			table.insert(frames, g.frame * scaled(piece.rest, g.scale))
		end
	end
	visual.hidden, visual.lastFlash = hidden, pose.flash
end

function V.destroy(visual: Visual)
	visual.model:Destroy()
end

return V
