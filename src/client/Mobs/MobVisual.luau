--!strict
-- Captura as juntas uma vez. A cada quadro compõe pais antes dos filhos e
-- acrescenta todas as peças ao mesmo lote do renderer, sem PivotTo por junta.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local A = require(Shared:WaitForChild("Mobs"):WaitForChild("MobAnim"))
local C = require(Shared:WaitForChild("Mobs"):WaitForChild("MobAnimConfig"))
local Names = require(Shared:WaitForChild("StatNames"))

-- eye: achata ao piscar; sparkle: brilho do olho, some ao piscar;
-- outline: borda, muda de cor quando o mob quer atacar.
type Kind = "eye" | "sparkle" | "outline" | "plain"
type Part = {
	part: MeshPart,
	kind: Kind,
	rest: CFrame,
	size: Vector3,
	sizeScale: number, -- escala aplicada no Size da peça
	sizeBlink: number, -- piscar aplicado no Size (só olhos)
	color: Color3,
	transparency: number,
	shownTransparency: number,
}
type Group = {
	model: Model,
	parent: number,
	rest: CFrame,
	parts: { Part },
	frame: CFrame,
	scale: number,
}
export type Visual = {
	model: Model,
	groups: { Group },
	scale: number,
	lastFlash: number,
	lastOutline: number,
}
local V = {}
local FLASH = Color3.new(C.FLASH_COLOR[1], C.FLASH_COLOR[2], C.FLASH_COLOR[3])
local HOSTILE = Color3.new(C.OUTLINE_HOSTILE[1], C.OUTLINE_HOSTILE[2], C.OUTLINE_HOSTILE[3])

local function scaled(frame: CFrame, scale: number): CFrame
	return CFrame.new(frame.Position * scale) * frame.Rotation
end

local function kindOf(part: MeshPart): Kind
	if part:GetAttribute(Names.MobOutline) == true then
		return "outline"
	end
	local name = string.lower(part.Name)
	if string.find(name, C.SPARKLE_PATTERN, 1, true) then
		return "sparkle"
	elseif string.find(name, C.EYE_PATTERN, 1, true) then
		return "eye"
	end
	return "plain"
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
					kind = kindOf(child),
					rest = pivot:ToObjectSpace(child.CFrame),
					size = child.Size,
					sizeScale = 1,
					sizeBlink = 0,
					color = child.Color,
					transparency = child.Transparency,
					shownTransparency = child.Transparency,
				})
			elseif child:IsA("Model") then
				collect(child, index, pivot)
			end
		end
	end
	collect(model:FindFirstChild("Body") :: Model, 0, model:GetPivot())
	model.Parent = folder
	return { model = model, groups = groups, scale = config.scale, lastFlash = -1, lastOutline = -1 }
end

function V.append(visual: Visual, root: CFrame, pose: A.Pose, parts: { BasePart }, frames: { CFrame })
	local hidden = pose.groups.Body.scale <= 0
	local recolor = pose.flash ~= visual.lastFlash or pose.outline ~= visual.lastOutline
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
			local blink = if piece.kind == "eye" then pose.blink else 0
			if
				math.abs(g.scale - piece.sizeScale) >= C.SIZE_STEP
				or (g.scale == 1 and piece.sizeScale ~= 1)
				or blink ~= piece.sizeBlink
			then
				piece.sizeScale, piece.sizeBlink = g.scale, blink
				local size = piece.size * math.max(g.scale, 0.001)
				part.Size = Vector3.new(size.X, size.Y, size.Z * (1 - C.BLINK_SQUASH * blink))
			end
			local transparency = if hidden or (piece.kind == "sparkle" and pose.blink > 0.5)
				then 1
				else piece.transparency
			if transparency ~= piece.shownTransparency then
				piece.shownTransparency = transparency
				part.Transparency = transparency
			end
			if recolor then
				local base = if piece.kind == "outline" then piece.color:Lerp(HOSTILE, pose.outline) else piece.color
				part.Color = base:Lerp(FLASH, pose.flash)
			end
			table.insert(parts, part)
			table.insert(frames, g.frame * scaled(piece.rest, g.scale))
		end
	end
	visual.lastFlash, visual.lastOutline = pose.flash, pose.outline
end

function V.destroy(visual: Visual)
	visual.model:Destroy()
end

return V
