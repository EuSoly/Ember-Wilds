--!strict
-- Captura as juntas uma vez. A cada quadro compõe pais antes dos filhos e
-- acrescenta todas as peças ao mesmo lote do renderer, sem PivotTo por junta.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local A = require(Shared:WaitForChild("Mobs"):WaitForChild("MobAnim"))
local C = require(Shared:WaitForChild("Mobs"):WaitForChild("MobAnimConfig"))
local Names = require(Shared:WaitForChild("StatNames"))
local AngryEyes = require(script.Parent:WaitForChild("AngryEyes"))

-- eye: achata ao piscar, some na cara de brava (se tiver o corte); angryEye:
-- o olho cortado (AngryEyes), só aparece na cara de brava; sparkle: brilho do olho, some
-- ao piscar e vai para o lado do focinho na cara de brava; outline: borda,
-- muda de cor quando o mob quer atacar.
type Kind = "eye" | "angryEye" | "sparkle" | "outline" | "plain"
type Part = {
	part: BasePart,
	kind: Kind,
	rest: CFrame,
	angryRest: CFrame?, -- brilho: onde fica na cara de brava
	hasAngry: boolean, -- olho: existe a versão cortada (some na cara de brava)
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

local function scaled(frame: CFrame, scale: number): CFrame
	return CFrame.new(frame.Position * scale) * frame.Rotation
end

local function kindOf(part: MeshPart): Kind
	if part:GetAttribute(Names.MobOutline) == true then
		return "outline"
	elseif part:GetAttribute(Names.MobAngryEye) == true then
		return "angryEye"
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
	-- Olhos bravos (se o corte deste mob já está pronto): ao lado de cada
	-- olho, antes do ScaleTo para escalarem juntos.
	local cuts = AngryEyes.get(template)
	local cutEyes: { [BasePart]: boolean } = {}
	if cuts then
		for _, part in model:GetDescendants() do
			local angry = if AngryEyes.isEye(part) then cuts[AngryEyes.pathOf(part, model)] else nil
			if angry then
				local copy = angry:Clone()
				copy.Transparency = 1
				copy:SetAttribute(Names.MobAngryEye, true)
				copy.Parent = part.Parent
				cutEyes[part :: BasePart] = true
			end
		end
	end
	-- Importados já têm escala canônica diferente de 1. A config é um fator
	-- sobre o tamanho aprovado no place, não a escala canônica absoluta.
	model:ScaleTo(model:GetScale() * config.scale)
	local groups: { Group } = {}
	local center = model:GetPivot()
	-- `visible`: transparência quando a peça aparece (o olho bravo nasce escondido).
	local function addPiece(entry: Group, part: BasePart, kind: Kind, visible: number): Part
		part.Anchored = true
		part.CanCollide, part.CanTouch, part.CanQuery = false, false, false
		part.Massless = true
		local piece: Part = {
			part = part,
			kind = kind,
			rest = entry.model:GetPivot():ToObjectSpace(part.CFrame),
			angryRest = nil,
			hasAngry = cutEyes[part] == true,
			size = part.Size,
			sizeScale = 1,
			sizeSquash = 0,
			color = part.Color,
			transparency = visible,
			shownTransparency = part.Transparency,
		}
		table.insert(entry.parts, piece)
		return piece
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
				addPiece(entry, child, kind, if kind == "angryEye" then 0 else child.Transparency)
			elseif child:IsA("Model") then
				collect(child, index, pivot)
			end
		end
	end
	collect(model:FindFirstChild("Body") :: Model, 0, center)

	-- Cara de brava: o brilho vai para o lado do focinho do olho mais perto,
	-- a parte que sobra no olho cortado.
	for _, entry in groups do
		local eyes: { BasePart } = {}
		for _, piece in entry.parts do
			if piece.kind == "eye" then
				table.insert(eyes, piece.part)
			end
		end
		for _, sparkle in entry.parts do
			if sparkle.kind ~= "sparkle" then
				continue
			end
			local nearest: BasePart? = nil
			for _, eye in eyes do
				local distance = (eye.Position - sparkle.part.Position).Magnitude
				if nearest == nil or distance < (nearest.Position - sparkle.part.Position).Magnitude then
					nearest = eye
				end
			end
			if nearest then
				local front = center.Rotation * Vector3.new(0, 0, -nearest.Size.Z * C.PUPIL_SHIFT)
				local target = Vector3.new(nearest.Position.X, sparkle.part.Position.Y, nearest.Position.Z) + front
				sparkle.angryRest = entry.model:GetPivot():ToObjectSpace(sparkle.part.CFrame.Rotation + target)
			end
		end
	end
	model.Parent = folder
	return { model = model, groups = groups, scale = config.scale, lastFlash = -1, lastOutline = -1 }
end

function V.append(visual: Visual, root: CFrame, pose: A.Pose, parts: { BasePart }, frames: { CFrame })
	local hidden = pose.groups.Body.scale <= 0
	local recolor = pose.flash ~= visual.lastFlash or pose.outline ~= visual.lastOutline
	local angry = pose.angry > 0.5
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
			local isEye = piece.kind == "eye" or piece.kind == "angryEye"
			local squash = if isEye then C.BLINK_SQUASH * pose.blink else 0
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
				or (piece.kind == "eye" and angry and piece.hasAngry)
				or (piece.kind == "angryEye" and not angry)
			local transparency = if gone then 1 else piece.transparency
			if transparency ~= piece.shownTransparency then
				piece.shownTransparency = transparency
				part.Transparency = transparency
			end
			if recolor then
				local base = if piece.kind == "outline" then piece.color:Lerp(HOSTILE, pose.outline) else piece.color
				part.Color = base:Lerp(FLASH, pose.flash)
			end
			local rest = if angry and piece.angryRest then piece.angryRest else piece.rest
			table.insert(parts, part)
			table.insert(frames, g.frame * scaled(rest, g.scale))
		end
	end
	visual.lastFlash, visual.lastOutline = pose.flash, pose.outline
end

function V.destroy(visual: Visual)
	visual.model:Destroy()
end

return V
