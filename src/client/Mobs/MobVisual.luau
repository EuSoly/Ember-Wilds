--!strict
-- Captura as juntas uma vez. A cada quadro compõe pais antes dos filhos e
-- acrescenta todas as peças ao mesmo lote do renderer, sem PivotTo por junta.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local A = require(Shared:WaitForChild("Mobs"):WaitForChild("MobAnim"))
local C = require(Shared:WaitForChild("Mobs"):WaitForChild("MobAnimConfig"))
local Names = require(Shared:WaitForChild("StatNames"))

-- eye: achata ao piscar e semicerra brava; sparkle: brilho do olho, some ao
-- piscar; outline: borda, muda de cor quando o mob quer atacar; brow:
-- sobrancelha criada aqui, só aparece com a cara de brava.
type Kind = "eye" | "sparkle" | "outline" | "brow" | "plain"
type Part = {
	part: BasePart,
	kind: Kind,
	rest: CFrame,
	size: Vector3,
	sizeScale: number, -- escala aplicada no Size da peça
	sizeSquash: number, -- quanto o olho está achatado no Size (só olhos)
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
local BROW = Color3.new(C.BROW_COLOR[1], C.BROW_COLOR[2], C.BROW_COLOR[3])

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

-- Sobrancelha "\ /" na frente do olho, um pouco acima dele. `center` é o
-- pivô do mob: a ponta de dentro (lado do centro) desce para trás.
local function newBrow(eye: BasePart, group: Model, center: CFrame): BasePart
	local x = center:PointToObjectSpace(eye.Position).X
	local inward = if x < 0 then 1 elseif x > 0 then -1 else 0
	local brow = Instance.new("Part")
	brow.Name = "AngryBrow"
	brow.Material = Enum.Material.SmoothPlastic
	brow.Color = BROW
	brow.CastShadow = false
	brow.Transparency = 1
	brow.Size = Vector3.new(eye.Size.X * C.BROW_LENGTH, 0.05, eye.Size.Z * C.BROW_THICKNESS)
	brow.CFrame = CFrame.new(eye.Position)
		* center.Rotation
		* CFrame.new(0, eye.Size.Y / 2 + C.BROW_LIFT, -eye.Size.Z * C.BROW_OFFSET)
		* CFrame.Angles(0, -inward * C.BROW_ANGLE, 0)
	brow.Parent = group
	return brow
end

function V.create(template: Model, config: C.Mob, folder: Folder): Visual
	local model = template:Clone()
	-- Importados já têm escala canônica diferente de 1. A config é um fator
	-- sobre o tamanho aprovado no place, não a escala canônica absoluta.
	model:ScaleTo(model:GetScale() * config.scale)
	local groups: { Group } = {}
	local center = model:GetPivot()
	-- `visible`: transparência quando a peça aparece (a sobrancelha nasce escondida).
	local function addPiece(entry: Group, part: BasePart, kind: Kind, pivot: CFrame, visible: number)
		part.Anchored = true
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		part.Massless = true
		table.insert(entry.parts, {
			part = part,
			kind = kind,
			rest = pivot:ToObjectSpace(part.CFrame),
			size = part.Size,
			sizeScale = 1,
			sizeSquash = 0,
			color = part.Color,
			transparency = visible,
			shownTransparency = part.Transparency,
		})
	end
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
				local kind: Kind = kindOf(child)
				addPiece(entry, child, kind, pivot, child.Transparency)
				if kind == "eye" then
					addPiece(entry, newBrow(child, group, center), "brow", pivot, 0)
				end
			elseif child:IsA("Model") then
				collect(child, index, pivot)
			end
		end
	end
	collect(model:FindFirstChild("Body") :: Model, 0, center)
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
			-- Olho: piscar achata quase tudo; brava semicerra (vale o maior).
			local squash = if piece.kind == "eye"
				then math.max(C.BLINK_SQUASH * pose.blink, C.ANGRY_SQUINT * pose.angry)
				else 0
			if
				math.abs(g.scale - piece.sizeScale) >= C.SIZE_STEP
				or (g.scale == 1 and piece.sizeScale ~= 1)
				or squash ~= piece.sizeSquash
			then
				piece.sizeScale, piece.sizeSquash = g.scale, squash
				local size = piece.size * math.max(g.scale, 0.001)
				part.Size = Vector3.new(size.X, size.Y, size.Z * (1 - squash))
			end
			local gone = hidden
				or (piece.kind == "sparkle" and pose.blink > 0.5)
				or (piece.kind == "brow" and pose.angry < 0.5)
			local transparency = if gone then 1 else piece.transparency
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
