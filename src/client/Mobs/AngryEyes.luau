--!strict
-- Olhos bravos: cada olho cortado em diagonal do lado da testa (para trás,
-- longe do focinho), com a ponta de dentro descendo para o focinho.
-- O corte (GeometryService) é feito no cliente, uma vez por tipo de mob, em
-- segundo plano: a malha de um corte feito no Studio não vai para o jogo.
-- Enquanto não fica pronto, o mob fica bravo sem o corte.
local GeometryService = game:GetService("GeometryService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local C = require(Shared:WaitForChild("Mobs"):WaitForChild("MobAnimConfig"))

-- Caminho do olho dentro do modelo ("Body/Head/eye"), igual no template e no clone.
export type Cuts = { [string]: BasePart }

local AngryEyes = {}
local cuts: { [string]: Cuts } = {}
local working: { [string]: boolean } = {}
local listeners: { (id: string) -> () } = {}

function AngryEyes.isEye(part: Instance): boolean
	if not part:IsA("MeshPart") then
		return false
	end
	local name = string.lower(part.Name)
	return string.find(name, C.EYE_PATTERN, 1, true) ~= nil and string.find(name, C.SPARKLE_PATTERN, 1, true) == nil
end

function AngryEyes.pathOf(part: Instance, model: Model): string
	local names = {}
	local current: Instance? = part
	while current and current ~= model do
		table.insert(names, 1, current.Name)
		current = current.Parent
	end
	return table.concat(names, "/")
end

local function cut(eye: BasePart, center: CFrame): BasePart?
	local x = center:PointToObjectSpace(eye.Position).X
	local inward = if x < 0 then 1 elseif x > 0 then -1 else 0
	-- Bloco que leva tudo atrás da linha do corte (frente do mob = -Z).
	local cutter = Instance.new("Part")
	cutter.Size = Vector3.new(eye.Size.X * 2, eye.Size.Y * 4, eye.Size.Z)
	cutter.CFrame = CFrame.new(eye.Position)
		* center.Rotation
		* CFrame.new(0, 0, eye.Size.Z * C.ANGRY_CUT)
		* CFrame.Angles(0, inward * C.ANGRY_CUT_ANGLE, 0)
		* CFrame.new(0, 0, eye.Size.Z / 2)
	local ok, result = pcall(function()
		return GeometryService:SubtractAsync(eye, { cutter }, {
			CollisionFidelity = Enum.CollisionFidelity.Box,
			RenderFidelity = Enum.RenderFidelity.Precise,
			SplitApart = false,
		})
	end)
	cutter:Destroy()
	if not ok or #result ~= 1 then
		warn(`[AngryEyes] não deu para cortar {eye:GetFullName()}: {if ok then #result else result}`)
		return nil
	end
	local angry = result[1]
	angry.Name = eye.Name .. "_angry"
	angry.Color = eye.Color
	angry.Material = eye.Material
	angry.CastShadow = eye.CastShadow
	return angry
end

-- Os cortes do template, ou nil enquanto não estão prontos (começa a fazer
-- na primeira chamada; avisa os ouvintes de onReady quando terminar).
function AngryEyes.get(template: Model): Cuts?
	local id = template.Name
	local ready = cuts[id]
	if ready or working[id] then
		return ready
	end
	working[id] = true
	task.spawn(function()
		local center = template:GetPivot()
		local result: Cuts = {}
		for _, part in template:GetDescendants() do
			if AngryEyes.isEye(part) then
				local angry = cut(part :: BasePart, center)
				if angry then
					result[AngryEyes.pathOf(part, template)] = angry
				end
			end
		end
		cuts[id] = result
		working[id] = nil
		for _, listener in listeners do
			listener(id)
		end
	end)
	return nil
end

function AngryEyes.onReady(listener: (id: string) -> ())
	table.insert(listeners, listener)
end

return AngryEyes
