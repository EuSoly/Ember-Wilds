--!strict
-- Animações das estruturas, só no cliente (G8): tampa do baú abre quando o
-- jogador está ao lado, rotor do extrator gira enquanto trabalha e chamas
-- somem quando a peça está apagada. Nada disso replica: as peças são ancoradas
-- e do servidor, e aqui só escrevemos o CFrame/transparência local de cada
-- quadro. Um loop só cuida de todas as peças com StructureTag.
-- As peças do modelo "Visual" (clone do molde, Task 3) são achadas pelo sufixo
-- do nome: *_lid, *_rotor, *_flames. O pivô delas já está na dobradiça/eixo.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local StatNames = require(Shared:WaitForChild("StatNames"))

local Client = script.Parent.Parent
local ChestState = require(Client:WaitForChild("ChestState"))

-- Graus. No Blender é -105; depois da conversão do FBX o sinal pode estar
-- invertido: conferir no Studio e trocar o sinal aqui se a tampa abrir para dentro.
local LID_OPEN_DEGREES = 105
local LID_SPEED = math.rad(420) -- rad/s ao abrir e fechar
local ROTOR_SPEED = math.rad(180) -- rad/s

type Mover = { part: BasePart, pivotRel: CFrame, angle: number, written: boolean }
type Piece = {
	visual: Instance?,
	dirty: boolean,
	lids: { Mover },
	rotors: { Mover },
	flames: { BasePart },
}

local pieces: { [Model]: Piece } = {}

local StructureFx = {}

local function scan(model: Model, piece: Piece, visual: Instance)
	-- Partes já conhecidas ficam como estão (o CFrame original foi guardado).
	local known: { [Instance]: boolean } = {}
	for _, mover in piece.lids do
		known[mover.part] = true
	end
	for _, mover in piece.rotors do
		known[mover.part] = true
	end
	for _, flame in piece.flames do
		known[flame] = true
	end
	local pivot = model:GetPivot()
	for _, descendant in visual:GetDescendants() do
		if descendant:IsA("BasePart") and not known[descendant] then
			local name = descendant.Name
			-- Guarda o pivô da parte relativo ao pivô da peça (robusto a rotação).
			local rel = pivot:ToObjectSpace(descendant:GetPivot())
			if name:sub(-4) == "_lid" then
				table.insert(piece.lids, { part = descendant, pivotRel = rel, angle = 0, written = false })
			elseif name:sub(-6) == "_rotor" then
				table.insert(piece.rotors, { part = descendant, pivotRel = rel, angle = 0, written = false })
			elseif name:sub(-7) == "_flames" then
				table.insert(piece.flames, descendant)
			end
		end
	end
end

local function track(instance: Instance)
	if not instance:IsA("Model") or pieces[instance] then
		return
	end
	pieces[instance] = { visual = nil, dirty = true, lids = {}, rotors = {}, flames = {} }
end

local function untrack(instance: Instance)
	pieces[instance :: Model] = nil
end

local function moveTo(model: Model, mover: Mover, angle: number, axis: "X" | "Y")
	local rotation = if axis == "X" then CFrame.Angles(angle, 0, 0) else CFrame.Angles(0, angle, 0)
	mover.part:PivotTo(model:GetPivot() * mover.pivotRel * rotation)
	mover.written = true
end

local function step(dt: number)
	local near = ChestState.near()
	local target = math.rad(LID_OPEN_DEGREES)
	for model, piece in pieces do
		-- Peça removida ou fora do mundo (streaming): esquece; volta se reaparecer.
		if model.Parent == nil or not model:IsDescendantOf(game) then
			pieces[model] = nil
			continue
		end

		-- O Visual pode chegar depois do modelo.
		local visual = piece.visual
		if visual == nil or visual.Parent == nil then
			visual = model:FindFirstChild("Visual")
			piece.visual = visual
			piece.dirty = true
			if visual then
				visual.DescendantAdded:Connect(function()
					piece.dirty = true
				end)
			end
		end
		if visual == nil then
			continue
		end
		if piece.dirty then
			piece.dirty = false
			scan(model, piece, visual)
		end

		-- Tampa: abre enquanto este baú é o que está perto, fecha ao sair.
		local lidTarget = if near == model then target else 0
		for _, lid in piece.lids do
			if lid.part.Parent == nil then
				continue
			end
			if lid.angle ~= lidTarget then
				local delta = lidTarget - lid.angle
				local move = math.min(math.abs(delta), LID_SPEED * dt)
				lid.angle += if delta > 0 then move else -move
				moveTo(model, lid, lid.angle, "X")
			end
		end

		-- Rotor: gira no eixo da peça só com Working == true.
		if model:GetAttribute(StatNames.Working) == true then
			for _, rotor in piece.rotors do
				if rotor.part.Parent then
					rotor.angle = (rotor.angle + ROTOR_SPEED * dt) % (2 * math.pi)
					moveTo(model, rotor, rotor.angle, "Y")
				end
			end
		end

		-- Chamas: visíveis salvo Lit == false (só local; Transparency fica do servidor).
		local modifier = if model:GetAttribute(StatNames.Lit) == false then 1 else 0
		for _, flame in piece.flames do
			if flame.LocalTransparencyModifier ~= modifier then
				flame.LocalTransparencyModifier = modifier
			end
		end
	end
end

function StructureFx.start()
	CollectionService:GetInstanceAddedSignal(StatNames.StructureTag):Connect(track)
	CollectionService:GetInstanceRemovedSignal(StatNames.StructureTag):Connect(untrack)
	for _, instance in CollectionService:GetTagged(StatNames.StructureTag) do
		track(instance)
	end
	RunService.RenderStepped:Connect(step)
end

return StructureFx
